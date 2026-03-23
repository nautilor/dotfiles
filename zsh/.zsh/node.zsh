_detect_pm() {
  if   [[ -f pnpm-lock.yaml ]];  then echo pnpm
  elif [[ -f yarn.lock ]];       then echo yarn
  elif [[ -f bun.lockb ]];       then echo bun
  elif [[ -f expo.json ]];       then echo expo
  elif [[ -f deno.json ]];       then echo deno
  elif [[ -f package-lock.json ]]; then echo npm
  else echo npm
  fi
}

function nd() {
  [[ ! -f package.json ]] && echo "No package.json found" && return 1
  local pm=$(_detect_pm)
  case $pm in
    deno) deno run --allow-net --allow-read dev.ts ;;
    *)    $pm run dev ;;
  esac
}

function nb() {
  [[ ! -f package.json ]] && echo "No package.json found" && return 1
  local pm=$(_detect_pm)
  case $pm in
    deno) deno run --allow-net --allow-read build.ts ;;
    *)    $pm run build ;;
  esac
}

function ns() {
  [[ ! -f package.json ]] && echo "No package.json found" && return 1
  local pm=$(_detect_pm)
  case $pm in
    deno) deno run --allow-net --allow-read start.ts ;;
    *)    $pm run start ;;
  esac
}
