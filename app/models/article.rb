class Article < ActiveRecord::Base
  attr_accessible :code, :date, :location, :misc, :money, :number, :organization, :person, :time, :content, :original, :callback_url, :processed

  after_create :process
  after_commit :respond, :if => :processed

  def select_entities
    a = self
    text = a.annotate(a.content)
    entity_hash = {"date" => {}, "location" => {}, "misc" => {}, "money" => {}, "number" => {}, "organization" => {}, "person" => {}, "time" => {}, "ordinal" => {}}
    text.get(:sentences).each do |sentence|
      sentence.get(:tokens).each do |token|
        if token.get(:named_entity_tag).to_s && token.get(:named_entity_tag).to_s != "O"
          puts " #{token.get(:named_entity_tag).to_s} #{token.get(:text).to_s} #{token.get(:index).to_s}"
          entity_hash[token.get(:named_entity_tag).to_s.downcase][token.get(:index).to_s] = token.get(:text).to_s
        end
      end
    end
    entity_hash = entity_hash.reject{|k,v| v.flatten.empty?}
    groups = a.chain_entities(entity_hash)
    a.populate_self(groups)
    self.update_attributes(:processed => true)
  end

  def respond
    attrs = a.attributes.reject{|k,v| v.nil? || ["id", "created_at", "updated_at", "callback_url"].include?(k) }.to_json
    self.make_put_request(self.callback_url, attrs)
  end

  def populate_self(groups)
    a = self
    groups.each do |attrib, vals|
      a.update_attributes(attrib => vals.join(", "))
    end
  end

  def chain_entities(entity_hash)
    sequences = []
    wrds =  Hash.new{|h,k| h[k] = [] }
    entity_hash.each do |tag, words|
      #  if ["location", "person"].include?(tag)
      indexes = words.keys
      sequences = find_sequences(indexes, words)
      if sequences.empty?
        wrds[tag] << words.values.flatten
      else
        sequences.each do |s|
          wrds[tag] << s.map{|seq| words[seq] }.join(" ")
        end
      end
      #  end
    end
    wrds
  end



  def find_sequences(indexes, words, sequence =[])
    indexes.each_with_index do |num, i|
      seqs = []
      if !indexes[i-1].nil?
        if Integer(num) - Integer(indexes[i-1]) == 1
          seqs << indexes[i-1].to_s
          seqs << num.to_s
        elsif seqs.last && !seqs.last.split(" ").include?(indexes[i-1].to_s)
          seqs << indexes[i-1].to_s
        end
      end
      if !seqs.empty?
        if sequence.last && sequence.last.last == indexes[i-1].to_s
          sequence.last << seqs.reject{|s| s == indexes[i-1].to_s}
          sequence.last.flatten!
        else
          sequence << seqs
        end
      end
    end
    sequence
  end

  def annotate(text)
    self.update_column(:original, text)
    text = text.gsub(/[^A-Za-z0-9\s]/,"").squish
    pipeline =  StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :parse, :ner, :dcoref)
    text = StanfordCoreNLP::Text.new(text)
    pipeline.annotate(text)
    return text
  end


  private

  def process
    Processor.create(:article_id => self.id)
  end

end
