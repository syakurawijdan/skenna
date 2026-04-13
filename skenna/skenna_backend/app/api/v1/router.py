from fastapi import APIRouter

from app.api.v1 import auth, chatbot, cv, history, sodium, users

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(sodium.router, prefix="/sodium", tags=["sodium"])
api_router.include_router(cv.router, prefix="/cv", tags=["cv"])
api_router.include_router(chatbot.router, prefix="/chatbot", tags=["chatbot"])
api_router.include_router(history.router, prefix="/history", tags=["history"])

