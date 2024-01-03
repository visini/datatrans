require "spec_helper"

describe Datatrans::JSON::Transaction::Authorize do
  before do
    @successful_response = {
      "transactionId" => "230223022302230223"
    }

    @failed_response = {
      "error" => {
        "code" => "INVALID_PROPERTY",
        "message" => "init.refno must not be null"
      }
    }

    @valid_params = {
      currency: "CHF",
      refno: "B4B4B4B4B",
      amount: 1337,
      payment_methods: ["ECA", "VIS"],
      success_url: "https://pay.sandbox.datatrans.com/upp/merchant/successPage.jsp",
      cancel_url: "https://pay.sandbox.datatrans.com/upp/merchant/cancelPage.jsp",
      error_url: "https://pay.sandbox.datatrans.com/upp/merchant/errorPage.jsp"
    }

    @expected_request_body = {
      "currency": "CHF",
      "refno": "B4B4B4B4B",
      "amount": 1337,
      "autoSettle": true,
      "paymentMethods": ["ECA", "VIS"],
      "redirect": {
        "successUrl": "https://pay.sandbox.datatrans.com/upp/merchant/successPage.jsp",
        "cancelUrl": "https://pay.sandbox.datatrans.com/upp/merchant/cancelPage.jsp",
        "errorUrl": "https://pay.sandbox.datatrans.com/upp/merchant/errorPage.jsp"
      }
    }

    @invalid_params = {
      currency: "CHF",
      refno: nil,
      amount: 1337,
      payment_methods: ["ECA", "VIS"],
    }
  end

  context "successful response" do
    before do
      allow_any_instance_of(Datatrans::JSON::Transaction::Authorize).to receive(:process).and_return(@successful_response)
    end

    it "generates correct request_body" do
      request = Datatrans::JSON::Transaction::Authorize.new(@datatrans, @valid_params)

      expect(request.request_body).to eq(@expected_request_body)
    end

    it "#process handles a valid datatrans authorize response" do
      @transaction = Datatrans::JSON::Transaction.new(@datatrans, @valid_params)
      expect(@transaction.authorize).to be true
    end
  end

  context "with autoSettle specified" do
    it "uses autoSettle=false in request_body" do
      params_with_auto_settle = @valid_params.merge(auto_settle: false)
      request = Datatrans::JSON::Transaction::Authorize.new(@datatrans, params_with_auto_settle)

      expected_request_body_without_auto_settle = @expected_request_body.merge(autoSettle: false)
      expect(request.request_body).to eq(expected_request_body_without_auto_settle)
    end
  end

  context "with card provided" do
    it "uses card in request_body" do
      card_params = {
        "alias": "AAABcH0Bq92s3kgAESIAAbGj5NIsAHWC",
        "expiryMonth": "06",
        "expiryYear": "25"
      }

      params_with_auto_settle = @valid_params.merge(card: card_params)
      request = Datatrans::JSON::Transaction::Authorize.new(@datatrans, params_with_auto_settle)

      expected_request_body_with_card = @expected_request_body.merge("card" => card_params)
      expect(request.request_body).to eq(expected_request_body_with_card)
    end
  end

  context "failed response" do
    before do
      allow_any_instance_of(Datatrans::JSON::Transaction::Authorize).to receive(:process).and_return(@failed_response)
      @transaction = Datatrans::JSON::Transaction.new(@datatrans, @invalid_params)
    end

    it "#process handles a failed datatrans authorize response" do
      expect(@transaction.authorize).to be false
    end

    it "returns error details" do
      @transaction.authorize
      expect(@transaction.response.error_code).to eq "INVALID_PROPERTY"
      expect(@transaction.response.error_message).to eq "init.refno must not be null"
    end
  end
end
