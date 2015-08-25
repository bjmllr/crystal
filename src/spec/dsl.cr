# Methods to define and organize specs. See `Spec` for a complete example.
module Spec::DSL
  # Define a context. Typically used to define a context containing the specs
  # for a particular unit, such as a class, module, or method. `description`
  # will become part of the description for each test case in the context. The
  # passed block can define additional contexts with the methods of this
  # module, but methods of `Spec::Expectations` should only be called in a
  # test case.
  #
  # ```
  # describe "Array" do
  #   describe "#length" do
  #     it "correctly reports the number of elements in the Array" do
  #       # expectations go here
  #     end
  #   end
  # end
  # ```
  def describe(description, file = __FILE__, line = __LINE__)
    Spec::RootContext.describe(description.to_s, file, line) do |context|
      yield
    end
  end

  # Define a context. Typically used to define a context containing the specs
  # for a particular circumstance, such as input data or collaborator state.
  # `description` will become part of the description for each test case in
  # the context. The passed block can define additional contexts with the
  # methods of this module, but methods of `Spec::Expectations` should only
  # be called in a test case.
  #
  # ```
  # describe "Array" do
  #   describe "#length" do
  #     context "with 3 elements in the Array" do
  #       it "returns 3" do
  #         # expectations go here
  #       end
  #     end
  #
  #     context "with 1024 elements in the Array" do
  #       it "returns 1024" do
  #         # expectations go here
  #       end
  #     end
  #   end
  # end
  # ```
  def context(description, file = __FILE__, line = __LINE__)
    describe(description.to_s, file, line) { |ctx| yield ctx }
  end

  # Define a test case. The passed block should not define additional contexts
  # using the method of this module, but methods of `Spec::Expectations` can
  # be called.
  #
  # ```
  # describe "Array" do
  #   describe "#empty?" do
  #     it "is empty when no elements are in the array" do
  #       ([] of Int32).empty?.should be_true
  #     end
  #
  #     it "is not empty if there are elements in the array" do
  #       [1].empty?.should be_false
  #     end
  #   end
  # end
  # ```
  def it(description, file = __FILE__, line = __LINE__)
    return if Spec.aborted?
    return unless Spec.matches?(description, file, line)

    Spec.formatter.before_example description

    begin
      Spec.run_before_each_hooks
      yield
      Spec::RootContext.report(:success, description, file, line)
    rescue ex : Spec::AssertionFailed
      Spec::RootContext.report(:fail, description, file, line, ex)
      Spec.abort! if Spec.fail_fast?
    rescue ex
      Spec::RootContext.report(:error, description, file, line, ex)
      Spec.abort! if Spec.fail_fast?
    ensure
      Spec.run_after_each_hooks
    end
  end

  # Define a context that skips all contained specs. Typically used to
  # identify specs that don't currently pass, but are supposed to pass
  # eventually. `description` will replace the descriptions of any test cases
  # inside the context, so the entire group will appear as a single pending
  # entry in the report. `block` must be syntactically valid, but can contain
  # some code that would be rejected by the compiler during type analysis.
  #
  # ```
  # describe "Array" do
  #   pending "#my_new_method is not implemented yet" do
  #     describe "#my_new_method" do
  #       it "does something that hasn't yet been implemented" do
  #         # expectations go here
  #       end
  #     end
  #   end
  # end
  # ```
  def pending(description, file = __FILE__, line = __LINE__, &block)
    return if Spec.aborted?
    return unless Spec.matches?(description, file, line)

    Spec.formatter.before_example description

    Spec::RootContext.report(:pending, description, file, line)
  end

  # Define a test case. Typically used when a test case only contains one
  # expectation. Longer specs typically use `it` so that a description can be
  # given. The passed block should not define additional contexts using the
  # method of this module, but methods of `Spec::Expectations` can be called.
  #
  # ```
  # describe "Int" do
  #   describe "**" do
  #     assert { (2 ** 2).should eq(4) }
  #     assert { (2 ** 2.5_f32).should eq(5.656854249492381) }
  #     assert { (2 ** 2.5).should eq(5.656854249492381) }
  #   end
  # end
  # ```
  def assert(file = __FILE__, line = __LINE__)
    it("assert", file, line) { yield }
  end

  # Raise a `Spec::AssertionFailed` exception with `msg`. Typically used when
  # the failure message would be too cryptic with existing matchers, but the
  # creation of a new matcher is not justified. For use inside a test case.
  #
  # ```
  # describe "Int" do
  #   describe "step" do
  #     it "steps through limit" do
  #       passed = false
  #       1.step(1) { |x| passed = true }
  #       fail "expected step to pass through 1" unless passed
  #     end
  #   end
  # end
  # ```
  def fail(msg, file = __FILE__, line = __LINE__)
    raise Spec::AssertionFailed.new(msg, file, line)
  end
end

include Spec::DSL
