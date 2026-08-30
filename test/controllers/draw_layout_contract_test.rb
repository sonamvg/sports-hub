require "test_helper"

class DrawLayoutContractTest < ActionDispatch::IntegrationTest
  test "draw stylesheet keeps the bracket as a compact horizontal dendrogram" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read

    assert_includes css, ".draw-bracket"
    assert_includes css, "--slot-height:72px;"
    assert_includes css, "--match-height:136px;"
    assert_includes css, "grid-template-rows:repeat(var(--bracket-size), var(--slot-height));"
    assert_includes css, "grid-row:var(--match-row-start) / span var(--match-row-span);"
    assert_includes css, "align-self:center;"
    assert_includes css, ".draw-round:not(:first-child) .draw-match::before"
    assert_includes css, ".draw-round:not(:first-child) .draw-match-form::before"
    assert_includes css, ".draw-bye-match,\n.draw-pending-match"
    assert_includes css, "--match-height:92px;"
    assert_not_includes css, "margin-top:calc((var(--match-span)"
  end

  test "shared action buttons use the modern compact button contract" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read

    assert_includes css, ".nav-button,.primary-button"
    assert_includes css, ".secondary-button"
    assert_includes css, "border-radius:4px;"
    assert_includes css, "min-height:44px;"
    assert_includes css, "text-transform:uppercase;"
    assert_includes css, "transition:background .16s ease,border-color .16s ease,color .16s ease,transform .16s ease;"
    assert_includes css, ".draw-save-button"
    assert_includes css, "min-height:36px;"
  end
end
