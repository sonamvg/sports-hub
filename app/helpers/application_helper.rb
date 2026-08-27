module ApplicationHelper
  def image_with_placeholder(source, alt:, placeholder:, **options)
    if source.present?
      image_options = {
        alt: alt,
        loading: options.delete(:loading) || "lazy",
        class: ["fallback-image", options.delete(:class)].compact.join(" "),
        onerror: "this.classList.add('is-hidden');this.nextElementSibling.hidden=false;"
      }.merge(options)

      tag.div(class: "image-fallback") do
        image_tag(source, image_options) +
          tag.div(placeholder, class: "fallback-placeholder", hidden: true)
      end
    else
      tag.div(placeholder, class: "fallback-placeholder")
    end
  end
end
