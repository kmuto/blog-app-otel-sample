# blog-app-otel-sample

Ruby on RailsアプリケーションからOpenTelemetryでトレースを書き出すサンプル。

- DBにはPostgreSQLを利用

## 利用
```
$ bundle install
$ rake db:create
$ rake db:migrate
$ rake db:seed
$ MACKEREL_VAXILA_APIKEY=XXX otelcol --config config.yaml &
$ bin/rails s
```

`MACKEREL_VAXILA_APIKEY`はMackerelのAPIキー。

## 作っていた手順
```
$ rails new blog-app-otel-sample -d postgresql
$ cd blog-app-otel-sample
$ rails generate model Post title:string content:text published_at:datetime
$ rails generate model Comment post:references content:text
$ rails db:create
$ rails db:migrate
$ vi app/models/post.rb
(以下に修正)
class Post < ApplicationRecord
  has_many :comments
end
(保存)
$ vi db/seeds.rb
(末尾に以下追加)
# サンプル記事を10件作成
10.times do |i|
  post = Post.create!(
    title: "Post #{i + 1}",
    content: "This is the content of post #{i + 1}.",
    published_at: i.even? ? Time.now - i.days : nil
  )
  # 各記事に5件のコメントを作成
  5.times do |j|
    post.comments.create!(
      content: "Comment #{j + 1} for post #{i + 1}.",
      created_at: Time.now - j.hours
    )
  end
end
(保存)
$ rails db:seed
$ rails generate controller Posts
$ vi app/controllers/posts_controller.rb
(以下に編集)
class PostsController < ApplicationController
  def index
    # 各種SQLクエリを発行し、結果をログに出力
    @all_posts = Post.all

    # WHERE句: 発行されるSQLは `SELECT "posts".* FROM "posts" WHERE "published_at" IS NOT NULL`
    @published_posts = Post.where.not(published_at: nil)

    # JOIN句: 発行されるSQLは `SELECT "posts".*, "comments".* FROM "posts" INNER JOIN "comments" ON "comments"."post_id" = "posts"."id"`
    @posts_with_comments = Post.joins(:comments)

    # COUNTクエリ: 発行されるSQLは `SELECT COUNT(*) FROM "posts"`
    @posts_count = Post.count

    # GROUP BY句: 発行されるSQLは `SELECT "post_id", COUNT(*) FROM "comments" GROUP BY "post_id"`
    @comments_count_per_post = Comment.group(:post_id).count
  end
end
(保存)
$ vi app/views/posts/index.html.erb
(以下を作成)
<h1>Blog Posts</h1>

<h2>All Posts</h2>
<% @all_posts.each do |post| %>
  <p><strong><%= post.title %></strong>: <%= post.content %></p>
<% end %>

<h2>Published Posts</h2>
<% @published_posts.each do |post| %>
  <p><strong><%= post.title %></strong>: Published at <%= post.published_at %></p>
<% end %>

<h2>Posts with Comments</h2>
<% @posts_with_comments.each do |post| %>
  <p><strong><%= post.title %></strong>: <%= post.comments.count %> comments</p>
<% end %>

<h2>Posts Count</h2>
<p>Total Posts: <%= @posts_count %></p>

<h2>Comments Count per Post</h2>
<% @comments_count_per_post.each do |post_id, count| %>
  <p>Post ID <%= post_id %>: <%= count %> comments</p>
<% end %>
(保存)
$ vi config/routes.rb
(rootを以下に変更)
  root to: 'posts#index'
(保存)
$ rails s
(localhost:3000起動を確認してC-c)
$ vi Gemfile
(以下を追加。railsとactive_recordいらないかも)
gem 'opentelemetry-sdk'
gem 'opentelemetry-instrumentation-rails'
gem 'opentelemetry-instrumentation-all'
gem 'opentelemetry-instrumentation-active_record'
gem 'opentelemetry-exporter-otlp'
(保存)
$ bundle install
$ vi config/initializers/opentelemetry.rb
(以下を作成)
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'

# トレースプロバイダーを設定
OpenTelemetry::SDK.configure do |config|
  config.service_name = 'my_rails_app' # サービス名を指定
  config.service_version = '1.0.0'
  
  # 使用するエクスポーターを設定 (OTLP)
  config.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      OpenTelemetry::Exporter::OTLP::Exporter.new(endpoint: 'http://localhost:4318/v1/traces')
    )
  )
  
  # 自動インストルメンテーション
  config.use_all
end
(保存)
$ vi otel-col.yaml
(以下を作成)
receivers:
  otlp:
    protocols:
      grpc:
      http:

exporters:
  logging:
    loglevel: debug
  otlphttp/vaxila:
    endpoint: https://otlp-vaxila.mackerelio.com
    compression: gzip
    headers:
      Mackerel-Api-Key: ${env:MACKEREL_VAXILA_APIKEY}

processors:
  batch:
    timeout: 15s
    send_batch_size: 5000
    send_batch_max_size: 5000
  resource/namespace:
    attributes:
    - key: service.namespace
      value: "kmuto/slowquery-demo"
      action: upsert

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [resource/namespace, batch]
      exporters: [logging, otlphttp/vaxila]
(保存)
$ MACKEREL_VAXILA_APIKEY=XXX otelcol --config config.yaml &
$ rails s
```
