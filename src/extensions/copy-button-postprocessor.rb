require 'asciidoctor'
require 'asciidoctor/extensions'

class CopyButtonPostprocessor < Asciidoctor::Extensions::Postprocessor
  def process(document, output)
    return output unless document.basebackend? 'html'

    output = output.gsub(/(<pre\b[^>]*>)/) do |match|
      %(<div class="code-wrapper"><button title="Copy" class="copy-btn" onclick="navigator.clipboard.writeText(this.nextElementSibling.textContent)"><svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1" stroke-linecap="round" stroke-linejoin="round"><rect x="8" y="8" width="13" height="13" rx="2"/><path d="M16 8V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h3"/></svg></button>#{match})
    end

    output.gsub('</pre>', '</pre></div>')
  end
end

Asciidoctor::Extensions.register do
  postprocessor CopyButtonPostprocessor
end
