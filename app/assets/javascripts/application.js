document.addEventListener("change", (event) => {
  if (!event.target.matches("[data-academy-choice-select]")) return

  updateAcademyOtherField(event.target)
})

document.addEventListener("input", (event) => {
  if (!event.target.matches("[data-draw-score-side]")) return

  updateDrawTieDecision(event.target.closest("form"))
})

document.addEventListener("click", (event) => {
  const copyButton = event.target.closest("[data-copy-text]")
  if (!copyButton) return

  copyText(copyButton)
})

document.addEventListener("turbo:load", updateAcademyOtherFields)
document.addEventListener("turbo:load", scheduleAutoDismiss)
document.addEventListener("turbo:load", updateDrawTieDecisions)
document.addEventListener("DOMContentLoaded", updateAcademyOtherFields)
document.addEventListener("DOMContentLoaded", scheduleAutoDismiss)
document.addEventListener("DOMContentLoaded", updateDrawTieDecisions)

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

function updateDrawTieDecisions() {
  document.querySelectorAll("[data-draw-score-form]").forEach((scoreGrid) => {
    updateDrawTieDecision(scoreGrid.closest("form"))
  })
}

function updateDrawTieDecision(form) {
  if (!form) return

  const submit = form.querySelector("[data-draw-score-submit]")
  const roundScores = [1, 2, 3].map((round) => scoreValuesForRound(form, round))
  const hasAllScores = roundScores.every((scores) => scores.red !== null && scores.blue !== null)

  const hasTiedRound = roundScores.some((scores) => scores.red !== null && scores.blue !== null && scores.red === scores.blue)

  updateDrawSubmit(submit, hasAllScores && !hasTiedRound)
}

function scoreValuesForRound(form, round) {
  return {
    round,
    red: scoreValue(form.querySelector(`[data-draw-score-side='red'][data-draw-score-round='${round}']`)),
    blue: scoreValue(form.querySelector(`[data-draw-score-side='blue'][data-draw-score-round='${round}']`))
  }
}

function scoreValue(input) {
  if (!input || input.value.trim() === "") return null

  const value = Number(input.value)
  return Number.isFinite(value) ? value : null
}

function updateDrawSubmit(submit, readyToFreeze) {
  if (!submit) return

  const label = readyToFreeze ? "Freeze result" : "Save result"
  submit.value = label
  const labelElement = submit.querySelector("[data-draw-score-submit-label]")
  if (labelElement) labelElement.textContent = label

  const saveIcon = submit.querySelector(".draw-save-icon-save")
  const lockIcon = submit.querySelector(".draw-save-icon-lock")
  if (saveIcon) saveIcon.hidden = readyToFreeze
  if (lockIcon) lockIcon.hidden = !readyToFreeze
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
