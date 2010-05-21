# encoding: utf-8

module Glyph

	# A Macro object is instantiated by a Glyph::Interpreter whenever a macro is found in the parsed text.
	# The Macro class contains shortcut methods to access the current node and document, as well as other
	# useful methods to be used in macro definitions.
	class Macro

		include Validators

		# Creates a new macro instance from a Node
		# @param [Node] node a node populated with macro data
		def initialize(node)
			@node = node
			@name = @node[:name]
			@source = @node[:source]
		end

		def attributes
			return @attributes if @attributes
			@attributes = {}
			@node[:attributes].each_pair do |key, value|
				@attributes[key] = value.evaluate
			end
			@attributes
		end

		def segments
			return @segments if @segments
			@segments = []
			@node[:segments].each do |value|
				@segments << value.evaluate
			end
			@segments
		end

		def value
			@node[:value]
		end

		# Returns the "path" to the macro within the syntax tree.
		# @return [String] the macro path
		def path
			macros = []
			@node.ascend {|n| macros << n[:name].to_s }
			macros.reverse.join('/')
		end
		
		# Returns a todo message to include in the document in case of errors.
		# @param [String] message the message to include in the document
		# @return [String] the resulting todo message
		# @since 0.2.0
		def macro_todo(message)
			draft = Glyph['document.draft']
			Glyph['document.draft'] = true unless draft
			res = interpret "![#{message}]"
			Glyph['document.draft'] = false unless draft
			res
		end

		# Raises a macro error (preventing document post-processing)
		# @param [String] msg the message to print
		# @raise [Glyph::MacroError]
		def macro_error(msg, klass=Glyph::MacroError)
			src = @node[:source_name]
			src ||= @node[:source]
			src ||= "--"
			message = "#{msg}\n -> source: #{src}\n -> path: #{path}"
			@node[:document].errors << message
			message += "\n -> value:\n#{"-"*54}\n#{raw_value}\n#{"-"*54}" if Glyph.debug?
			raise klass, message
		end

		# Prints a macro earning
		# @param [String] msg the message to print
		# @param [Exception] e the exception raised
		# @since 0.2.0
		def macro_warning(msg, e=nil)
			src = @node[:source_name]
			src ||= @node[:source]
			src ||= "--"
			message = "#{msg}\n -> source: #{src}\n -> path: #{path}"
			if Glyph.debug? then
				message << %{\n -> value:\n#{"-"*54}\n#{raw_value}\n#{"-"*54}} 
				if e then
					message << "\n"+"-"*20+"[ Backtrace: ]"+"-"*20
					message << "\n"+e.backtrace.join("\n")
					message << "\n"+"-"*54
				end
			end
			Glyph.warning message
		end

		# Instantiates a Glyph::Interpreter and interprets a string
		# @param [String] string the string to interpret
		# @return [String] the interpreted output
		# @raise [Glyph::MacroError] in case of mutual macro inclusion (snippet, include macros)
		def interpret(string)
			@node[:source] = "#@name[#{raw_value}]"
			@node[:source_name] = (raw_value.length > 50 || raw_value.match(/\n/)) ? "#{@name}[...]" : @node[:source]
			macro_error "Mutual inclusion", Glyph::MutualInclusionError if @node.find_parent {|n| n[:source] == @node[:source] }
			if @node[:escape] then
				result = string 
			else
				@node[:embedded] = true
			 	result = Glyph::Interpreter.new(string, @node).document.output
			end
			result.gsub(/\\*([\[\]])/){"\\#$1"}
		end

		# Encodes all macros in a string so that it can be encoded
		# (and interpreted) later on
		# @param [String] string the string to encode
		# @return [String] the encoded string
		# @since 0.2.0
		def encode(string)
			string.gsub(/([\[\]\|])/) { "‡‡¤#{$1.bytes.to_a[0]}¤‡‡" }
		end

		# Decodes a previously encoded string 
		# so that it can be interpreted
		# @param [String] string the string to decode
		# @return [String] the decoded string
		# @since 0.2.0
		def decode(string)
			string.gsub(/‡‡¤(91|93|124)¤‡‡/) { $1.to_i.chr }
		end

		# @see Glyph::Document#placeholder
		def placeholder(&block)
			@node[:document].placeholder &block
		end			

		# @see Glyph::Document#bookmark
		def bookmark(hash)
			@node[:document].bookmark hash
		end

		# @see Glyph::Document#bookmark?
		def bookmark?(ident)
			@node[:document].bookmark? ident
		end

		# @see Glyph::Document#header?
		def header?(ident)
			@node[:document].header? ident
		end

		# @see Glyph::Document#header
		def header(hash)
			@node[:document].header hash
		end

		# Executes a macro definition in the context of self
		def expand
			block = Glyph::MACROS[@name]
			macro_error "Undefined macro '#@name'}" unless block
			res = instance_exec(@node, &block).to_s
			res.gsub!(/\\*([\[\]\|])/){"\\#$1"} 
			res
		end

		protected

	end

end
