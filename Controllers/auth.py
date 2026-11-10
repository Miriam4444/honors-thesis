from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel
from database import SessionLocal
from Models.user import User
from workos import WorkOSClient
import jwt
import redis
import os
import time
import uuid

router = APIRouter()

workos_client = WorkOSClient(
    api_key=os.environ["WORKOS_API_KEY"],
    client_id=os.environ["WORKOS_CLIENT_ID"],
)

# where WorkOS sends the browser after login: straight back into the app (not to this server),
# so it works no matter what IP address the laptop has. this exact URI has to be added in the
# WorkOS dashboard under Redirects.
APP_REDIRECT_URI = os.environ.get("WORKOS_APP_REDIRECT_URI", "honorsthesis://auth/callback")

# our own session tokens (JWTs). JWT_SECRET signs them, so nobody can make a fake one. keep it secret!
JWT_SECRET = os.environ["JWT_SECRET"]
JWT_ALGORITHM = "HS256"
TOKEN_LIFETIME_SECONDS = 7 * 24 * 60 * 60  # logged in for a week, then you sign in again

# Redis remembers logged-out tokens until they would have expired anyway (the "blocklist")
redis_client = redis.Redis.from_url(os.environ.get("REDIS_URL", "redis://127.0.0.1:6379/0"), decode_responses=True)


class TokenRequest(BaseModel):
    code: str  # the one-time code WorkOS gave the app after the user signed in


def get_or_create_user(db, workos_user_id: str, email: str) -> User:
    user = db.query(User).filter(User.workos_user_id == workos_user_id).first()

    if user is None:
        user = User(
            username=email,
            email=email,
            workos_user_id=workos_user_id,
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    return user


# ---------- session tokens ----------

def make_token(user_id: int) -> str:
    now = int(time.time())
    payload = {
        "sub": str(user_id),        # who the token belongs to
        "jti": uuid.uuid4().hex,    # this token's own id, so it can be blocklisted on logout
        "iat": now,                 # issued at
        "exp": now + TOKEN_LIFETIME_SECONDS,  # expires at
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def _blocklist_key(jti: str) -> str:
    return f"blocklist:{jti}"


def _read_token(authorization: str | None) -> dict:
    # pulls the token out of the "Authorization: Bearer <token>" header and checks it
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Not logged in")
    token = authorization.removeprefix("Bearer ").strip()
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Your login expired, please sign in again")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid login token")

    try:
        if redis_client.exists(_blocklist_key(payload["jti"])):
            raise HTTPException(status_code=401, detail="You logged out, please sign in again")
    except redis.RedisError:
        # if we can't check the blocklist we can't be sure the token is still good, so refuse
        raise HTTPException(status_code=503, detail="Login check failed: is Redis running?")
    return payload


def get_current_user(authorization: str | None = Header(default=None)) -> User:
    # use this in any endpoint that needs a logged-in user:
    #     def my_endpoint(user: User = Depends(get_current_user)):
    payload = _read_token(authorization)
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.idUser == int(payload["sub"])).first()
        if user is None:
            raise HTTPException(status_code=401, detail="That account doesn't exist anymore")
        db.expunge(user)  # so it can still be used after the db session closes
        return user
    finally:
        db.close()


# ---------- endpoints ----------

@router.get("/auth/login-url")
def get_login_url(state: str | None = None, signup: bool = False):
    # the WorkOS page the app opens. it handles both signing in and creating an account;
    # signup=true just makes it start on the "create account" screen.
    # state = a random value from the app, sent back untouched, so the app knows the reply is really for it
    url = workos_client.user_management.get_authorization_url(
        provider="authkit",
        redirect_uri=APP_REDIRECT_URI,
        state=state,
        screen_hint="sign-up" if signup else None,
    )
    return {"url": url}


@router.post("/auth/token")
def exchange_code(body: TokenRequest):
    # the app sends the code it got back from WorkOS; we trade it for the user's info
    # (that needs our secret API key, which is why it happens here and not in the app)
    db = SessionLocal()
    try:
        try:
            auth_response = workos_client.user_management.authenticate_with_code(code=body.code)
        except Exception:
            raise HTTPException(status_code=401, detail="Invalid or expired login code")

        workos_user = auth_response.user
        user = get_or_create_user(db=db, workos_user_id=workos_user.id, email=workos_user.email)
        return {"token": make_token(user.idUser), "user_id": user.idUser, "email": user.email}
    finally:
        db.close()


@router.get("/auth/me")
def me(authorization: str | None = Header(default=None)):
    # the app calls this when it starts, to check its saved token is still good
    user = get_current_user(authorization)
    return {"user_id": user.idUser, "email": user.email}


@router.post("/auth/logout")
def logout(authorization: str | None = Header(default=None)):
    # puts this token on the blocklist until it would have expired anyway
    payload = _read_token(authorization)
    seconds_left = max(1, payload["exp"] - int(time.time()))
    try:
        redis_client.set(_blocklist_key(payload["jti"]), "1", ex=seconds_left)
    except redis.RedisError:
        raise HTTPException(status_code=503, detail="Couldn't log out: is Redis running?")
    return {"message": "Logged out"}