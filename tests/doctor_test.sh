#!/bin/bash
set -euo pipefail

. tests/test_lib.sh
. scripts/lib/config.sh
. scripts/lib/catalog.sh
. scripts/lib/doctor.sh

make_doctor_root() {
  local tmp_dir="$1"
  mkdir -p "$tmp_dir/scripts/animations" "$tmp_dir/scripts/voices" "$tmp_dir/scripts/messages" "$tmp_dir/data"
  printf '#!/bin/bash\n' > "$tmp_dir/scripts/animations/rocket.sh"
  printf '#!/bin/bash\n' > "$tmp_dir/scripts/voices/cheer_en.sh"
  cat > "$tmp_dir/scripts/messages/catalog_en.tsv" <<'EOF'
quick|gentle|qg1|Quick gentle
quick|hype|qh1|Quick hype
quick|steady|qs1|Quick steady
quick|cozy|qc1|Quick cozy
solid|steady|ss1|Solid steady
solid|rapid_fire|sr1|Solid rapid fire
solid|cozy|sc1|Solid cozy
solid|streak|ssk1|Solid streak
solid|triumphant|st1|Solid triumphant
big|triumphant|bt1|Big triumphant
big|streak|bs1|Big streak
big|hype|bh1|Big hype
legendary|milestone|lm1|Legendary milestone
EOF
}

run_doctor_with_root() {
  local root="$1"
  local data_dir="$2"
  local _anim="${CHEERER_ANIM:-rocket}"
  unset CHEERER_ANIM
  CHEERER_ROOT="$root"
  CHEERER_DATA_DIR="$data_dir"
  ANIM_DIR="$root/scripts/animations"
  VOICE_DIR="$root/scripts/voices"
  CHEERER_LANG="en"
  CHEERER_ANIM="$_anim"
  CHEERER_MODE="auto"
  CHEERER_DUMB="auto"
  doctor_reset
  doctor_check_config
  doctor_check_runtime
  doctor_check_assets
  doctor_check_catalog
  doctor_check_optional_files
  doctor_print_report
}

test_doctor_reports_pass_for_happy_path() {
  unset CHEERER_ANIM
  local tmp_dir output
  tmp_dir="$(make_tmp_dir)"
  make_doctor_root "$tmp_dir"

  output="$(run_doctor_with_root "$tmp_dir" "$tmp_dir/data")"

  assert_contains "$output" 'PASS config file not present; defaults apply'
  assert_contains "$output" 'PASS runtime mode resolved to full'
  assert_contains "$output" 'PASS plugin data directory writable'
  assert_contains "$output" 'PASS animations directory found'
  assert_contains "$output" 'PASS voice script exists for lang=en'
  assert_contains "$output" 'PASS catalog coverage valid for en'
  assert_contains "$output" 'WARN custom messages file not found'
  assert_eq "0" "$(doctor_exit_code)"
}

test_doctor_fails_when_configured_animation_missing() {
  local tmp_dir output
  tmp_dir="$(make_tmp_dir)"
  make_doctor_root "$tmp_dir"

  CHEERER_ANIM='missing'
  output="$(run_doctor_with_root "$tmp_dir" "$tmp_dir/data")"

  assert_contains "$output" "FAIL configured animation 'missing' missing script"
  assert_eq "1" "$(doctor_exit_code)"
}

test_doctor_warns_when_voice_script_missing() {
  unset CHEERER_ANIM
  local tmp_dir output
  tmp_dir="$(make_tmp_dir)"
  make_doctor_root "$tmp_dir"
  rm -f "$tmp_dir/scripts/voices/cheer_en.sh"

  output="$(run_doctor_with_root "$tmp_dir" "$tmp_dir/data")"

  assert_contains "$output" 'WARN voice script missing for lang=en'
  assert_eq "0" "$(doctor_exit_code)"
}

test_doctor_fails_when_catalog_invalid() {
  unset CHEERER_ANIM
  local tmp_dir output
  tmp_dir="$(make_tmp_dir)"
  make_doctor_root "$tmp_dir"
  printf 'quick|gentle|only|Only one row\n' > "$tmp_dir/scripts/messages/catalog_en.tsv"

  output="$(run_doctor_with_root "$tmp_dir" "$tmp_dir/data" 2>&1)"

  assert_contains "$output" 'FAIL catalog coverage invalid for en'
  assert_eq "1" "$(doctor_exit_code)"
}

run_test "doctor_reports_pass_for_happy_path" test_doctor_reports_pass_for_happy_path
run_test "doctor_fails_when_configured_animation_missing" test_doctor_fails_when_configured_animation_missing
run_test "doctor_warns_when_voice_script_missing" test_doctor_warns_when_voice_script_missing
run_test "doctor_fails_when_catalog_invalid" test_doctor_fails_when_catalog_invalid
finish_tests
