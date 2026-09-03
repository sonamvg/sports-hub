document.addEventListener("change", (event) => {
  if (!event.target.matches("[data-academy-choice-select]")) return

  updateAcademyOtherField(event.target)
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
document.addEventListener("DOMContentLoaded", updateAcademyOtherFields)
document.addEventListener("DOMContentLoaded", scheduleAutoDismiss)

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
