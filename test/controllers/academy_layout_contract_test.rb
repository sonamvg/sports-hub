require "test_helper"

class AcademyLayoutContractTest < ActionDispatch::IntegrationTest
  test "academy athlete rows use compact kebab action menus" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read

    assert_includes css, ".kebab-menu"
    assert_includes css, ".kebab-menu summary"
    assert_includes css, "height:36px;"
    assert_includes css, "width:36px;"
    assert_includes css, ".kebab-menu-panel"
    assert_includes css, "min-width:190px;"
    assert_includes css, "position:absolute;"
    assert_includes css, "right:0;"
    assert_includes css, ".kebab-menu-item"
    assert_includes css, ".kebab-menu-danger"
  end

  test "academy cards keep the logo and menu card contract" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read

    assert_includes css, ".academy-card"
    assert_includes css, "border-radius:8px;"
    assert_includes css, ".academy-card-main"
    assert_includes css, ".academy-card-logo"
    assert_includes css, "height:172px;"
    assert_includes css, ".academy-card-menu"
    assert_includes css, ".academy-card:has(.kebab-menu[open])"
    assert_includes css, ".academy-athlete-stack"
  end

  test "academy profile uses compact logo contact and top menu layout" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read

    assert_includes css, ".academy-show-header"
    assert_includes css, ".academy-show-logo"
    assert_includes css, ".academy-show-menu"
    assert_includes css, ".academy-contact-panel"
    assert_includes css, ".academy-contact-grid"
    assert_includes css, "grid-template-columns:repeat(2,minmax(0,1fr));"
  end

  test "copy email closes the open kebab menu after feedback" do
    js = Rails.root.join("app/assets/javascripts/application.js").read

    assert_includes js, "const menu = button.closest(\"details\")"
    assert_includes js, "menu.removeAttribute(\"open\")"
    assert_includes js, "label.textContent = \"Copied\""
  end
end
