#!/opt/homebrew/bin/bash
# run-cycle-tests.sh — 执行多次部署测试循环

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# 测试次数（默认 3 次）
CYCLES="${1:-3}"
LOG_DIR="$SCRIPT_DIR/../logs"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SUMMARY_LOG="$LOG_DIR/test-summary-${TIMESTAMP}.log"

log_info "=========================================="
log_info "开始循环测试 - 共 $CYCLES 次"
log_info "=========================================="
echo

# 记录测试结果
declare -a RESULTS

for i in $(seq 1 "$CYCLES"); do
    CYCLE_LOG="$LOG_DIR/cycle-${i}-${TIMESTAMP}.log"

    log_info "==================== 测试循环 #${i}/${CYCLES} ===================="
    echo

    # 执行测试循环并记录日志
    if "$SCRIPT_DIR/test-deploy-cycle.sh" "$i" 2>&1 | tee "$CYCLE_LOG"; then
        RESULTS[$i]="✓ PASS"
        log_ok "测试循环 #${i} 成功"
    else
        RESULTS[$i]="✗ FAIL"
        log_error "测试循环 #${i} 失败"
    fi

    echo
    echo "日志已保存到: $CYCLE_LOG"
    echo

    # 如果不是最后一次，等待一段时间
    if [ "$i" -lt "$CYCLES" ]; then
        log_info "等待 10 秒后开始下一轮测试..."
        sleep 10
        echo
    fi
done

# 生成测试摘要
{
    echo "=========================================="
    echo "循环测试摘要"
    echo "=========================================="
    echo "测试时间: $(date)"
    echo "测试次数: $CYCLES"
    echo
    echo "测试结果:"
    for i in $(seq 1 "$CYCLES"); do
        echo "  循环 #${i}: ${RESULTS[$i]}"
    done
    echo

    # 统计成功率
    PASS_COUNT=0
    for result in "${RESULTS[@]}"; do
        if [[ "$result" == *"PASS"* ]]; then
            ((PASS_COUNT++))
        fi
    done

    SUCCESS_RATE=$((PASS_COUNT * 100 / CYCLES))
    echo "成功率: ${PASS_COUNT}/${CYCLES} (${SUCCESS_RATE}%)"
    echo

    if [ "$PASS_COUNT" -eq "$CYCLES" ]; then
        echo "✓ 所有测试通过！部署流程稳定可靠。"
    else
        echo "✗ 部分测试失败，需要进一步优化。"
    fi
    echo "=========================================="
} | tee "$SUMMARY_LOG"

echo
log_info "测试摘要已保存到: $SUMMARY_LOG"
echo

# 返回状态码
if [ "$PASS_COUNT" -eq "$CYCLES" ]; then
    exit 0
else
    exit 1
fi
