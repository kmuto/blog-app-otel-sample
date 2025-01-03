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
