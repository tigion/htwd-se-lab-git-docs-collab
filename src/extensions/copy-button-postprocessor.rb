require 'asciidoctor'
require 'asciidoctor/extensions'

class CopyButtonPostprocessor < Asciidoctor::Extensions::Postprocessor
  # The HTML for the copy button.
  # The CSS styling for the button is defined in the css/styles.css file.
  COPY_BUTTON = <<~HTML
    <button
      title="Copy"
      class="copy-btn"
      onclick="navigator.clipboard.writeText(this.nextElementSibling.textContent)"
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        width="16"
        height="16"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="1"
        stroke-linecap="round"
        stroke-linejoin="round"
      >
        <rect x="8" y="8" width="13" height="13" rx="2"/>
        <path d="M16 8V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h3"/>
      </svg>
    </button>
  HTML

  def process(document, output)
    return output unless document.basebackend? 'html'

    # Wraps pre blocks with a div and add the copy button.
    # <pre>...</pre> -> <div><button>Copy</button><pre>...</pre></div>
    output.gsub(/<pre\b[^>]*>.*?<\/pre>/m) do |match|
      %(<div class="code-wrapper">#{COPY_BUTTON}#{match}</div>)
    end
  end
end

Asciidoctor::Extensions.register do
  postprocessor CopyButtonPostprocessor
end
