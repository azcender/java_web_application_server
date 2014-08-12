# spec/classes/init_spec.rb
require 'spec_helper'

describe "java_web_application_server::init" do
  it { should create_define('tomcat::instance')}
end