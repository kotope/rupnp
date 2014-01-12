require_relative 'spec_helper'

module RUPNP

  describe ControlPoint do
    include EM::SpecHelper

    let(:cp) { ControlPoint.new(:all) }

    it 'should initialize a new instance' do
      expect(cp.devices).to be_a(Array)
      expect(cp.devices).to be_empty
    end

    [:search_only, :start].each do |meth|
      it "##{meth} should detect devices" do
        em do
          uuid1 = UUID.generate
          generate_search_responder uuid1, 1234
          generate_search_responder uuid1, 1234
          uuid2 = UUID.generate
          generate_search_responder uuid2, 1235

          stub_request(:get, '127.0.0.1:1234').to_return :headers => {
            'SERVER' => 'OS/1.0 UPnP/1.1 TEST/1.0'
          }, :body => generate_xml_device_description(uuid1)
          stub_request(:get, '127.0.0.1:1235').to_return :headers => {
            'SERVER' => 'OS/1.0 UPnP/1.1 TEST/1.0'
          }, :body => generate_xml_device_description(uuid2)

          cp.send meth

          EM.add_timer(1) do
            expect(cp.devices).to have(2).item
            done
          end
        end
      end
    end

    it '#search_only should not register devices after wait time is expired' do
      em do
        uuid = UUID.generate
        stub_request(:get, '127.0.0.1:1234').to_return :headers => {
          'SERVER' => 'OS/1.0 UPnP/1.1 TEST/1.0'
        }, :body => generate_xml_device_description(uuid)

        cp = ControlPoint.new(:all, :response_wait_time => 1)
        cp.search_only

        EM.add_timer(2) do
          expect(cp.devices).to be_empty
          generate_search_responder uuid, 1234
          EM.add_timer(1) do
            expect(cp.devices).to be_empty
            done
          end
        end
      end
    end

    it '#start should listen for alive, update or byebye notifications from devices'
    it '#find_device_by_udn should get known devices'
  end

end

