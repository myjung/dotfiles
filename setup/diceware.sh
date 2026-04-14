#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORDLIST_URL="https://www.eff.org/files/2016/07/18/eff_large_wordlist.txt"
WORDLIST_FILE="${SCRIPT_DIR}/eff_large_wordlist.txt"
WORD_COUNT=7
N_FLAG_SET=0

usage() {
    echo "사용법: $0 [-f wordlist] [-n 단어수] [단어수]" >&2
    echo "  -f  단어 목록 파일 경로 (기본값: 스크립트 디렉토리/eff_large_wordlist.txt)" >&2
    echo "  -n  생성할 단어 수 (기본값: 7)" >&2
    echo "  단어수  -n 없이 숫자만 입력해도 동작" >&2
    exit 1
}

while getopts "f:n:" opt; do
    case $opt in
        f) WORDLIST_FILE="$OPTARG" ;;
        n)
            if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
                echo "오류: 단어 수는 숫자여야 합니다: $OPTARG" >&2
                usage
            fi
            WORD_COUNT="$OPTARG"
            N_FLAG_SET=1
            ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

# 위치 인자로 단어 수 지정
if [[ $# -gt 0 ]]; then
    if ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "오류: 단어 수는 숫자여야 합니다: $1" >&2
        usage
    fi
    if [[ $N_FLAG_SET -eq 1 ]]; then
        echo "오류: -n과 위치 인자를 동시에 쓸 수 없습니다." >&2
        usage
    fi
    WORD_COUNT="$1"
fi

# 단어 목록 없으면 다운로드 (기본 파일일 때만)
if [[ ! -f "$WORDLIST_FILE" ]]; then
    if [[ "$WORDLIST_FILE" != "${SCRIPT_DIR}/eff_large_wordlist.txt" ]]; then
        echo "오류: 지정한 파일을 찾을 수 없습니다: $WORDLIST_FILE" >&2
        exit 1
    fi
    echo "단어 목록 다운로드 중: $WORDLIST_URL" >&2
    if ! curl -fsSL "$WORDLIST_URL" -o "$WORDLIST_FILE"; then
        echo "오류: 단어 목록 다운로드 실패" >&2
        echo "URL이 변경되었거나 EFF 서버에 문제가 있을 수 있습니다." >&2
        echo "수동으로 다운로드 후 -f 옵션으로 경로를 지정하세요." >&2
        exit 1
    fi
fi

# 단어 목록 파싱 및 유효성 검사
mapfile -t WORDS < <(awk '{print $2}' "$WORDLIST_FILE")
TOTAL=${#WORDS[@]}

if (( TOTAL < 1000 )); then
    echo "오류: 단어 목록이 너무 작습니다 (${TOTAL}개). 파일이 손상되었거나 형식이 다를 수 있습니다." >&2
    exit 1
fi

# 기각 샘플링으로 편향 제거
# limit = floor(2^32 / TOTAL) * TOTAL
LIMIT=$(( (4294967296 / TOTAL) * TOTAL ))

get_unbiased_index() {
    while true; do
        local rand
        rand=$(od -An -N4 -tu4 /dev/urandom | tr -d ' \n')
        if (( rand < LIMIT )); then
            echo $(( rand % TOTAL ))
            return
        fi
    done
}

passphrase=()
for ((i = 0; i < WORD_COUNT; i++)); do
    idx=$(get_unbiased_index)
    passphrase+=("${WORDS[$idx]}")
done

echo "${passphrase[*]}"
