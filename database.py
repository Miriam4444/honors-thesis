from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

URL_DATABASE = 'mysql+pymysql://root:ServBay.dev@localhost/honorsthesis'

engine = create_engine(URL_DATABASE)

SessionLocal = sessionmaker(bind=engine)

Base = declarative_base()

#testing the database connection
'''
from sqlalchemy import inspect
from database import engine

inspector = inspect(engine)
print(inspector.get_table_names())
'''