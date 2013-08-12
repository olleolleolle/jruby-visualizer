require 'jruby-visualizer/compiler_data'

module CompilerDataTestUtils
  @updated_ruby_code = false
  @updated_ast_root = false
  @updated_ir_scope = false
  
  def add_ruby_code_listener
    @compiler_data.ruby_code_property.add_change_listener do |new_code|
      @updated_ruby_code = true
    end    
  end
  
  def add_ast_root_listener
    @compiler_data.ast_root_property.add_change_listener do |new_ast|
      @updated_ast_root = true
    end
  end
  
  def add_ir_scope_listener
    @compiler_data.ir_scope_property.add_change_listener do |new_ir_scope|
      @updated_ir_scope = true
    end    
  end
  
  def add_listeners
    add_ruby_code_listener
    add_ast_root_listener
    add_ir_scope_listener
  end
  
  def clear_updates
    @updated_ruby_code, @updated_ast_root, @updated_ir_scope = false, false, false
  end
  
  def should_has_ast(other_ast)
    @compiler_data.ast_root.to_s == other_ast.to_s
  end
  
  def should_has_ir_scope(other_ir_scope)
    @compiler_data.ir_scope.to_s == other_ir_scope.to_s
  end
  
  def self.ast_for(ruby_code)
    JRuby::parse(ruby_code)
  end
  
  def self.ir_scope_for(ast_root)
    ir_manager = JRuby::runtime.ir_manager
    ir_manager.dry_run = true

    builder = 
      if JRuby::runtime.is1_9?
        org.jruby.ir.IRBuilder19
      else
        org.jruby.ir.IRBuilder
      end
    builder = builder.new(ir_manager)
    builder.build_root(ast_root)
  end
  
end

describe CompilerData do
  include CompilerDataTestUtils 
  
  before(:each) do
    @compiler_data = CompilerData.new
  end

  it "should update AST and IR Scope after updating ruby code" do
    add_listeners
    
    @compiler_data.ruby_code = "i = 1 + 2; puts i"
    @updated_ruby_code.should be_true
    @updated_ast_root.should be_true
    @updated_ir_scope.should be_true
  end
  
  it "should only update IR Scope after assigning a new AST" do
    add_listeners
    
    @compiler_data.ast_root = CompilerDataTestUtils.ast_for("j = 2; j") 
    @updated_ruby_code.should be_false
    @updated_ast_root.should be_true
    @updated_ir_scope.should be_true
  end
  
  it "should parse the AST implicitly" do
    ruby_code = "a = 1; b = 4; puts a + b"
    @compiler_data.ruby_code = ruby_code
    should_has_ast(CompilerDataTestUtils.ast_for(ruby_code))
  end
  
  it "should build the IR implicitly" do
    ast_root = CompilerDataTestUtils.ast_for("i = 42; puts i")
    @compiler_data.ast_root = ast_root
    should_has_ir_scope(CompilerDataTestUtils.ir_scope_for(ast_root))
  end
  
end

