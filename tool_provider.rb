require 'sinatra'
require 'ims/lti'
require 'open-uri'
require 'pygments'
require 'json'
require 'yaml'
require 'oauth/request_proxy/rack_request'

enable :sessions
set :protection, :except => :frame_options

$extension_platform = "canvas.instructure.com"
#@context_url = get_context_url(request)

get '/' do
  erb :index
end

get '/embed' do
  content_type :json
  code = ''
  open(params['url']) { |io| code = io.read }

  html = Pygments.highlight(code, :options => {
    :encoding  => 'utf-8',
    # :linenos   => 'inline',
    :linenos   => 'table',
    :style     => 'manni',
    :noclasses => true,
   #:nowrap => true,
   #:cssstyles => 'width:100%', #Inline CSS styles for the wrapping <div> tag (default: '').
   :prestyles => 'overflow:scroll;width:100%' #Inline CSS styles for the <pre> tag (default: ''). New in Pygments 0.11.
  })

  { "version" => "1.0",
    "type"    => "rich",
    "width"   => "900",
    #"height"  => 344,
    "html"    => html
    }.to_json
end

# The url for launching the tool
post '/launch' do
  @tp = IMS::LTI::ToolProvider.new(nil, nil, params)
  @tp.extend IMS::LTI::Extensions::Content::ToolProvider
  erb :launch
end

get '/config.xml' do
  tc = IMS::LTI::ToolConfig.new(
    :title        => 'Emebd Gist',
    :launch_url   => context_url + 'launch',
    :description  => 'Embed Github Gists in your pages and discussions'
  )

  tc.set_ext_params($extension_platform, {
    'privacy_level' => 'public',
    'text'          => 'Embed Gist',
    'editor_button' => {
      'enabled'           => 'true',
      'icon_url'          => context_url + 'img/GitHub-Mark-32px.png',
      'secltion_width'    => '720',
      'selection_height'  => '480',
    }
  })

  headers 'Content-Type' => 'text/xml'
  tc.to_xml(:indent => 2)
end

def context_url
  "#{request.scheme}://#{request.host_with_port}/"
end

def show_error(message)
  @message = message
  erb :error
end