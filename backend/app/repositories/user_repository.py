# backend/app/repositories/user_repository.py

from sqlalchemy.orm import Session
from ..models.user import User
from ..core.security import get_password_hash, verify_password
from datetime import datetime

class UserRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_email(self, email: str) -> User | None:
        return self.db.query(User).filter(User.email == email).first()

    def get_by_id(self, user_id: int) -> User | None:
        return self.db.query(User).filter(User.id == user_id).first()

    def create(self, **kwargs) -> User:
        # On s'assure que le mot de passe est hashé
        if 'password' in kwargs:
            password = kwargs.pop('password')
            kwargs['password_hash'] = get_password_hash(password)
        
        user = User(**kwargs)
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def update(self, user: User, **kwargs) -> User:
        for key, value in kwargs.items():
            if hasattr(user, key) and value is not None:
                setattr(user, key, value)
        self.db.commit()
        self.db.refresh(user)
        return user

    def update_last_login(self, user: User) -> User:
        user.last_login = datetime.utcnow()
        self.db.commit()
        self.db.refresh(user)
        return user

    def verify_password(self, user: User, password: str) -> bool:
        return verify_password(password, user.password_hash)