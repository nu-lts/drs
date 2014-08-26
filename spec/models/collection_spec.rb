require 'spec_helper'

describe Collection do

  let(:collection) { Collection.new }

  describe "Custom setters and getters" do
    let(:c) { Collection.new }

    it "Sets custom permissions correctly" do
      permissions = {'permissions0' => {'identity_type' => 'person', 'identity' => 'Will', 'permission_type' => 'edit'},
                      'permissions1' => {'identity_type' => 'group', 'identity' => 'NU:All', 'permission_type' => 'read'},
                      'permissions2' => {'identity_type' => 'person', 'identity' => 'Tadd', 'permission_type' => 'read'} }
      c.permissions = permissions
      c.permissions.should =~ [{ type: 'user', access: 'edit', name: 'Will' },
                               { type: 'group', access: 'read', name: 'NU:All' },
                               { type: 'user', access: 'read', name: 'Tadd'}]
    end

    it "Doesn't allow permissions set of public or registered groups" do
      permissions = {'permissions0' => {'identity_type' => 'group', 'identity' => 'public', 'permission_type' => 'read'},
                      'permissions1' => {'identity_type' => 'group', 'identity' => 'registered', 'permission_type' => 'read'},
                      'permissions2' => {'identity_type' => 'group', 'identity' => 'public', 'permission_type' => 'edit'},
                      'permissions3' => {'identity_type' => 'group', 'identity' => 'registered', 'permission_type' => 'edit'} }
      c.permissions = permissions
      c.permissions.should == []
    end
  end

  describe "Behavior of Parent setter" do
    let(:p_coll) { Collection.new }
    let(:root) { Collection.new }

    before do
      root.save!
      @saved_root = Collection.find(root.pid)
    end

    it "Sets the parent collection, but receives nil" do
      p_coll.parent = @saved_root.pid
      p_coll.parent.should == @saved_root
    end
  end

  describe "User parent" do
    before do
      Employee.destroy_all
    end

    let(:employee) { FactoryGirl.create(:employee) }

    it "can be set via nuid" do
      collection.user_parent = employee.nuid
      collection.user_parent.pid.should == employee.pid
    end

    it "CANNOT be set by pid" do
      expect{collection.user_parent = employee.pid}.to raise_error
    end

    it "can be set by passing the entire object" do
      collection.user_parent = employee
      collection.user_parent.pid.should == employee.pid
    end
  end


  describe "Recursive delete" do
    before(:each) do
      ActiveFedora::Base.find(:all).each do |file|
        file.destroy
      end

      @root = Collection.create(title: "Root")
      @child_one = Collection.create(title: "Child One", parent: @root)
      @c1_gf = CoreFile.create(title: "Core File One", parent: @child_one, depositor: "nobody@nobody.com")
      @c2_gf = CoreFile.create(title: "Core File Two", parent: @child_one, depositor: "nobody@nobody.com")
      @child_two = Collection.create(title: "Child Two", parent: @root)
      @grandchild = Collection.create(title: "Grandchild", parent: @child_two)
      @great_grandchild = Collection.create(title: "Great Grandchild", parent: @grandchild)
      @gg_gf = CoreFile.create(title: "GG CF", parent: @great_grandchild, depositor: "nobody@nobody.com")
      @pids = [ @root.pid, @child_one.pid, @c1_gf.pid, @c2_gf.pid, @child_two.pid, @grandchild.pid, @great_grandchild.pid,
                @gg_gf.pid]
    end

    it "deletes the item its called on and all descendent files and collections." do
      @root.recursive_delete
      Collection.find(:all).length.should == 0
      CoreFile.find(:all).length.should   == 0
    end
  end

  after :all do
    Collection.find(:all).each do |coll|
      coll.destroy
    end
  end
end