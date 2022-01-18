# TODO: make this default to govuk-ruby once it's being pushed somewhere public
ARG base_image=ruby:2.7.2
ARG app_home=/app

FROM ${base_image} AS builder

ARG app_home

RUN apt-get update -qy && \
    apt-get upgrade -y

ENV RAILS_ENV=production GOVUK_APP_NAME=authenticating-proxy

RUN mkdir -p ${app_home}

WORKDIR ${app_home}

COPY Gemfile* .ruby-version ${app_home}/

RUN bundle config set deployment 'true' && \
    bundle config set without 'development test' && \
    bundle install -j8 --retry=2

COPY . ${app_home}


FROM $base_image

ARG app_home

RUN apt-get update -qy && \
    apt-get upgrade -y

ENV RAILS_ENV=production GOVUK_APP_NAME=authenticating-proxy

COPY --from=builder /usr/local/bundle/ /usr/local/bundle/

COPY --from=builder ${app_home} ${app_home}/

WORKDIR ${app_home}

CMD bundle exec puma
