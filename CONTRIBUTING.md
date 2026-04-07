# Contributing

欢迎为 cheerer 提交 Issue、PR 和改进建议。

## 开发环境

仅需以下环境：

- bash
- shellcheck

## 如何添加新动画

1. 在 `scripts/animations/` 下创建新的动画脚本，例如 `your_anim.sh`
2. 保持脚本可执行，并确保可以单独运行
3. 在 `scripts/cheer.sh` 的 `ANIMS` 数组中加入动画名称
4. 运行 `shellcheck scripts/cheer.sh scripts/animations/*.sh scripts/voices/*.sh`
5. 运行 `bash scripts/cheer.sh test` 验证功能正常

## 如何添加新语言

1. 在 `scripts/voices/` 下创建新的语言脚本，例如 `cheer_fr.sh`
2. 在 `scripts/cheer.sh` 中接入对应语言逻辑
3. 确保新脚本可执行
4. 运行 `shellcheck scripts/cheer.sh scripts/animations/*.sh scripts/voices/*.sh`
5. 运行 `bash scripts/cheer.sh test` 验证功能正常

## PR 要求

提交 PR 前，请确保：

- shellcheck 通过
- 测试通过
- 如有必要，README 和相关文档已同步更新
