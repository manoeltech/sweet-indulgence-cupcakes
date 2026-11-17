#!/usr/bin/env bash
# Build no Render: instala as gems, compila os assets, prepara o banco e
# insere os dados de demonstração (o seed só cria o que ainda não existe).
set -o errexit

bundle install
bin/rails assets:precompile
bin/rails assets:clean
bin/rails db:prepare
bin/rails db:seed
