module ApplicationHelper
  ICON_PATHS = {
    "academy" => '<path d="M4 10.5 12 6l8 4.5"/><path d="M6 11v7h12v-7"/><path d="M10 18v-4h4v4"/>',
    "arrow-right" => '<path d="M5 12h14"/><path d="m13 6 6 6-6 6"/>',
    "calendar" => '<path d="M8 2v4"/><path d="M16 2v4"/><path d="M3 10h18"/><rect x="3" y="4" width="18" height="18" rx="2"/>',
    "chevron-right" => '<path d="m9 18 6-6-6-6"/>',
    "copy" => '<rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>',
    "x" => '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>',
    "edit" => '<path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4Z"/>',
    "eye" => '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/>',
    "filter" => '<path d="M3 5h18"/><path d="M6 12h12"/><path d="M10 19h4"/>',
    "globe" => '<circle cx="12" cy="12" r="10"/><path d="M2 12h20"/><path d="M12 2a15.3 15.3 0 0 1 0 20"/><path d="M12 2a15.3 15.3 0 0 0 0 20"/>',
    "home" => '<path d="m3 11 9-8 9 8"/><path d="M5 10v10h14V10"/><path d="M10 20v-6h4v6"/>',
    "lock" => '<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>',
    "log-out" => '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="M16 17l5-5-5-5"/><path d="M21 12H9"/>',
    "medal" => '<path d="M7 2h10l-3 6h-4Z"/><circle cx="12" cy="14" r="6"/><path d="m10.5 14 1 1 2-2"/>',
    "more-vertical" => '<circle cx="12" cy="5" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="12" cy="19" r="1"/>',
    "plus" => '<path d="M12 5v14"/><path d="M5 12h14"/>',
    "save" => '<path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2Z"/><path d="M17 21v-8H7v8"/><path d="M7 3v5h8"/>',
    "search" => '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',
    "shield" => '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10"/><path d="m9.5 12 1.7 1.7 3.8-4"/>',
    "trash" => '<path d="M3 6h18"/><path d="M8 6V4h8v2"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/>',
    "trophy" => '<path d="M8 21h8"/><path d="M12 17v4"/><path d="M7 4h10v5a5 5 0 0 1-10 0Z"/><path d="M5 6H3v2a4 4 0 0 0 4 4"/><path d="M19 6h2v2a4 4 0 0 1-4 4"/>',
    "user" => '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>'
  }.freeze

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

  def ui_icon(name, **options)
    path = ICON_PATHS.fetch(name.to_s)
    classes = ["ui-icon", options.delete(:class)].compact.join(" ")

    content_tag(
      :svg,
      path.html_safe,
      {
        class: classes,
        xmlns: "http://www.w3.org/2000/svg",
        viewBox: "0 0 24 24",
        fill: "none",
        stroke: "currentColor",
        "stroke-width": options.delete(:stroke_width) || 2,
        "stroke-linecap": "round",
        "stroke-linejoin": "round",
        aria: { hidden: true }
      }.merge(options)
    )
  end

  def user_first_name(user)
    user.name.to_s.squish.split.first.presence || user.email.to_s.split("@").first
  end
end
