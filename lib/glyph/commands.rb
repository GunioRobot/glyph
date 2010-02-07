#!/usr/bin/env ruby

include GLI


GLI.desc "Enable debugging"
switch [:d, :debug]

GLI.desc 'Create a new Glyph project'
command :init do |c|
	c.action do |global_options,options,args|
		Glyph.run 'project:create', Dir.pwd
	end
end

GLI.desc 'Add a new text file to project'
arg_name "file_name"
command :add do |c|
	c.action do |global_options,options,args|
		Glyph.run 'project:add', args[0]
	end
end

GLI.desc 'Compile the project'
arg_name "[output_target]"
command :compile do |c|
	c.desc "Specify a glyph file to compile (default: document.glyph)"
	c.flag [:f, :file]
	c.action do |global_options, options, args|
		output_targets = Glyph::CONFIG.get('document.output_targets')
		target = nil
		case args.length
		when 0 then
			target = cfg('document.output')
			target = nil if target.blank?
			target ||= cfg('filters.target')
		when 1 then
			target = args[0]
		else
			raise RuntimeError, "Too many arguments."
		end	
		Glyph.config_override 'document.source', options[:f] if options[:f]
		raise RuntimeError, "Output target not specified" unless target
		raise RuntimeError, "Unknown output target '#{target}'" unless output_targets.include? target.to_sym
		Glyph.run "generate:#{target}"
		info "'#{cfg('document.filename')}.#{target}' generated successfully."
		unless Glyph::TODOS.blank?
			info "*** TODOs: ***"
			Glyph::TODOS.each do |t|
				info t
			end
		end
	end
end

GLI.desc 'Get/set configuration settings'
arg_name "setting [new_value]"
command :config do |c|
	Glyph.run 'load:config'
	c.desc "Save to global configuration"
	c.switch [:g, :global]
	c.action do |global_options,options,args|
		if options[:g] then
			cfg = Glyph::GLOBAL_CONFIG
		else
			cfg = Glyph::PROJECT_CONFIG
		end
		case args.length
		when 0 then
			raise RuntimeError, "Too few arguments."
		when 1 then # read current config
			setting = cfg(args[0])
			raise RuntimeError, "Unknown setting '#{args[0]}'" if setting.blank?
			info Glyph::CONFIG.get(args[0])
		when 2 then
			cfg.set args[0], args[1]
			Glyph.reset_config
		else
			raise RuntimeError, "Too many arguments."
		end
	end
end

pre do |global,command,options,args|
	# Pre logic here
	# Return true to proceed; false to abourt and not call the
	# chosen command
	if global[:d] then
		Glyph::DEBUG = true
	end
	if !command || command.name == :help then
		puts "====================================="
		puts "Glyph v#{Glyph::VERSION}"
		puts "====================================="
	end
	true
end

post do |global,command,options,args|
	# Post logic here
end

on_error do |exception|
	if Glyph.const_defined? :DEBUG then
		puts "error: #{exception.message}"
		puts "backtrace:"
		exception.backtrace.each do |b|
			puts b
		end
	end
	# Error logic here
	# return false to skip default error handling
	true
end
