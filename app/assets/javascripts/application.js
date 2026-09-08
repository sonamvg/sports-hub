document.addEventListener("change", (event) => {
  if (!event.target.matches("[data-academy-choice-select]")) return

  updateAcademyOtherField(event.target)
})

document.addEventListener("change", (event) => {
  if (!event.target.matches("[data-match-decision-select]")) return

  updateMatchDecisionFields(event.target)
})

document.addEventListener("input", (event) => {
  if (!event.target.matches("[data-round-points]")) return

  updateRoundRow(event.target.closest("[data-match-round-row]"))
})

document.addEventListener("input", clearResolvedFieldError)
document.addEventListener("change", clearResolvedFieldError)

document.addEventListener("click", (event) => {
  const copyButton = event.target.closest("[data-copy-text]")
  closeKebabMenusOutside(event)
  if (!copyButton) return

  copyText(copyButton)
})

document.addEventListener("turbo:load", updateAcademyOtherFields)
document.addEventListener("turbo:load", scheduleAutoDismiss)
document.addEventListener("turbo:load", initMatchDecisionFields)
document.addEventListener("turbo:load", initBracketViewer)
document.addEventListener("turbo:load", initRoundRows)
document.addEventListener("turbo:load", initSessionTimeout)
document.addEventListener("turbo:load", initMobileNav)
document.addEventListener("turbo:load", initDefaultMidnightDateTimes)
document.addEventListener("DOMContentLoaded", updateAcademyOtherFields)
document.addEventListener("DOMContentLoaded", scheduleAutoDismiss)
document.addEventListener("DOMContentLoaded", initMatchDecisionFields)
document.addEventListener("DOMContentLoaded", initBracketViewer)
document.addEventListener("DOMContentLoaded", initRoundRows)
document.addEventListener("DOMContentLoaded", initSessionTimeout)
document.addEventListener("DOMContentLoaded", initMobileNav)
document.addEventListener("DOMContentLoaded", initDefaultMidnightDateTimes)

function updateAcademyOtherFields() {
  document.querySelectorAll("[data-academy-choice-select]").forEach(updateAcademyOtherField)
}

function updateAcademyOtherField(select) {
  const form = select.closest("form")
  if (!form) return

  const otherField = form.querySelector("[data-academy-other-field]")
  const otherInput = form.querySelector("[data-academy-other-input]")
  const showOther = select.value === "other"

  if (otherField) otherField.hidden = !showOther
  if (otherInput) otherInput.disabled = !showOther
}

function initMatchDecisionFields() {
  document.querySelectorAll("[data-match-decision-select]").forEach(updateMatchDecisionFields)
}

function updateMatchDecisionFields(select) {
  const card = select.closest("[data-match-form]")
  if (!card) return

  const isPoints = select.value === "points"
  const roundsField = card.querySelector("[data-match-rounds-field]")
  const winnerField = card.querySelector("[data-match-winner-field]")

  if (roundsField) roundsField.hidden = !isPoints
  if (winnerField) winnerField.hidden = isPoints
}

function initRoundRows() {
  document.querySelectorAll("[data-match-round-row]").forEach(updateRoundRow)
}

function updateRoundRow(row) {
  if (!row) return

  const oneInput = row.querySelector('[data-round-points="one"]')
  const twoInput = row.querySelector('[data-round-points="two"]')
  const resultEl = row.querySelector("[data-round-result]")
  const superiorityField = row.querySelector("[data-round-superiority-field]")
  const superiorityGroup = row.querySelector("[data-round-superiority-select]")
  if (!oneInput || !twoInput || !resultEl || !superiorityField) return

  const oneValue = oneInput.value.trim()
  const twoValue = twoInput.value.trim()

  resultEl.classList.remove("is-decided", "is-tied")

  if (oneValue === "" || twoValue === "") {
    resultEl.textContent = ""
    superiorityField.hidden = true
    clearSuperiorityChoice(superiorityGroup)
    return
  }

  const one = Number(oneValue)
  const two = Number(twoValue)

  if (one === two) {
    resultEl.textContent = "Tied — pick who showed superiority"
    resultEl.classList.add("is-tied")
    superiorityField.hidden = false
  } else {
    const winnerName = one > two ? oneInput.placeholder : twoInput.placeholder
    resultEl.textContent = `${winnerName} wins this round`
    resultEl.classList.add("is-decided")
    superiorityField.hidden = true
    clearSuperiorityChoice(superiorityGroup)
  }
}

function clearSuperiorityChoice(group) {
  if (!group) return
  group.querySelectorAll('input[type="radio"]').forEach((input) => { input.checked = false })
}

function initBracketViewer() {
  const container = document.querySelector(".brackets-viewer[data-bracket]")
  if (!container || typeof window.bracketsViewer === "undefined") return
  if (container.dataset.rendered === "true") return

  container.dataset.rendered = "true"
  window.bracketsViewer.render(JSON.parse(container.dataset.bracket), { clear: true })
}

function scheduleAutoDismiss() {
  document.querySelectorAll("[data-auto-dismiss]").forEach((element) => {
    if (element.dataset.dismissScheduled === "true") return

    element.dataset.dismissScheduled = "true"
    const delay = Number.parseInt(element.dataset.autoDismiss, 10) || 5000

    window.setTimeout(() => {
      element.classList.add("is-dismissing")
      window.setTimeout(() => element.remove(), 250)
    }, delay)
  })
}

// Reloading (rather than navigating to a logout URL) reuses the server-side
// idle check in ApplicationController#enforce_session_timeout, which is the
// actual source of truth — this timer just makes the sign-out happen without
// waiting for the user's next click.
const SESSION_TIMEOUT_ACTIVITY_EVENTS = ["mousemove", "mousedown", "keydown", "scroll", "touchstart"]

function initSessionTimeout() {
  const timeoutSeconds = Number.parseInt(document.body.dataset.sessionTimeoutSeconds, 10)
  if (!timeoutSeconds) return

  resetSessionTimeoutTimer(timeoutSeconds)

  if (window.__sessionTimeoutListenersAttached) return
  window.__sessionTimeoutListenersAttached = true

  SESSION_TIMEOUT_ACTIVITY_EVENTS.forEach((eventName) => {
    document.addEventListener(eventName, () => {
      const currentTimeoutSeconds = Number.parseInt(document.body.dataset.sessionTimeoutSeconds, 10)
      if (currentTimeoutSeconds) resetSessionTimeoutTimer(currentTimeoutSeconds)
    }, { passive: true })
  })
}

function resetSessionTimeoutTimer(timeoutSeconds) {
  window.clearTimeout(window.__sessionTimeoutTimer)
  window.__sessionTimeoutTimer = window.setTimeout(() => window.location.reload(), timeoutSeconds * 1000)
}

function initMobileNav() {
  const toggle = document.querySelector("[data-mobile-nav-toggle]")
  const closeButton = document.querySelector("[data-mobile-nav-close]")
  const backdrop = document.querySelector("[data-mobile-nav-backdrop]")
  const sideMenu = document.querySelector(".side-menu")
  if (!toggle || !sideMenu) return

  // Toggle the open state directly on the panel and backdrop (rather than
  // relying on a `body.is-open .side-menu` descendant selector) so it takes
  // effect immediately and consistently.
  const setOpen = (open) => {
    document.body.classList.toggle("mobile-nav-open", open)
    sideMenu.classList.toggle("is-open", open)
    backdrop?.classList.toggle("is-open", open)
    toggle.setAttribute("aria-expanded", open ? "true" : "false")
  }

  toggle.addEventListener("click", () => setOpen(true))
  closeButton?.addEventListener("click", () => setOpen(false))
  backdrop?.addEventListener("click", () => setOpen(false))
  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") setOpen(false)
  })
  document.querySelectorAll(".side-menu a").forEach((link) => {
    link.addEventListener("click", () => setOpen(false))
  })
}

function initDefaultMidnightDateTimes() {
  document.querySelectorAll("[data-default-midnight]").forEach((input) => {
    if (input.dataset.midnightBound === "true") return
    input.dataset.midnightBound = "true"

    // The browser fills in the current time of day the first time a date is
    // picked in an empty datetime-local field. Snap that first value to
    // midnight instead — once the field holds a value, later edits (the
    // organizer deliberately picking a time) are left alone.
    input.addEventListener("change", function onFirstChange() {
      input.removeEventListener("change", onFirstChange)
      if (!input.value) return

      const [datePart] = input.value.split("T")
      input.value = `${datePart}T00:00`
    })
  })
}

function copyText(button) {
  const text = button.dataset.copyText
  if (!text || !navigator.clipboard) return

  navigator.clipboard.writeText(text).then(() => {
    const label = button.querySelector("span")
    const menu = button.closest("details")

    if (!label) {
      if (menu) menu.removeAttribute("open")
      return
    }
    const original = label.textContent
    label.textContent = "Copied"
    window.setTimeout(() => {
      label.textContent = original
      if (menu) menu.removeAttribute("open")
    }, 1200)
  })
}

function clearResolvedFieldError(event) {
  const field = event.target
  if (!field.matches("input, select, textarea")) return

  const wrapper = field.closest(".field_with_errors")
  const fieldContainer = wrapper ? wrapper.parentElement : field.parentElement
  if (wrapper) wrapper.classList.remove("field_with_errors")

  fieldContainer?.querySelectorAll("[data-field-error-message]").forEach((message) => {
    message.classList.add("is-resolved")
  })
}

function closeKebabMenusOutside(event) {
  document.querySelectorAll("details.kebab-menu[open]").forEach((menu) => {
    if (!menu.contains(event.target)) menu.removeAttribute("open")
  })
}
