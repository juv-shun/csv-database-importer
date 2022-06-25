FROM python:3.10

LABEL maintainer Shun Fukusumi <shun.fukusumi@gmail.com>

ENV TZ Asia/Tokyo

COPY app/ /app

COPY pyproject.toml poetry.lock ./

RUN pip install -U pip \
    && pip install poetry \
    && poetry config virtualenvs.create false \
    && poetry install -n --no-dev
