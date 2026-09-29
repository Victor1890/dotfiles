#!/usr/bin/env bash
# Aprovisiona los perfiles/modos "Silencio" y "Rendimiento" de CoolerControl.
# Va DESPUÉS de stow_packages (necesita curves.json ya enlazado) y no en
# install-packages.sh (que corre antes del stow). Sin el token de la API
# (creado a mano desde la GUI, ver docs/omarchy.md) no hay nada que
# aprovisionar todavía. Idempotente.
#
# Silencio queda activo por defecto (apply_on_boot del daemon); Rendimiento
# se activa manualmente desde la GUI de CoolerControl cuando haga falta más
# refrigeración — no hay cambio automático de perfil.
#
# Safe-fail a propósito: nada de esta función debe poder abortar el resto del
# bootstrap (set -e). Cada paso que puede fallar por causas externas al repo
# (coolercontrold caído, hardware distinto) se comprueba explícitamente y, si
# falla, se registra en COOLERCONTROL_ISSUES en vez de propagar el error;
# report_coolercontrol_issues() imprime el resumen al final del bootstrap
# (ver main).
COOLERCONTROL_ISSUES=()

ensure_coolercontrol_profiles() {
  [[ "${OS}" == "omarchy" ]] || return 0
  local token="${XDG_STATE_HOME:-${HOME}/.local/state}/coolercontrol-modes/api-token"
  if [[ ! -s "${token}" ]]; then
    log "Falta el token de la API de CoolerControl (${token}); perfiles no aprovisionados."
    log "Créalo desde la GUI (Settings > Access Tokens) y reejecuta el bootstrap; ver docs/omarchy.md."
    COOLERCONTROL_ISSUES+=("Falta el token de la API (${token}); créalo desde la GUI (ver docs/omarchy.md).")
    return 0
  fi

  log "Aprovisionando perfiles/modos de CoolerControl…"
  if ! "${HOME}/.local/bin/coolercontrol-provision"; then
    log "Aprovisionamiento falló; revisa manual (¿coolercontrold corriendo? ¿hardware detectado?)."
    COOLERCONTROL_ISSUES+=("coolercontrol-provision falló; revisa el log de arriba (¿coolercontrold corriendo?).")
    return 0
  fi
}

report_coolercontrol_issues() {
  [[ ${#COOLERCONTROL_ISSUES[@]} -gt 0 ]] || return 0
  log "CoolerControl: ${#COOLERCONTROL_ISSUES[@]} paso(s) fallaron (no bloquearon el bootstrap):"
  local issue
  for issue in "${COOLERCONTROL_ISSUES[@]}"; do
    log "  - ${issue}"
  done
}
