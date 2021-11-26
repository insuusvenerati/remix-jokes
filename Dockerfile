FROM node:17-bullseye-slim as base

RUN apt-get update && apt-get upgrade -y

FROM base as deps
WORKDIR /app

ADD package.json yarn.lock ./

RUN yarn install

FROM base as build
WORKDIR /app

ARG DATABASE_URL
ENV DATABASE_URL $DATABASE_URL

COPY --from=deps /app/node_modules /app/node_modules
ADD package.json yarn.lock /app/
ADD prisma .

ADD . .
RUN yarn build

FROM base
WORKDIR /app

ARG SESSION_SECRET
ARG DATABASE_URL
ENV DATABASE_URL $DATABASE_URL
ENV SESSION_SECRET $SESSION_SECRET
ENV NODE_ENV production

COPY --from=deps /app/node_modules /app/node_modules
COPY --from=build /app/build /app/build
COPY --from=build /app/public /app/public
COPY --from=build /app/prisma /app/prisma

ADD . .

RUN yarn prisma generate \
    && yarn prisma db push

EXPOSE 3000

CMD ["yarn", "start"]