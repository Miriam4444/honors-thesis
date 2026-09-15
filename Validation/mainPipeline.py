'''
okay so before i actually do anything im going to put an explanation for everything thats going to happen here.

this folder is going to basically have all of the chemistry rules so that when a user tries to save a molecule in the frontend, before it gets saved to the database it goes through all of these checks.

i think instead of putting it all in one file, im going to have a folder and then a bunch of different files for different checks.
for example, one file checks that the bond types are valid and another one checks that the atoms can actually bond to each other... idk fs yet but like yeah.

and then in this file its going to have a function that iterates through all of those functions so it's all being called in one easy call.
'''