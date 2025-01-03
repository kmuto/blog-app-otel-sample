# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
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
