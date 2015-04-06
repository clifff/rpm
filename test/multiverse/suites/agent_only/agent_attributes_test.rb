# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

class AgentAttributesTest < Minitest::Test

  include MultiverseHelpers

  setup_and_teardown_agent

  def test_http_response_code_default_destinations
    run_transaction do |txn|
      txn.http_response_code = 418
    end

    assert_transaction_trace_has_agent_attribute("httpResponseCode", 418)
    assert_event_has_agent_attribute("httpResponseCode", 418)
    assert_error_has_agent_attribute("httpResponseCode", 418)

    refute_browser_monitoring_has_agent_attributes
  end

  def test_request_parameters_default_destinations_without_capture_params
    run_transaction(:capture_params => false) do |txn|
      txn.merge_request_parameters(:duly => "noted")
    end

    refute_transaction_trace_has_agent_attribute("request.parameters.duly")
    refute_event_has_agent_attribute("request.parameters.duly")
    refute_error_has_agent_attribute("request.parameters.duly")
    refute_browser_monitoring_has_agent_attributes
  end

  def test_request_parameters_default_destinations_with_capture_params
    run_transaction(:capture_params => true) do |txn|
      txn.merge_request_parameters(:duly => "noted")
    end

    assert_transaction_trace_has_agent_attribute("request.parameters.duly", "noted")
    assert_error_has_agent_attribute("request.parameters.duly", "noted")

    refute_event_has_agent_attribute("request.parameters.duly")
    refute_browser_monitoring_has_agent_attributes
  end

  def run_transaction(config = {})
    default_config = {
      :'transaction_tracer.attributes.enabled' => true,
      :'transaction_events.attributes.enabled' => true,
      :'error_collector.attributes.enabled'    => true,
      :'browser_monitoring.attributes.enabled' => true
    }

    assert_raises(RuntimeError) do
      with_config(default_config.merge(config)) do
        in_transaction do |txn|
          yield(txn)

          # JS instrumentation happens within transaction, so capture it now
          capture_js_data

          # Have to raise an error to exercise attribute capture there
          raise "O_o"
        end
      end
    end

    run_harvest
  end

  def capture_js_data
    state = NewRelic::Agent::TransactionState.tl_get
    events = stub(:subscribe => nil)
    @instrumentor = NewRelic::Agent::JavascriptInstrumentor.new(events)
    @js_data = @instrumentor.data_for_js_agent(state)
  end

  def assert_transaction_trace_has_agent_attribute(attribute, expected)
    # TODO: Implement once we've updated TT's with attributes!
  end

  def assert_event_has_agent_attribute(attribute, expected)
    assert_equal expected, single_event_posted.last[attribute]
  end

  def assert_error_has_agent_attribute(attribute, expected)
    assert_equal expected, single_error_posted.params["agentAttributes"][attribute]
  end


  def refute_transaction_trace_has_agent_attribute(attribute)
    # TODO: Implement once we've updated TT's with attributes!
  end

  def refute_event_has_agent_attribute(attribute)
    refute_includes single_event_posted.last, attribute
  end

  def refute_error_has_agent_attribute(attribute)
    refute_includes single_error_posted.params["agentAttributes"], attribute
  end

  def refute_browser_monitoring_has_agent_attributes
    refute_includes @js_data, "atts"
  end
end
