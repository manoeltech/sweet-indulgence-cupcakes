"""O banco guarda horários em UTC; a loja trabalha no horário de Brasília."""
from datetime import datetime, time, timezone
from zoneinfo import ZoneInfo

FUSO_LOJA = ZoneInfo("America/Sao_Paulo")


def para_local(momento_utc):
    return momento_utc.replace(tzinfo=timezone.utc).astimezone(FUSO_LOJA)


def hoje_local():
    return datetime.now(FUSO_LOJA).date()


def limites_utc(inicio, fim):
    """Converte um intervalo de datas locais (inclusivo) para datetimes UTC sem fuso, como estão no banco."""
    de = datetime.combine(inicio, time.min, FUSO_LOJA).astimezone(timezone.utc).replace(tzinfo=None)
    ate = datetime.combine(fim, time.max, FUSO_LOJA).astimezone(timezone.utc).replace(tzinfo=None)
    return de, ate
