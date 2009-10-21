module MPI
  mattr_accessor :server_url
  self.server_url = 'http://mpi.server.com/'

  class Response
    attr_reader :xml, :error_code, :error_message, :status, :url

    def initialize(xml)
      @xml = xml
    end

    def successful?
      !(error_message || error_code)
    end

    def parse
      doc = Nokogiri::XML(xml)

      unless (error = doc.xpath("//Error")).empty?
        @error_message = error.text
        @error_code    = error.attr('code')
      else
        @status = doc.xpath("//Transaction").attr('status')
        @url = doc.xpath("//Transaction/URL").text
      end
    end

    def self.parse(xml)
      response = self.new(xml)
    end
  end

  class VerificationRequest
    PARAMS_MAP = {
      'AccountId'       => :account_id,
      'Amount'          => :amount,     #in cents
      'CardNumber'      => :card_number,
      'Description'     => :description,
      'DisplayAmount'   => :display_amount,
      'CurrencyCode'    => :currency,
      'ExpY'            => :exp_year,
      'ExpM'            => :exp_month,
      'URL'             => :termination_url,
    }

    REQUEST_TYPE = 'vereq'

    attr_reader :options, :transaction_id

    def initialize(options, transaction_id)
      @options, @transaction_id = options, transaction_id
    end

    def process
      MPI::Response.parse(post(build_xml))
    end

    private
    def post(xml_request)
      Network.post(MPI.server_url, xml_request)
    end

    def build_xml
      xml = Nokogiri::XML::Builder.new(:encoding => 'UTF-8')

      xml.REQUEST(:type => REQUEST_TYPE) do |xml|
        xml.Transaction(:id => transaction_id) do |xml|
          PARAMS_MAP.each_pair do |key, value|
            xml.send(key, options[value])
          end
        end
      end

      xml.to_xml
    end
  end
end
