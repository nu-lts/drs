require "spec_helper"

describe EmployeeMailer do
  before(:all) { @employee = FactoryGirl.create(:employee) }
  describe "New employee alerts" do
    it "sends the emails to wjackson in the test environment" do
      msg = EmployeeMailer.new_employee_alert(@employee).deliver
      expect(msg.to).to match_array ["wjackson64@gmail.com"]
      expect(ActionMailer::Base.deliveries.length).to eq 1
    end

    it "sends the email even if employee is malformed" do
      e = Employee.new
      msg = EmployeeMailer.new_employee_alert(e).deliver
      expect(ActionMailer::Base.deliveries.length).to eq 1
    end
  end
  after(:all) { @employee.destroy }
end