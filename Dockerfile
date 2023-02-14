ARG ruby_version=3.1.2
ARG base_image=ghcr.io/alphagov/govuk-ruby-base:$ruby_version
ARG builder_image=ghcr.io/alphagov/govuk-ruby-builder:$ruby_version


FROM $builder_image AS builder
RUN apt-get update -qq && apt-get upgrade -y
RUN apt-get install -y libpq-dev && apt-get clean

WORKDIR $APP_HOME
COPY Gemfile* .ruby-version ./
RUN bundle install
COPY . .
RUN bootsnap precompile --gemfile .


FROM $base_image
RUN apt-get update -qq && apt-get upgrade -y
RUN apt-get install -y libpq-dev && apt-get clean

ENV GOVUK_APP_NAME=authenticating-proxy

WORKDIR $APP_HOME
COPY --from=builder $BUNDLE_PATH $BUNDLE_PATH
COPY --from=builder $BOOTSNAP_CACHE_DIR $BOOTSNAP_CACHE_DIR
COPY --from=builder $APP_HOME .

USER app
CMD ["puma"]
