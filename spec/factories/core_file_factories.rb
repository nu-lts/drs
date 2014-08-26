FactoryGirl.define do
  factory :core_file, class: CoreFile do
    sequence(:title) { |n| "Core File #{n}" }

    trait :deposited_by_bill do
      depositor "000000001"
    end

    trait :incomplete do
      before(:create) do |file|
        file.tag_as_in_progress
      end
    end

    trait :complete do
      before(:create) do |file|
        file.tag_as_completed
      end
    end

    factory :significant_content do
      mass_permissions 'public'
      deposited_by_bill

      factory :theses do
       category 'Theses and Dissertations'
      end

      factory :research do
       category 'Research Publications'
      end

      factory :presentation do
        category 'Presentations'
      end

      factory :dataset do
        category 'Datasets'
      end

      factory :learning_object do
        category 'Learning Objects'
      end
    end

    factory :complete_file do
      ignore do
        depositor false
        parent false
      end

      after(:build) do |u, evaluator|
        u.depositor = evaluator.depositor if evaluator.depositor
        u.parent = evaluator.parent if evaluator.parent
      end
    end

    factory :bills_complete_file do
      deposited_by_bill
      complete
    end

    factory :bills_incomplete_file do
      deposited_by_bill
      incomplete
    end
  end
end