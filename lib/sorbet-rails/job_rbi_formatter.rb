# typed: strict
require('parlour')
require('sorbet-rails/sorbet_utils.rb')

class SorbetRails::JobRbiFormatter
  extend T::Sig

  Parameter = ::Parlour::RbiGenerator::Parameter

  sig { params(job_class: T.class_of(ActiveJob::Base)).void }
  def initialize(job_class)
    @job_class = T.let(job_class, T.class_of(ActiveJob::Base))
    @parlour = T.let(Parlour::RbiGenerator.new, Parlour::RbiGenerator)
  end

  sig {returns(String)}
  def generate_rbi
    puts "-- Generate sigs for mailer #{@job_class.name} --"

    @parlour.root.add_comments([
      'This is an autogenerated file for Rails\' jobs.',
      'Please rerun bundle exec rake rails_rbi:jobs to regenerate.'
    ])

    @parlour.root.create_class(@job_class.name) do |job_rbi|
      method_def = @job_class.instance_method(:perform)
      parameters = SorbetRails::SorbetUtils.parameters_from_method_def(method_def)
      job_rbi.create_method(
        "perform_later",
        parameters: parameters,
        class_method: true,
      )
      job_rbi.create_method(
        "perform_now",
        parameters: parameters,
        class_method: true,
      )
      # Override the signature for "set" so that we can support it
      # At run-time, this method returns a `ActiveJob::ConfiguredJob` but
      # we fake the signature to return "T.self_class" so that
      # sorbet can type-check when `perform_later` is called on it
      # See: https://guides.rubyonrails.org/active_job_basics.html#enqueue-the-job
      job_rbi.create_method(
        "set",
        # Documentation: https://api.rubyonrails.org/classes/ActiveJob/Core/ClassMethods.html
        parameters: [
          Parameter.new(
            "wait:",
            type: "T.nilable(ActiveSupport::Duration)",
            default: "nil",
          ),
          Parameter.new(
            "wait_until:",
            type: "T.nilable(T.any(ActiveSupport::TimeWithZone, Date, Time))",
            default: "nil",
          ),
          Parameter.new(
            "queue:",
            type: "T.nilable(T.any(String, Symbol))",
            default: "nil",
          ),
          Parameter.new(
            "priority:",
            type: "T.nilable(Integer)",
            default: "nil",
          ),
        ],
        return_type: "T.self_type",
        class_method: true,
      )
    end

    @parlour.rbi
  end
end