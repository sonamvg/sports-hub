require "test_helper"

class DrawLayoutContractTest < ActionDispatch::IntegrationTest
  test "draw stylesheet keeps the bracket as a compact horizontal dendrogram" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read

    assert_includes css, ".draw-bracket"
    assert_includes css, ".draw-page"
    assert_includes css, "background:#090a0b;"
    assert_includes css, "background:#0d0e10;"
    assert_includes css, "--slot-height:174px;"
    assert_includes css, "--match-height:136px;"
    assert_includes css, "grid-template-rows:repeat(var(--bracket-size), var(--slot-height));"
    assert_includes css, "grid-row:var(--match-row-start) / span var(--match-row-span);"
    assert_includes css, "align-self:center;"
    assert_includes css, ".draw-match:has(.draw-scoreboard[open])"
    assert_includes css, "min-height:348px;"
    assert_includes css, ".draw-round:not(:first-child) .draw-match::before"
    assert_includes css, "height:var(--connector-height);"
    assert_includes css, ".draw-round:not(:last-child) .draw-match-form::after"
    assert_includes css, ".draw-round:not(:first-child) .draw-match-form::before"
    assert_includes css, "background:#36383d;"
    assert_includes css, ".draw-bye-match,\n.draw-pending-match"
    assert_includes css, "--match-height:104px;"
    assert_includes css, "border-radius:999px;"
    assert_includes css, "position:absolute;"
    assert_includes css, "border-left-color:#f0b74e;"
    assert_not_includes css, ".draw-match::after"
    assert_not_includes css, "border-right:1px solid #c9c8c3;"
    assert_not_includes css, "writing-mode:vertical-rl;"
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
