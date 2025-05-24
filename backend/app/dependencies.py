from fastapi import Depends
from sqlalchemy.orm import Session
from . import database, auth

get_db = database.get_db

get_current_user = auth.get_current_user
