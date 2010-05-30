#!/usr/bin/env ruby

macro :note do
	%{<div class="#{@name}">
<span class="note-title">#{@name.to_s.capitalize}</span>#{value}

</div>}
end

macro :box do
	exact_parameters 2
	%{<div class="box">
<div class="box-title">#{param(0)}</div>
#{param(1)}

</div>}
end

macro :codeblock do
	exact_parameters 1 
	%{
<div class="code">
<pre>
<code>
#{value}
</code>
</pre>
</div>}
end

macro :title do
	no_parameters
	%{<h1>
			#{Glyph["document.title"]}
</h1>}
end

macro :img do
	min_parameters 1
	max_parameters 3
	image = param(0)
	width = param(1) rescue nil
	source_file = Glyph.lite? ? image : Glyph::PROJECT/"images/#{image}"
	dest_file = Glyph.lite? ? image : "images/#{image}"
 	w = (width) ? "width=\"#{width}\"" : ''
	height = param(2) rescue nil
 	h = (height) ? "height=\"#{height}\"" : ''
	Glyph.warning "Image '#{image}' not found" unless Pathname.new(dest_file).exist? 
	%{<img src="#{dest_file}" #{w} #{h} alt="-"/>}
end

macro :fig do
	min_parameters 1
	max_parameters 2
	image = param(0)
	caption = param(1) rescue nil
	caption = %{<div class="caption">#{caption}</div>} if caption
	source_file = Glyph.lite? ? image : Glyph::PROJECT/"images/#{image}"
	dest_file = Glyph.lite? ? image : "images/#{image}"
	Glyph.warning "Figure '#{image}' not found" unless Pathname.new(dest_file).exist? 
	%{<div class="figure">
<img src="#{dest_file}" alt="-"/>
#{caption}
</div>}
end


macro :subtitle do
	no_parameters
	%{<h2>
#{Glyph["document.subtitle"]}
</h2>}
end

macro :author do
	no_parameters
	%{<div class="author">
by <em>#{Glyph["document.author"]}</em>
</div>}
end

macro :pubdate do
	no_parameters
	%{<div class="pubdate">
#{Time.now.strftime("%B %Y")}
</div>}
end

macro_alias :important => :note
macro_alias :tip => :note
macro_alias :caution => :note
