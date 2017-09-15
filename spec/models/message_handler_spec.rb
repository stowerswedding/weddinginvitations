require 'rails_helper'

RSpec.describe MessageHandler, type: :model do
  TWILIO = Twilio::REST::Api::V2010::AccountContext::MessageList
  let(:twilio_number) { '+12103618994' }

  before { allow_any_instance_of(TWILIO).to receive(:create) }

  describe '#send_pending_invites' do
    subject { MessageHandler.send_pending_invites }

    context 'when invitee group with one invitee is invitation_pending' do
      let!(:invitee_group) { FactoryGirl.create(:invitee_group) }

      include_examples 'progress point should be set to', 'invitation_sent'

      it 'should send a text message' do
        lead_number = invitee_group.leads.first.phone_number
        message = "Save the Date!\n\nJoshua Stowers and Anastasia Krisan are excited to invite Anastasia to our wedding.\u2028\n3pm on January 14th, 2018 at Our Lady of Grace: 223 East Summit San Antonio, Texas 78212\u2028\u2028\nDinner and dancing to follow at Magnolia Gardens on Main: 2030 N Main Ave San Antonio, TX 78212\n\nPlease text YES if you are saving the date and can join us or text NO if sadly, you won’t be able to be with us.\n\nSee more details on the event and our wedding registry at: http://wedding.stowers.info"

        expect_any_instance_of(TWILIO).to receive(:create).with(to: lead_number, from: twilio_number, body: message)
        subject
      end
    end

    context 'when invitee group with two invitees is invitation_pending' do
      let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee) }

      include_examples 'progress point should be set to', 'invitation_sent'

      it 'should send a text message' do
        lead_number = invitee_group.leads.first.phone_number
        message = "Save the Date!\n\nJoshua Stowers and Anastasia Krisan are excited to invite Anastasia and Joshua to our wedding.\u2028\n3pm on January 14th, 2018 at Our Lady of Grace: 223 East Summit San Antonio, Texas 78212\u2028\u2028\nDinner and dancing to follow at Magnolia Gardens on Main: 2030 N Main Ave San Antonio, TX 78212\n\nPlease text YES if you are saving the date and can join us or text NO if sadly, you won’t be able to be with us. If only part of your party can come text PART.\n\nSee more details on the event and our wedding registry at: http://wedding.stowers.info"

        expect_any_instance_of(TWILIO).to receive(:create).with(to: lead_number, from: twilio_number, body: message)
        subject
      end
    end

    context 'when invitee group with three invitees is invitation_pending' do
      let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :third_invitee) }

      include_examples 'progress point should be set to', 'invitation_sent'

      it 'should send a text message' do
        lead_number = invitee_group.leads.first.phone_number
        message = "Save the Date!\n\nJoshua Stowers and Anastasia Krisan are excited to invite Anastasia, Joshua, and Yuki to our wedding.\u2028\n3pm on January 14th, 2018 at Our Lady of Grace: 223 East Summit San Antonio, Texas 78212\u2028\u2028\nDinner and dancing to follow at Magnolia Gardens on Main: 2030 N Main Ave San Antonio, TX 78212\n\nPlease text YES if you are saving the date and can join us or text NO if sadly, you won’t be able to be with us. If only part of your party can come text PART.\n\nSee more details on the event and our wedding registry at: http://wedding.stowers.info"

        expect_any_instance_of(TWILIO).to receive(:create).with(to: lead_number, from: twilio_number, body: message)
        subject
      end
    end
  end

  describe '#receive_message' do
    let(:message) { 'yes' }
    subject { MessageHandler.receive_message('+12107239168', message) }

    context 'when message is yes' do
      context 'when invitee group with one invitee' do
        context 'when invitation_sent' do
          let!(:invitee_group) { FactoryGirl.create(:invitee_group, :invitation_sent) }

          include_examples 'progress point should be set to', 'rsvp_received'

          include_examples 'all invitees accept invitation'

          it 'should send a text message' do
            lead_number = '+1' + invitee_group.leads.first.phone_number
            message = ['Thank you for RSVPing! We can’t wait to celebrate with you.',
                       'You can see more details on the event and find our gift registry at http://wedding.stowers.info',
                       'Do you have any diet restrictions or are you under the age of 21/will not drink? Please text YES or NO.'
                      ].join("\n")

            expect_any_instance_of(TWILIO).to receive(:create).with(to: lead_number, from: twilio_number, body: message)
            subject
          end
        end

        context 'when rsvp_received' do
          let!(:invitee_group) { FactoryGirl.create(:invitee_group, :rsvp_received, :all_accepted) }

          include_examples 'progress point should be set to', 'awaiting_diet'

          it 'should send a text message' do
            lead_number = '+1' + invitee_group.leads.first.phone_number
            message = 'Are you (1) vegetarian, (2) vegan, (3) under 21/will not drink or (4) other? Plese text the numbers (separated with commas) associated with the statements that apply to you.'

            expect_any_instance_of(TWILIO).to receive(:create).with(to: lead_number, from: twilio_number, body: message)
            subject
          end
        end
      end

      context 'when invitee group with two invitees' do
        context 'when invitation_sent' do
          let!(:invitee_group) { FactoryGirl.create(:invitee_group, :invitation_sent, :second_invitee) }

          include_examples 'progress point should be set to', 'rsvp_received'

          include_examples 'all invitees accept invitation'

          it 'should send a text message' do
            lead_number = '+1' + invitee_group.leads.first.phone_number
            message = ['Thank you for RSVPing! We can’t wait to celebrate with you.',
                       'You can see more details on the event and find our gift registry at http://wedding.stowers.info',
                       'Is there anyone in your party that has diet restrictions or is under the age of 21/will not drink? Please text YES or NO.'
            ].join("\n")

            expect_any_instance_of(TWILIO).to receive(:create).with(to: lead_number, from: twilio_number, body: message)
            subject
          end
        end

        context 'when rsvp_received' do
          let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :rsvp_received, :all_accepted) }

          include_examples 'progress point should be set to', 'diet_flow_initialized'

          it 'should send a text message' do
            lead_number = '+1' + invitee_group.leads.first.phone_number
            message = [ 'Alright, here are the people in your party:',
                           '(1) Anastasia',
                           '(2) Joshua',
                           'Please text the numbers (separated with commas) associated with the individuals who have dietary restrictions or who are under the age of 21/will not drink.'].join("\n")

            expect_any_instance_of(TWILIO).to receive(:create).with(to: lead_number, from: twilio_number, body: message)
            subject
          end
        end
      end

      context 'when invitee group with three invitees' do
        context 'when invitation_sent' do
          let!(:invitee_group) { FactoryGirl.create(:invitee_group, :invitation_sent, :second_invitee, :third_invitee) }

          include_examples 'progress point should be set to', 'rsvp_received'

          include_examples 'all invitees accept invitation'

          it 'should send a text message' do
            lead_number = '+1' + invitee_group.leads.first.phone_number
            message = ['Thank you for RSVPing! We can’t wait to celebrate with you.',
                       'You can see more details on the event and find our gift registry at http://wedding.stowers.info',
                       'Is there anyone in your party that has diet restrictions or is under the age of 21/will not drink? Please text YES or NO.'
            ].join("\n")

            expect_any_instance_of(TWILIO).to receive(:create).with(to: lead_number, from: twilio_number, body: message)
            subject
          end
        end

        context 'when rsvp_received' do
          let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :third_invitee, :rsvp_received, :all_accepted) }

          include_examples 'progress point should be set to', 'diet_flow_initialized'

          it 'should send a text message' do
            lead_number = '+1' + invitee_group.leads.first.phone_number
            message = [ 'Alright, here are the people in your party:',
                        '(1) Anastasia',
                        '(2) Joshua',
                        '(3) Yuki',
                        'Please text the numbers (separated with commas) associated with the individuals who have dietary restrictions or who are under the age of 21/will not drink.'].join("\n")

            expect_any_instance_of(TWILIO).to receive(:create).with(to: lead_number, from: twilio_number, body: message)
            subject
          end
        end
      end
    end

    context 'when message is no' do
      let(:message) { 'no' }

      context 'when invitee group with one invitee' do
        context 'when invitation_sent' do
          let!(:invitee_group) { FactoryGirl.create(:invitee_group, :invitation_sent) }

          include_examples 'progress point should be set to', 'complete'

          include_examples 'all invitees decline invitation'

          include_examples 'should generate declination message'
        end

        context 'when rsvp_received' do
          let!(:invitee_group) { FactoryGirl.create(:invitee_group, :rsvp_received, :all_accepted) }

          include_examples 'progress point should be set to', 'complete'

          include_examples 'should set every accepted invitee to will_drink'

          include_examples 'should generate conclusion message'
        end
      end

      context 'when invitee group with two invitees' do
        context 'when invitation_sent' do
          let!(:invitee_group) { FactoryGirl.create(:invitee_group, :invitation_sent, :second_invitee) }

          include_examples 'progress point should be set to', 'complete'

          include_examples 'all invitees decline invitation'

          include_examples 'should generate declination message'
        end

        context 'when rsvp_received' do
          context 'and all accepted' do
            let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :rsvp_received, :all_accepted) }

            include_examples 'progress point should be set to', 'complete'

            include_examples 'should set every accepted invitee to will_drink'

            include_examples 'should generate conclusion message'
          end

          context 'and only invitee 1 of the group accepted invitation' do
            let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :rsvp_received, :partial_accepted, rsvp_accepted_indexes: [1]) }

            include_examples 'progress point should be set to', 'complete'

            include_examples 'should set every accepted invitee to will_drink'

            include_examples 'should generate conclusion message'
          end

          context 'and only invitee 2 of the group accepted invitation' do
            let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :rsvp_received, :partial_accepted, rsvp_accepted_indexes: [2]) }

            include_examples 'progress point should be set to', 'complete'

            include_examples 'should set every accepted invitee to will_drink'

            include_examples 'should generate conclusion message'
          end
        end
      end

      context 'when invitee group with three invitees' do
        context 'when invitation_sent' do
          let!(:invitee_group) { FactoryGirl.create(:invitee_group, :invitation_sent, :second_invitee, :third_invitee) }
          include_examples 'progress point should be set to', 'complete'

          include_examples 'all invitees decline invitation'

          include_examples 'should generate declination message'
        end

        context 'when rsvp_received' do
          context 'and all accepted' do
            let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :third_invitee, :rsvp_received, :all_accepted) }

            include_examples 'progress point should be set to', 'complete'

            include_examples 'should set every accepted invitee to will_drink'

            include_examples 'should generate conclusion message'
          end

          context 'and only invitee 1 of the group accepted invitation' do
            let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :third_invitee, :rsvp_received, :partial_accepted, rsvp_accepted_indexes: [1]) }

            include_examples 'progress point should be set to', 'complete'

            include_examples 'should set every accepted invitee to will_drink'

            include_examples 'should generate conclusion message'
          end

          context 'and only invitee 2 of the group accepted invitation' do
            let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :third_invitee, :rsvp_received, :partial_accepted, rsvp_accepted_indexes: [2]) }

            include_examples 'progress point should be set to', 'complete'

            include_examples 'should set every accepted invitee to will_drink'

            include_examples 'should generate conclusion message'
          end

          context 'and only invitee 3 of the group accepted invitation' do
            let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :third_invitee, :rsvp_received, :partial_accepted, rsvp_accepted_indexes: [3]) }

            include_examples 'progress point should be set to', 'complete'

            include_examples 'should set every accepted invitee to will_drink'

            include_examples 'should generate conclusion message'
          end

          context 'and only invitees 1 and 2 of the group accepted invitation' do
            let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :third_invitee, :rsvp_received, :partial_accepted, rsvp_accepted_indexes: [1, 2]) }

            include_examples 'progress point should be set to', 'complete'

            include_examples 'should set every accepted invitee to will_drink'

            include_examples 'should generate conclusion message'
          end

          context 'and only invitees 2 and 3 of the group accepted invitation' do
            let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :third_invitee, :rsvp_received, :partial_accepted, rsvp_accepted_indexes: [2, 3]) }

            include_examples 'progress point should be set to', 'complete'

            include_examples 'should set every accepted invitee to will_drink'

            include_examples 'should generate conclusion message'
          end

          context 'and only invitees 1 and 3 of the group accepted invitation' do
            let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :third_invitee, :rsvp_received, :partial_accepted, rsvp_accepted_indexes: [1, 3]) }

            include_examples 'progress point should be set to', 'complete'

            include_examples 'should set every accepted invitee to will_drink'

            include_examples 'should generate conclusion message'
          end
        end
      end
    end

    context 'when message is part' do
      let(:message) { 'part' }

      context 'when invitee group with two invitees' do
        context 'when invitation_sent' do
          let!(:invitee_group) { FactoryGirl.create(:invitee_group, :invitation_sent, :second_invitee) }

          include_examples 'progress point should be set to', 'awaiting_partial_rsvp'

          include_examples 'should generate next message instructions'
        end
      end

      context 'when invitee group with three invitees' do
        context 'when invitation_sent' do
          let!(:invitee_group) { FactoryGirl.create(:invitee_group, :invitation_sent, :second_invitee, :third_invitee) }
          include_examples 'progress point should be set to', 'awaiting_partial_rsvp'

          include_examples 'should generate next message instructions'
        end
      end
    end

    numbers = ('1'..'5').to_a
    numbers.each do |number|
      context 'when message is ' + number do
        let(:message) { number }

        context 'when invitee group with one invitee' do
          context 'when awaiting_diet' do
            let!(:invitee_group) { FactoryGirl.create(:invitee_group, :awaiting_diet, :all_accepted, :all_awaiting_diet) }

            include_examples 'progress point should be set to', 'complete', message: number

            include_examples 'should set diet to', number

            include_examples 'should generate post diet message', number
          end
        end

        context 'when invitee group with two invitees' do
          context 'when awaiting_partial_rsvp' do
            let!(:invitee_group) { FactoryGirl.create(:invitee_group, :awaiting_partial_rsvp, :second_invitee) }

            include_examples 'progress point should be set to', 'rsvp_received', message: number

            include_examples 'part of the invitees accept invitation', number

            include_examples 'should send partial acceptance message', number
          end

          context 'when diet_flow_initialized' do
            context 'and all accepted' do
              let!(:invitee_group) { FactoryGirl.create(:invitee_group, :diet_flow_initialized, :second_invitee, :all_accepted) }

              include_examples 'progress point should be set to', 'awaiting_diet', message: number

              include_examples 'should mark those with diet', number

              include_examples 'should send message with invitees with diet', number
            end

            ('1'..'2').each do |invitee_number|
              context 'and only invitee ' + invitee_number + ' accepted' do
                let!(:invitee_group) { FactoryGirl.create(:invitee_group, :diet_flow_initialized, :second_invitee, :partial_accepted, rsvp_accepted_indexes: [invitee_number.to_i]) }

                include_examples 'progress point should be set to', 'awaiting_diet', message: number

                include_examples 'should mark those with diet', number

                include_examples 'should send message with invitees with diet', number
              end
            end
          end

          context 'when awaiting_diet' do
            context 'when all invitees awaiting diet' do
              let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :awaiting_diet, :all_accepted, :all_awaiting_diet) }

              include_examples 'progress point should be set to', 'awaiting_diet', message: number

              include_examples 'should set diet to', number

              include_examples 'should generate post diet message', number
            end

            ('1'..'2').each do |invitee_number|
              context 'when only invitee ' + invitee_number + ' is awaiting diet' do
                let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :awaiting_diet, :all_accepted, :partial_awaiting_diet, awaiting_diet_indexes: [invitee_number.to_i]) }

                include_examples 'progress point should be set to', 'complete', message: number

                include_examples 'should set diet to', number

                include_examples 'should generate post diet message', number
              end
            end
          end
        end

        context 'when invitee group with three invitees' do
          context 'when awaiting_partial_rsvp' do
            let!(:invitee_group) { FactoryGirl.create(:invitee_group, :awaiting_partial_rsvp, :second_invitee, :third_invitee) }

            include_examples 'progress point should be set to', 'rsvp_received', message: number

            include_examples 'part of the invitees accept invitation', number

            include_examples 'should send partial acceptance message', number
          end

          context 'when diet_flow_initialized' do
            context 'and all accepted' do
              let!(:invitee_group) { FactoryGirl.create(:invitee_group, :diet_flow_initialized, :second_invitee, :third_invitee, :all_accepted) }

              include_examples 'progress point should be set to', 'awaiting_diet', message: number

              include_examples 'should mark those with diet', number

              include_examples 'should send message with invitees with diet', number
            end

            ('1'..'3').each do |invitee_number|
              context 'and only invitee ' + invitee_number + ' accepted' do
              let!(:invitee_group) { FactoryGirl.create(:invitee_group, :diet_flow_initialized, :second_invitee, :third_invitee, :partial_accepted, rsvp_accepted_indexes: [invitee_number.to_i]) }

              include_examples 'progress point should be set to', 'awaiting_diet', message: number

              include_examples 'should mark those with diet', number

              include_examples 'should send message with invitees with diet', number
              end
            end

            (('1'..'3').to_a).combination(2).to_a.each do |invitee_numbers|
              context 'and only invitee ' + invitee_numbers.join(' and ') + ' accepted' do
                invitee_numbers = invitee_numbers.map { |i| i.to_i }
                let!(:invitee_group) { FactoryGirl.create(:invitee_group, :diet_flow_initialized, :second_invitee, :third_invitee, :partial_accepted, rsvp_accepted_indexes: invitee_numbers) }

                include_examples 'progress point should be set to', 'awaiting_diet', message: number

                include_examples 'should mark those with diet', number

                include_examples 'should send message with invitees with diet', number
              end
            end

          end

          context 'when awaiting_diet' do
            context 'when all invitees awaiting diet' do
              let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :third_invitee, :awaiting_diet, :all_accepted, :all_awaiting_diet) }

              include_examples 'progress point should be set to', 'awaiting_diet', message: number

              include_examples 'should set diet to', number

              include_examples 'should generate post diet message', number
            end

            ('1'..'3').each do |invitee_number|
              context 'when only invitee ' + invitee_number + ' is awaiting diet' do
                let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :third_invitee, :awaiting_diet, :all_accepted, :partial_awaiting_diet, awaiting_diet_indexes: [invitee_number.to_i]) }

                include_examples 'progress point should be set to', 'complete', message: number

                include_examples 'should set diet to', number

                include_examples 'should generate post diet message', number
              end
            end

            (('1'..'3').to_a).combination(2).to_a.each do |invitee_numbers|
              context 'when invitee ' + invitee_numbers.join(' and ') + ' are awaiting diet' do
                invitee_numbers = invitee_numbers.map { |i| i.to_i }
                let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :third_invitee, :awaiting_diet, :all_accepted, :partial_awaiting_diet, awaiting_diet_indexes: invitee_numbers) }

                include_examples 'progress point should be set to', 'awaiting_diet', message: number

                include_examples 'should set diet to', number

                include_examples 'should generate post diet message', number
              end
            end

          end
        end
      end
    end

    numbers_unique_groups_of_2 = numbers.combination(2).to_a
    numbers_unique_groups_of_2.each do |number_group|
      number = number_group.join(', ')
      context 'when message is ' + number do
        let(:message) { number }

        context 'when invitee group with one invitee' do
          context 'when awaiting_diet' do
            let!(:invitee_group) { FactoryGirl.create(:invitee_group, :awaiting_diet, :all_accepted, :all_awaiting_diet) }

            if number.include? '4'
              include_examples 'progress point should be set to', 'awaiting_diet', message: number
            else
              include_examples 'progress point should be set to', 'complete', message: number
            end

            include_examples 'should set diet to', number

            include_examples 'should generate post diet message', number
          end
        end

        context 'when invitee group with two invitees' do
          context 'when awaiting_partial_rsvp' do
            let!(:invitee_group) { FactoryGirl.create(:invitee_group, :awaiting_partial_rsvp, :second_invitee) }

            include_examples 'progress point should be set to', 'rsvp_received', message: number

            include_examples 'part of the invitees accept invitation', number

            include_examples 'should send partial acceptance message', number
          end

          context 'when diet_flow_initialized' do
            context 'and all accepted' do
              let!(:invitee_group) { FactoryGirl.create(:invitee_group, :diet_flow_initialized, :second_invitee, :all_accepted) }

              include_examples 'progress point should be set to', 'awaiting_diet', message: number

              include_examples 'should mark those with diet', number

              include_examples 'should send message with invitees with diet', number
            end

            ('1'..'2').each do |invitee_number|
              context 'and only invitee ' + invitee_number + ' accepted' do
                let!(:invitee_group) { FactoryGirl.create(:invitee_group, :diet_flow_initialized, :second_invitee, :partial_accepted, rsvp_accepted_indexes: [invitee_number.to_i]) }

                include_examples 'progress point should be set to', 'awaiting_diet', message: number

                include_examples 'should mark those with diet', number

                include_examples 'should send message with invitees with diet', number
              end
            end
          end

          context 'when awaiting_diet' do
            context 'when all invitees awaiting diet' do
              let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :awaiting_diet, :all_accepted, :all_awaiting_diet) }

              include_examples 'progress point should be set to', 'awaiting_diet', message: number

              include_examples 'should set diet to', number

              include_examples 'should generate post diet message', number
            end

            ('1'..'2').each do |invitee_number|
              context 'when only invitee ' + invitee_number + ' is awaiting diet' do
                let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :awaiting_diet, :all_accepted, :partial_awaiting_diet, awaiting_diet_indexes: [invitee_number.to_i]) }

                if number.include? '4'
                  include_examples 'progress point should be set to', 'awaiting_diet', message: number
                else
                  include_examples 'progress point should be set to', 'complete', message: number
                end

                include_examples 'should set diet to', number

                include_examples 'should generate post diet message', number
              end
            end
          end
        end

        context 'when invitee group with three invitees' do
          context 'when awaiting_partial_rsvp' do
            let!(:invitee_group) { FactoryGirl.create(:invitee_group, :awaiting_partial_rsvp, :second_invitee, :third_invitee) }

            include_examples 'progress point should be set to', 'rsvp_received', message: number

            include_examples 'part of the invitees accept invitation', number

            include_examples 'should send partial acceptance message', number
          end

          context 'when diet_flow_initialized' do
            context 'and all accepted' do
              let!(:invitee_group) { FactoryGirl.create(:invitee_group, :diet_flow_initialized, :second_invitee, :third_invitee, :all_accepted) }

              include_examples 'progress point should be set to', 'awaiting_diet', message: number

              include_examples 'should mark those with diet', number

              include_examples 'should send message with invitees with diet', number
            end

            ('1'..'3').each do |invitee_number|
              context 'and only invitee ' + invitee_number + ' accepted' do
                let!(:invitee_group) { FactoryGirl.create(:invitee_group, :diet_flow_initialized, :second_invitee, :third_invitee, :partial_accepted, rsvp_accepted_indexes: [invitee_number.to_i]) }

                include_examples 'progress point should be set to', 'awaiting_diet', message: number

                include_examples 'should mark those with diet', number

                include_examples 'should send message with invitees with diet', number
              end
            end

            (('1'..'3').to_a).combination(2).to_a.each do |invitee_numbers|
              context 'and only invitee ' + invitee_numbers.join(' and ') + ' accepted' do
                invitee_numbers = invitee_numbers.map { |i| i.to_i }
                let!(:invitee_group) { FactoryGirl.create(:invitee_group, :diet_flow_initialized, :second_invitee, :third_invitee, :partial_accepted, rsvp_accepted_indexes: invitee_numbers) }

                include_examples 'progress point should be set to', 'awaiting_diet', message: number

                include_examples 'should mark those with diet', number

                include_examples 'should send message with invitees with diet', number
              end
            end

          end

          context 'when awaiting_diet' do
            context 'when all invitees awaiting diet' do
              let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :third_invitee, :awaiting_diet, :all_accepted, :all_awaiting_diet) }

              include_examples 'progress point should be set to', 'awaiting_diet', message: number

              include_examples 'should set diet to', number

              include_examples 'should generate post diet message', number
            end

            ('1'..'3').each do |invitee_number|
              context 'when only invitee ' + invitee_number + ' is awaiting diet' do
                let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :third_invitee, :awaiting_diet, :all_accepted, :partial_awaiting_diet, awaiting_diet_indexes: [invitee_number.to_i]) }

                if number.include? '4'
                  include_examples 'progress point should be set to', 'awaiting_diet', message: number
                else
                  include_examples 'progress point should be set to', 'complete', message: number
                end

                include_examples 'should set diet to', number

                include_examples 'should generate post diet message', number
              end
            end

            (('1'..'3').to_a).combination(2).to_a.each do |invitee_numbers|
              context 'when invitee ' + invitee_numbers.join(' and ') + ' are awaiting diet' do
                invitee_numbers = invitee_numbers.map { |i| i.to_i }
                let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :third_invitee, :awaiting_diet, :all_accepted, :partial_awaiting_diet, awaiting_diet_indexes: invitee_numbers) }

                include_examples 'progress point should be set to', 'awaiting_diet', message: number

                include_examples 'should set diet to', number

                include_examples 'should generate post diet message', number
              end
            end

          end
        end
      end
    end

    numbers_unique_groups_of_3 = numbers.combination(3).to_a
    numbers_unique_groups_of_3.each do |number_group|
      number = number_group.join(', ')
      context 'when message is ' + number do
        let(:message) { number }

        context 'when invitee group with one invitee' do
          context 'when awaiting_diet' do
            let!(:invitee_group) { FactoryGirl.create(:invitee_group, :awaiting_diet, :all_accepted, :all_awaiting_diet) }

            if number.include? '4'
              include_examples 'progress point should be set to', 'awaiting_diet', message: number
            else
              include_examples 'progress point should be set to', 'complete', message: number
            end

            include_examples 'should set diet to', number

            include_examples 'should generate post diet message', number
          end
        end

        context 'when invitee group with two invitees' do
          context 'when awaiting_partial_rsvp' do
            let!(:invitee_group) { FactoryGirl.create(:invitee_group, :awaiting_partial_rsvp, :second_invitee) }

            include_examples 'progress point should be set to', 'rsvp_received', message: number

            include_examples 'part of the invitees accept invitation', number

            include_examples 'should send partial acceptance message', number
          end

          context 'when diet_flow_initialized' do
            context 'and all accepted' do
              let!(:invitee_group) { FactoryGirl.create(:invitee_group, :diet_flow_initialized, :second_invitee, :all_accepted) }

              include_examples 'progress point should be set to', 'awaiting_diet', message: number

              include_examples 'should mark those with diet', number

              include_examples 'should send message with invitees with diet', number
            end

            ('1'..'2').each do |invitee_number|
              context 'and only invitee ' + invitee_number + ' accepted' do
                let!(:invitee_group) { FactoryGirl.create(:invitee_group, :diet_flow_initialized, :second_invitee, :partial_accepted, rsvp_accepted_indexes: [invitee_number.to_i]) }

                include_examples 'progress point should be set to', 'awaiting_diet', message: number

                include_examples 'should mark those with diet', number

                include_examples 'should send message with invitees with diet', number
              end
            end
          end

          context 'when awaiting_diet' do
            context 'when all invitees awaiting diet' do
              let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :awaiting_diet, :all_accepted, :all_awaiting_diet) }

              include_examples 'progress point should be set to', 'awaiting_diet', message: number

              include_examples 'should set diet to', number

              include_examples 'should generate post diet message', number
            end

            ('1'..'2').each do |invitee_number|
              context 'when only invitee ' + invitee_number + ' is awaiting diet' do
                let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :awaiting_diet, :all_accepted, :partial_awaiting_diet, awaiting_diet_indexes: [invitee_number.to_i]) }

                if number.include? '4'
                  include_examples 'progress point should be set to', 'awaiting_diet', message: number
                else
                  include_examples 'progress point should be set to', 'complete', message: number
                end

                include_examples 'should set diet to', number

                include_examples 'should generate post diet message', number
              end
            end
          end
        end

        context 'when invitee group with three invitees' do
          context 'when awaiting_partial_rsvp' do
            let!(:invitee_group) { FactoryGirl.create(:invitee_group, :awaiting_partial_rsvp, :second_invitee, :third_invitee) }

            include_examples 'progress point should be set to', 'rsvp_received', message: number

            include_examples 'part of the invitees accept invitation', number

            include_examples 'should send partial acceptance message', number
          end

          context 'when diet_flow_initialized' do
            context 'and all accepted' do
              let!(:invitee_group) { FactoryGirl.create(:invitee_group, :diet_flow_initialized, :second_invitee, :third_invitee, :all_accepted) }

              include_examples 'progress point should be set to', 'awaiting_diet', message: number

              include_examples 'should mark those with diet', number

              include_examples 'should send message with invitees with diet', number
            end

            ('1'..'3').each do |invitee_number|
              context 'and only invitee ' + invitee_number + ' accepted' do
                let!(:invitee_group) { FactoryGirl.create(:invitee_group, :diet_flow_initialized, :second_invitee, :third_invitee, :partial_accepted, rsvp_accepted_indexes: [invitee_number.to_i]) }

                include_examples 'progress point should be set to', 'awaiting_diet', message: number

                include_examples 'should mark those with diet', number

                include_examples 'should send message with invitees with diet', number
              end
            end

            (('1'..'3').to_a).combination(2).to_a.each do |invitee_numbers|
              context 'and only invitee ' + invitee_numbers.join(' and ') + ' accepted' do
                invitee_numbers = invitee_numbers.map { |i| i.to_i }
                let!(:invitee_group) { FactoryGirl.create(:invitee_group, :diet_flow_initialized, :second_invitee, :third_invitee, :partial_accepted, rsvp_accepted_indexes: invitee_numbers) }

                include_examples 'progress point should be set to', 'awaiting_diet', message: number

                include_examples 'should mark those with diet', number

                include_examples 'should send message with invitees with diet', number
              end
            end

          end

          context 'when awaiting_diet' do
            context 'when all invitees awaiting diet' do
              let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :third_invitee, :awaiting_diet, :all_accepted, :all_awaiting_diet) }

              include_examples 'progress point should be set to', 'awaiting_diet', message: number

              include_examples 'should set diet to', number

              include_examples 'should generate post diet message', number
            end

            ('1'..'3').each do |invitee_number|
              context 'when only invitee ' + invitee_number + ' is awaiting diet' do
                let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :third_invitee, :awaiting_diet, :all_accepted, :partial_awaiting_diet, awaiting_diet_indexes: [invitee_number.to_i]) }

                if number.include? '4'
                  include_examples 'progress point should be set to', 'awaiting_diet', message: number
                else
                  include_examples 'progress point should be set to', 'complete', message: number
                end

                include_examples 'should set diet to', number

                include_examples 'should generate post diet message', number
              end
            end

            (('1'..'3').to_a).combination(2).to_a.each do |invitee_numbers|
              context 'when invitee ' + invitee_numbers.join(' and ') + ' are awaiting diet' do
                invitee_numbers = invitee_numbers.map { |i| i.to_i }
                let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :third_invitee, :awaiting_diet, :all_accepted, :partial_awaiting_diet, awaiting_diet_indexes: invitee_numbers) }

                include_examples 'progress point should be set to', 'awaiting_diet', message: number

                include_examples 'should set diet to', number

                include_examples 'should generate post diet message', number
              end
            end

          end
        end
      end
    end

    context 'when message is garbage' do
      let(:message) { 'garbage' }
      context 'when invitee group with one invitee' do
        context 'when invitation_sent' do
          let!(:invitee_group) { FactoryGirl.create(:invitee_group, :invitation_sent) }

          include_examples 'progress should not be made', 'invitation_sent'

          include_examples 'should send generic error message'
        end

        context 'when rsvp_received' do
          let!(:invitee_group) { FactoryGirl.create(:invitee_group, :rsvp_received, :all_accepted) }

          include_examples 'progress should not be made', 'rsvp_received'

          include_examples 'should send generic error message'
        end
      end

      context 'when invitee group with two invitees' do
        context 'when invitation_sent' do
          let!(:invitee_group) { FactoryGirl.create(:invitee_group, :invitation_sent, :second_invitee) }

          include_examples 'progress should not be made', 'invitation_sent'

          include_examples 'should send generic error message'
        end

        context 'when rsvp_received' do
          let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :rsvp_received, :all_accepted) }

          include_examples 'progress should not be made', 'rsvp_received'

          include_examples 'should send generic error message'
        end
      end

      context 'when invitee group with three invitees' do
        context 'when invitation_sent' do
          let!(:invitee_group) { FactoryGirl.create(:invitee_group, :invitation_sent, :second_invitee, :third_invitee) }
          include_examples 'progress should not be made', 'invitation_sent'

          include_examples 'should send generic error message'
        end

        context 'when rsvp_received' do
          let!(:invitee_group) { FactoryGirl.create(:invitee_group, :second_invitee, :third_invitee, :rsvp_received, :all_accepted)
          }
          include_examples 'progress should not be made', 'rsvp_received'

          include_examples 'should send generic error message'
        end
      end
    end
  end
end