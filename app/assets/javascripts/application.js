document.addEventListener("change", (event) => {
  if (!event.target.matches("[data-academy-choice-select]")) return

  updateAcademyOtherField(event.target)
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
