module WebThings
  module ClassMethods


  end  
  def get_host
    if Rails.env.production?
      @host = `curl http://169.254.169.254/latest/meta-data/public-ipv4`
    elsif Rails.env.development?
      @host = "localhost:3000"
    end
    return @host
  end

  def make_put_request(url, body)
    require 'web_things'
    @uri = URI(url)
    request = Net::HTTP::Put.new(@uri.path, initheader = {'Content-Type' =>'application/json'})
    request.body = body
    response = Net::HTTP.new(@uri.host, @uri.port).start {|http| http.request(request) }
  end


  def make_post_request(url, body)
    require 'web_things'
    @uri = URI(url)
    request = Net::HTTP::Post.new(@uri.path, initheader = {'Content-Type' =>'application/json'})
    request.body = body
    response = Net::HTTP.new(@uri.host, @uri.port).start {|http| http.request(request) }
  end


end