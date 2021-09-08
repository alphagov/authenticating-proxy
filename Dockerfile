ARG base_image=ruby:2.7.2
FROM ${base_image}

RUN apt-get update -qq && apt-get upgrade -y
RUN apt-get install -y build-essential nodejs && apt-get clean
RUN gem install foreman

ENV GOVUK_APP_NAME authenticating-proxy
ENV PORT 3107
ENV RAILS_ENV production

ENV APP_HOME /app
RUN mkdir $APP_HOME

WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
ADD .ruby-version $APP_HOME/
RUN bundle install

ADD . $APP_HOME

CMD foreman run web
