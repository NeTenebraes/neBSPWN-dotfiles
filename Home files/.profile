if command -v qt5ct >/dev/null 2>&1; then
  export QT_QPA_PLATFORMTHEME=qt5ct
elif command -v qt6ct >/dev/null 2>&1; then
  export QT_QPA_PLATFORMTHEME=qt6ct
fi

