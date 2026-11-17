#!/usr/bin/env bash
# Mechanical version of the four per-step checks. Run locally and in CI.
set -uo pipefail
fail=0
err() { printf '✗ %b\n' "$1"; fail=1; }

# 1. Firebase SDKs only in remote datasources
hits=$(grep -rlE "package:(firebase_[a-z_]+|cloud_firestore|google_sign_in)/" lib --include='*.dart' \
       | grep -v '^lib/data/datasources/remote/' || true)
[ -n "$hits" ] && err "Firebase import outside data/datasources/remote:\n$hits"

# 2. Views: no DI, no data layer, no Firebase
hits=$(grep -rnE "Get\.(put|lazyPut|putAsync|find)\b|datasources/|repositories/" lib/features/*/views || true)
[ -n "$hits" ] && err "View touches DI or the data layer:\n$hits"

# 3. ViewModels never touch datasources
hits=$(grep -rn "datasources/" lib/features/*/viewmodels || true)
[ -n "$hits" ] && err "ViewModel imports a datasource:\n$hits"

# 4. Anything holding a disposable must override onClose
for f in $(grep -rlE "Timer|StreamSubscription|TextEditingController|AnimationController|PageController|AudioPlayer|Worker|AppLifecycleListener" \
             lib/features/*/viewmodels lib/core/services lib/core/network lib/app/session 2>/dev/null); do
  grep -q "void onClose" "$f" || err "missing onClose(): $f"
done

# 5. No hardcoded keys outside generated (gitignored) options
hits=$(grep -rnE "AIza[0-9A-Za-z_-]{20,}|-----BEGIN (RSA )?PRIVATE KEY" lib android/app/src/main ios/Runner 2>/dev/null \
       | grep -vE 'firebase_options/|GoogleService-Info.plist|google-services.json' || true)
[ -n "$hits" ] && err "Possible hardcoded secret:\n$hits"

[ $fail -eq 0 ] && echo "✓ architecture checks passed"
exit $fail
