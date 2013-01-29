class Article < ActiveRecord::Base
  include WebThings
  
  attr_accessible :code, :date, :location, :misc, :money, :number, :organization, :person, :time, :content, :original, :callback_url, :processed, :duration, :ordinal, :percent, :info

  after_create :process
  after_commit :respond, :if => :processed

  def select_entities
    a = self
    a.update_column(:original, a.content)
    wrds =  Hash.new{|h,k| h[k] = [] }
    texts = a.content.split(".")
    pipeline =  StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :parse, :ner, :dcoref)
    texts.each do |text|
      text = a.annotate(text, pipeline)
      entity_hash = {"date" => {}, "location" => {}, "misc" => {}, "money" => {}, "number" => {}, "organization" => {}, "person" => {}, "time" => {}, "ordinal" => {}, "duration" => {}, "percent" => {}}
      text.get(:sentences).each do |sentence|
        sentence.get(:tokens).each do |token|
          if token.get(:named_entity_tag).to_s && token.get(:named_entity_tag).to_s != "O"
            puts "GOT #{token.get(:named_entity_tag).to_s} WTH #{token.get(:text).to_s}"
            entity_hash[token.get(:named_entity_tag).to_s.downcase][token.get(:index).to_s] = token.get(:text).to_s
          end
        end
      end
      entity_hash = entity_hash.reject{|k,v| v.flatten.empty?}
      a.chain_entities(entity_hash, wrds)
    end
    puts "GROUPS: #{wrds}"    
    a.populate_self(wrds)
    self.update_attributes(:processed => true)
  end

  def respond
    attrs = self.attributes.reject{|k,v| v.nil? || ["id", "created_at", "updated_at", "callback_url"].include?(k) }.to_json
    self.make_post_request(self.callback_url, attrs)
  end

  def populate_self(groups)
    a = self
    groups.each do |attrib, vals|
      if ["organization", "person", "location"].include?(attrib)
        a.update_attributes(attrib => vals.join(", "))
      end
    end
    if a.location
      a.location = a.location.split(", ").uniq.join(", ")
    end
    if a.person      
      a.person = a.person.split(", ").uniq.join(", ")
    end
    if a.organization
      a.organization = a.organization.split(", ").uniq.join(", ")
    end
    a.save!
  end

  def chain_entities(entity_hash, wrds)
    sequences = []
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

  def annotate(text, pipeline)
    text = text.gsub(/[^A-Za-z0-9\s]/,"").squish
    text = StanfordCoreNLP::Annotation.new(text)
    pipeline.annotate(text)
    return text
  end


  private

  def process
    Processor.create(:article_id => self.id)
  end

end
