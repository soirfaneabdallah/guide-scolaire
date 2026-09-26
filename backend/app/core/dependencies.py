# backend/app/core/dependencies.py

import logging
from typing import Optional

from fastapi import Depends, HTTPException, status, Request, Query
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from jose import JWTError, jwt

from ..core.config import settings
from ..core.database import get_db
from ..models.user import User

logger = logging.getLogger(__name__)

# ✅ Définir oauth2_scheme
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


# ============================================================
#  DÉPENDANCES D'AUTHENTIFICATION
# ============================================================

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    """
    Récupère l'utilisateur actuel à partir du token JWT.
    Lève une exception si le token est invalide.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Identifiants invalides",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM],
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = db.query(User).filter(User.id == int(user_id)).first()
    if user is None:
        raise credentials_exception

    return user


async def get_current_active_user(
    current_user: User = Depends(get_current_user),
) -> User:
    """
    Récupère l'utilisateur actuel et vérifie qu'il est actif.
    """
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Utilisateur inactif",
        )
    return current_user


async def get_current_active_user_optional(
    token: Optional[str] = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> Optional[User]:
    """
    Récupère l'utilisateur actuel si un token est fourni,
    sinon retourne None (optionnel pour les routes publiques).
    """
    if token is None:
        return None

    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM],
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            return None
    except JWTError:
        return None

    user = db.query(User).filter(User.id == int(user_id)).first()
    if user is None or not user.is_active:
        return None

    return user


# ============================================================
#  AUTHENTIFICATION PAR QUERY PARAM (pour les médias)
# ============================================================

async def get_current_user_from_query_or_header(
    request: Request,
    token: Optional[str] = Query(
        None,
        description="JWT en query param (pour les lecteurs vidéo Web)",
    ),
    db: Session = Depends(get_db),
) -> User:
    """
    Récupère l'utilisateur courant depuis :
    1. Le header Authorization: Bearer <token> (prioritaire)
    2. Le query param ?token=<token> (fallback pour <video> HTML et video_player)

    ⚠️ Nécessaire car les balises <video> HTML et video_player Flutter Web
    ne peuvent PAS envoyer de header Authorization personnalisé.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Identifiants invalides",
        headers={"WWW-Authenticate": "Bearer"},
    )

    # ⚠️ LOGS DE DEBUG — À RETIRER EN PROD
    logger.info("=" * 60)
    logger.info("🔐 [AUTH] URL complète : %s", request.url)
    logger.info("🔐 [AUTH] Query params : %s", dict(request.query_params))
    logger.info("🔐 [AUTH] token (query) : %s",
                (token[:20] + "...") if token else "ABSENT")
    logger.info("🔐 [AUTH] Authorization header : %s",
                request.headers.get("authorization", "ABSENT"))
    logger.info("=" * 60)

    # 1. Chercher le token dans le header
    jwt_token: Optional[str] = None
    auth_header = request.headers.get("authorization")
    if auth_header and auth_header.lower().startswith("bearer "):
        jwt_token = auth_header[7:].strip()
        logger.info("✅ [AUTH] Token trouvé dans le header")
    # 2. Sinon, dans le query param
    elif token:
        jwt_token = token
        logger.info("✅ [AUTH] Token trouvé dans le query param")

    if not jwt_token:
        logger.error("❌ [AUTH] AUCUN token trouvé (ni header, ni query)")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token d'authentification manquant",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # 3. Décoder et valider
    try:
        payload = jwt.decode(
            jwt_token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM],
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            logger.error("❌ [AUTH] 'sub' absent du JWT")
            raise credentials_exception
        logger.info("✅ [AUTH] JWT décodé, user_id=%s", user_id)
    except JWTError as e:
        logger.error("❌ [AUTH] JWTError: %s", e)
        raise credentials_exception

    user = db.query(User).filter(User.id == int(user_id)).first()
    if user is None:
        logger.error("❌ [AUTH] Utilisateur %s introuvable en BDD", user_id)
        raise credentials_exception
    if not user.is_active:
        logger.error("❌ [AUTH] Utilisateur %s inactif", user_id)
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Utilisateur inactif",
        )

    logger.info("✅ [AUTH] Utilisateur authentifié : %s", user.id)
    return user


# ============================================================
#  DÉPENDANCES POUR LES TESTS (Optionnel)
# ============================================================

def get_test_user() -> User:
    """Retourne un utilisateur de test (pour les tests unitaires)"""
    return User(
        id=1,
        email="test@example.com",
        first_name="Test",
        last_name="User",
        is_active=True,
    )