#!/usr/bin/env perl
use strict;
use warnings;
use Mojolicious::Lite;        # лёгкий DSL-фреймворк

# --- Лог каждого запроса ---
under sub {
  my $c = shift;
  my $ip = $c->tx->remote_address // '-';
  my $path = $c->req->url->path->to_string;
  my $method = $c->req->method;
  app->log->info("[$ip] $method $path");
  return 1; # пропускаем дальше
};

# GET /
get '/' => sub {
  my $c = shift;
  $c->render(text => "Hello, Perl! See /time and POST /echo");
};

# GET /time -> JSON { now: "...ISO..." }
get '/time' => sub {
  my $c = shift;
  my $now = Mojo::Date->new(time)->to_datetime; # ISO 8601
  $c->render(json => { now => $now });
};

# POST /echo -> принимает JSON и возвращает JSON + server_time + валидация email
# Пример тела: { "name": "Alex", "email": "test@example.com" }
post '/echo' => sub {
  my $c = shift;
  my $data = $c->req->json // {};
  
  # простая валидация: email похож на email?
  my $email = $data->{email} // '';
  if ($email ne '' && $email !~ /^[^\s\@]+@[^\s\@]+\.[^\s\@]+$/) {
    return $c->render(status => 400, json => { error => 'Invalid email' });
  }

  my $server_time = Mojo::Date->new(time)->to_datetime;
  $data->{server_time} = $server_time;
  $c->render(json => $data);
};

app->start;
