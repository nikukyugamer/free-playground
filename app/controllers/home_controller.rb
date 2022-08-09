class HomeController < ApplicationController
  def index
    check_or_create_cloudfront_private_key

    signer = Aws::CloudFront::CookieSigner.new(
      key_pair_id: ENV.fetch('CLOUDFRONT_PUBLIC_KEY'),
      private_key_path: Rails.root.join('config/cloudfront_private_key.pem').to_s
    )

    policy_statement = {
      'Statement' => [
        {
          'Resource' => object_path,
          'Condition' => {
            DateLessThan: {
              'AWS:EpochTime' => 2.minutes.since.to_i
            }
          }
        },
      ]
    }

    cookie_params = signer.signed_cookie(
      object_path,
      policy: policy_statement.to_json
    )

    cookie_params.each do |k, v|
      cookies[k] = case params[:cookie_domain]
                   when 'domain'
                     # assets.neo-kobe-city.com は cookie を受け入れることができることを確認する
                     { value: v, domain: 'neo-kobe-city.com' }
                   when 'assets'
                     # domain: www.neo-kobe-city.com のときは assets では受け入れられないことを確認する
                     { value: v, domain: 'assets.neo-kobe-city.com' }
                   else
                     { value: v }
                   end
    end

    @cookies = cookies.to_h

    @min_tobus2_url = 'https://assets.neo-kobe-city.com/min-tobus2.jpg'
    @min_tukimi3_url = 'https://assets.neo-kobe-city.com/min-tukimi3.jpg'
    @min_undokai1_url = 'https://assets.neo-kobe-city.com/min-undokai1.jpg'
    @min_up1_url = 'https://assets.neo-kobe-city.com/min-up1.jpg'
    @min_xmas3_url = 'https://assets.neo-kobe-city.com/min-xmas3.jpg'
    @min_yuyake3_url = 'https://assets.neo-kobe-city.com/min-yuyake3.jpg'
  end

  private

  def object_path(path='*')
    "https://assets.neo-kobe-city.com/#{path}"
  end

  def check_or_create_cloudfront_private_key
    private_key_path = Rails.root.join('config/cloudfront_private_key.pem')

    return if File.exist?(private_key_path)

    File.write(private_key_path, ENV.fetch('CLOUDFRONT_PRIVATE_KEY'))
  end
end
