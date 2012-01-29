# encoding: utf-8

module Glyph

	# The Glyph::Document class stores information about a document or a chunk of text
	# currently being interpreted.
	#
	# It is responsible of analyzing (evaluating) the syntax tree and return the corresponding output
	# as well as replacing placeholders.
	class Document

		ESCAPES = [
			['\\]', ']'],
			['\\[', '['],
			['\\=', '='],
			['\\.', ''],
			['\\\\', '\\'],
			['\\|', '|']
		]

		attr_reader :bookmarks, :placeholders, :headers, :context, :errors, :todos

		# Creates a new document
		# @param [GlyphSyntaxNode] tree the syntax tree to be evaluate
		# @param [Glyph::Node] context the context associated with the tree
		# @raise [RuntimeError] unless tree responds to :evaluate
		def initialize(tree, context)
			@tree = tree
			@context = context
			@bookmarks = {}
			@placeholders = {}
			@headers = []
			@errors = []
			@todos = []
			@state = :new
		end


		# Returns a tree of Glyph::Node objects corresponding to the analyzed document
		# @raise [RuntimeError] unless the document has been analized
		def structure
			raise RuntimeError, "Document has not been analyzed" unless analyzed? || finalized?
			@tree
		end

		# Copies bookmarks, headers, todos and placeholders from another Glyph::Document
		# @param [Glyph::Document] document a valid Glyph::Document
		def inherit_from(document)
			@bookmarks = document.bookmarks
			@headers = document.headers
			@todos = document.todos
			@placeholders = document.placeholders
		end

		# Defines a placeholder block that will be evaluated after the whole document has been analyzed
		# @param [Proc] &block a block taking the document itself as parameter
		# @return [String] the placeholder key string
		def placeholder(&block)
			key = "‡‡‡‡‡PLACEHOLDER¤#{@placeholders.length+1}‡‡‡‡‡".to_sym
			@placeholders[key] = block
			key
		end

		# Returns a stored bookmark or nil
		# @param [#to_sym] key the bookmark identifier
		# @return [Hash, nil] the bookmark hash or nil if no bookmark is found
		def bookmark?(key)
			@bookmarks[key.to_sym]
		end

		# Stores a new bookmark
		# @param [Hash] hash the bookmark hash: {:id => "Bookmark ID", :title => "Bookmark Title"}
		# @return [Hash] the stored bookmark (:id is converted to a symbol)
		def bookmark(hash)
			ident = hash[:id].to_sym
			hash[:id] = ident
			@bookmarks[ident] = hash
			hash
		end

		# Stores a new header
		# @param [Hash] hash the header hash: {:id => "Bookmark ID", :title => "Bookmark Title", :level => 3}
		# @return [Hash] the stored header
		def header(hash)
			@headers << hash
			hash
		end

		# Returns a stored header or nil
		# @param [String] key the header identifier
		# @return [Hash, nil] the header hash or nil if no header is found
		def header?(key)
			@headers.select{|h| h[:id] == key}[0] rescue nil
		end

		# Analyzes the document by evaluating its @tree
		# @return [:analyzed]
		# @raise [RuntimeError] if the document is already analyzed or finalized
		def analyze
			raise RuntimeError, "Document is #{@state}" if analyzed? || finalized?
			@context[:document] = self
			@output = @tree.evaluate @context
			@state = :analyzed
		end

		# Finalizes the document by evaluating its @placeholders
		# @return [:finalized]
		# @raise [RuntimeError] if the document the document has not been analyzed,
		# 	if it is already finalized or if errors occurred during analysis
		def finalize
			raise RuntimeError, "Document has not been analyzed" unless analyzed?
			raise RuntimeError, "Document has already been finalized" if finalized?
			return (@state = :finalized) if @context[:embedded]
			raise RuntimeError, "Document cannot be finalized due to previous errors" unless @context[:document].errors.blank?
			# Substitute placeholders
			ESCAPES.each{|e| @output.gsub! e[0], e[1]}
			begin
				@placeholders.each_pair do |key, value|
					begin
						@output.gsub! key.to_s, value.call(self).to_s
					rescue Glyph::MacroError => e
						e.macro.macro_warning e.message, e
					rescue Exception => e
						puts e.class
						Glyph.warning e.message
					end
				end
			rescue Exception => e
			end
			@state = :finalized
		end

		# Returns the document output
		# @raise [RuntimeError] unless the document is finalized.
		def output
			raise RuntimeError, "Document is not finalized" unless finalized?
			@output
		end

		# @return [Boolean] Returns true if the document is new, false otherwise
		def new?
			@state == :new
		end

		# @return [Boolean] Returns true if the document is analyzed, false otherwise
		def analyzed?
			@state == :analyzed
		end

		# @return [Boolean] Returns true if the document is analyzed, false otherwise
		def finalized?
			@state == :finalized
		end

	end

end
