class Processor
  include Resque::Plugins::Status
  @queue = :collect_queue

  def perform
    article_id = options["article_id"]
    article = Article.find(article_id)
    article.select_entities
  end




end
