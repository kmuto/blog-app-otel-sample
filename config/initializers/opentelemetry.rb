require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'

# トレースプロバイダーを設定
OpenTelemetry::SDK.configure do |config|
  config.service_name = 'my_rails_app' # サービス名を指定
  config.service_version = '1.0.0'
  
  # 使用するエクスポーターを設定 (OTLP)
  config.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      OpenTelemetry::Exporter::OTLP::Exporter.new(endpoint: 'http://localhost:4318/v1/traces')
    )
  )
  
  # RailsとActive Recordの自動インストルメンテーション
  config.use_all
  #config.use 'OpenTelemetry::Instrumentation::PG'
  #config.use 'OpenTelemetry::Instrumentation::Rails'
  #config.use 'OpenTelemetry::Instrumentation::ActiveRecord'
  #config.use 'OpenTelemetry::Instrumentation::ActiveRecord', {
  #  enable_sql_obfuscation: false # クエリ内容の隠蔽を無効化
  #}
end
