moon_sfx 项目申报书

1、项目名称
moon_sfx：基于 MoonBit 原生实现的轻量级过程化音频合成与复古游戏音效引擎

2、项目简介
moon_sfx 是一个纯原生、零外部依赖（Zero-Dependency）的过程化音频合成与复古游戏音效引擎。项目针对 WebAssembly 网页游戏、跨平台独立游戏、UI 交互反馈以及无资源音频（Asset-less Game Audio）等场景，提供高保真波形振荡合成、ADSR 声音包络调制、sfxr 经典复古游戏音效生成、数字信号滤波处理与标准 RIFF WAVE 二进制文件生成能力。
项目构建了清晰的分层式架构交付体系：
第一层为数学波形振荡与声音包络层：提供正弦波（Sine）、方波/脉冲波（Square/PWM）、锯齿波（Sawtooth）、三角波（Triangle）与伪随机白噪声（Noise）五大经典波形振荡器，配合支持线性与对数过渡的 4 段式 ADSR 包络发生器；
第二层为过程化音效与数字滤波层：重构实现了经典 sfxr 核心生成算法，支持激光射击（Laser）、跳跃（Jump）、爆炸（Explosion）、金币拾取（Coin）、受到伤害（Hit）、能力提升（Powerup）与按键选择（Blip）7 大经典预设，支持基于随机种子的可复现变异（Mutate）与随机化，并集成了频率动态滑移、颤音（Vibrato）与双二阶低通/高通数字滤波器；
第三层为二进制容器与多端交付层：纯原生按字节级别打包符合 RFC / Microsoft 规范的 16 位与 8 位 PCM RIFF WAVE 二进制音频流，内置 Base64 Data URI 生成与极简乐符旋律音序器（MML Sequencer），直接赋能浏览器端与 Native 端发声。

3、项目方向与通用性说明
项目方向：MoonBit 基础库 / 多媒体与数字信号处理（DSP）基础设施 / 2D/3D 游戏开发基础构件。
通用性说明：经对 mooncakes.io 官方包仓库与 GitHub 开源生态的全量排查检索，目前 MoonBit 开源生态在原生音频合成、音效发生器与数字音频编解码领域完全空白。现有的 WebAssembly 游戏或模拟器项目由于缺乏原生音频支持，大多只能保持无声或高度依赖复杂的宿主 JavaScript FFI。本项目作为底层纯数学与信号计算引擎，无需外部 C/Rust 动态库或宿主运行时注入，可无缝交叉编译至 WebAssembly、Native 及 JavaScript 目标平台，为未来 MoonBit 生态内的各类游戏框架（如 selene ECS）、模拟器、CLI 工具和 UI 交互组件提供通用的基础发声基座。

4、至少3个完整的预期使用场景
（1）WebAssembly 与 HTML5 网页游戏的纯原生即时音效生成：在无外部音效素材资源包的情况下，通过几十字节的紧凑参数结构体动态实时生成激光、爆炸、跳跃、金币等 8-bit / 16-bit 经典游戏音效，直接输出 PCM WAV 字节流交由 Web Audio API 播放，实现零素材加载（Asset-less）、零网络延迟的轻量化游戏音频系统。
（2）桌面端与嵌入式界面的按键与提示音合成器：在 Native 编译环境下，为各类 CLI 命令行工具、桌面应用或微控制器界面提供操作反馈音效（如按键 Blip、成功提示音、错误告警脉冲等），直接将音频数据保存为本地标准 .wav 文件或推送到音频设备缓冲。
（3）复古音乐与音序器（Chiptune / Tracker / MML）旋律回放：通过内置的乐符频率映射表（十二平均律半音计算）与简易多音轨音序器，按节拍调度播放复古风格的主题旋律与通关 BGM。
（4）游戏开发者音效调优与可视化调音台（Audio Playground）：内置支持导出参数配置与 HTML5 交互式试听工作台，允许开发者在浏览器中实时调参、随机突变音效并一键下载 .wav 音频资源文件。

5、拟实现的核心功能
（1）基础数学波形振荡器（Oscillator）：
1. Sine（正弦波）：纯净基频平滑波形；
2. Square / Pulse（方波/脉冲波）：支持可配置占空比（Duty Cycle）与脉宽调制（PWM），产生浓郁的 8-bit / NES 风格复古质感；
3. Sawtooth（锯齿波）：包含全频谐波，泛音明亮丰富；
4. Triangle（三角波）：主要包含奇次谐波且衰减极快，适于低音及柔和音色；
5. Noise（噪声发生器）：基于伪随机数发生器生成宽频白噪声，适于爆炸、碰撞与打击乐。
（2）高精度声音包络器（ADSR Envelope Generator）：
1. Attack（起音时间）、Decay（衰减时间）、Sustain（延音电平）、Release（释音时间）；
2. 支持线性渐变与对数感知音量衰减过渡，彻底消除突变爆音（Click/Pop）；
3. 提供预设触发（Trigger）与释音（Release）状态机。
（3）经典过程化复古音效生成器（Procedural SFX Generator - sfxr 体系）：
1. Laser（激光射击）：高频快速向下平滑滑移；
2. Jump（跳跃）：低频向上阶跃滑移并伴随快速衰减；
3. Explosion（爆炸）：白噪声结合低频谐振与长释放包络；
4. Coin / Pickup（金币/拾取）：双频或三频短促阶梯跳跃；
5. Hit / Hurt（受击/受伤）：方波与噪声混合结合剧烈俯冲音调；
6. Powerup（能力升级）：多级升阶扫频序列；
7. Blip / Select（界面点按）：极短高频方波脉冲；
8. 具备确定性随机种子（Seed）的变异（Mutate）与随机化（Randomize）发生器。
（4）数字信号效果器（DSP Effects）：
1. 频率动态滑移（Frequency Slide / Drop / Delta）；
2. 颤音发生器（Vibrato with Depth & Speed）；
3. 双二阶数字低通与高通滤波器（Biquad Low-pass / High-pass Filter with Cutoff & Resonance）；
4. 简易回声/混响延迟（Echo / Delay）；
5. 柔和过载失真（Overdrive Distortion）；
6. Lo-Fi 8-bit/12-bit 阶梯位深度量化与降采样位深度破坏器（Bitcrusher）。
（5）标准 RIFF WAVE 二进制容器与流式打包器：
1. 严格遵循 Microsoft RIFF WAVE / RFC 规范构造标准的 44 字节二进制头部信息；
2. 支持 8-bit 无符号 PCM 与 16-bit 有符号 PCM 采样编码；
3. 支持 44100Hz、22050Hz 等主流采样率，单声道与立体声输出；
4. 提供 Base64 Data URI 生成器（可直接嵌入网页 audio 标签或 JS Audio 对象播放）。
（6）旋律音序器（MML / Melodic Sequencer）：
1. 乐音音高转频率映射（C0 ~ B8，涵盖 12 平均律半音）；
2. 节拍 BPM 与音符时值（全音符、二分、四分、八分、十六分音符及休止符）调度；
3. 多音符时序串联与多音轨混音（Mixing）。

6、是否为原创项目、移植项目或参考已有开源项目
本项目为基于经典算法架构的深度移植与增强创新项目。

7、如为移植项目，需说明参考项目名称，简要说明改造计划
（1）参考项目信息：
参考项目一：sfxr（C++ 实现，Tomas Pettersson 原创复古音效生成器）
来源链接：https://github.com/grimfang4/sfxr
许可证：Public Domain
参考项目二：jsfxr（JavaScript 移植与 Web Audio 适配版）
来源链接：https://github.com/chr15m/jsfxr
许可证：Apache-2.0
本项目许可证：Apache-2.0
（2）改造与增强计划：
第一，类型系统与内存安全重构：彻底摒弃原版 C 语言中使用的大量隐式全局状态变量与裸浮点指针运算，利用 MoonBit 的代数数据类型（Enum）、不可变数据结构与模式匹配进行类型安全与内存安全重构；
第二，分层解耦与模块化设计：原版 sfxr 将波形、包络、UI 与回放逻辑高度耦合，本项目将其彻底解耦为振荡器模块、包络模块、DSP 滤波模块、过程化预设发生器以及 WAV 容器编码器，每个模块均可单独引用测试；
第三，增强 ADSR 包络与现代数字滤波：突破原版仅支持简单 Attack/Sustain/Decay 3 段且无法单独配置释音斜率的局限，提供完整 4 段 ADSR 并引入具有谐振峰调节能力的双二阶数字滤波器；
第四，新增乐符频率换算与旋律音序器：原版仅能生成单发独立音效，本项目创新性引入了乐符音阶换算（十二平均律）与轻量音序器，使得游戏通关旋律、简单 BGM 编排成为可能；
第五，原生二进制打包与开箱即用多端输出：无需依赖操作系统底层音频驱动即可在内存中直接生成规范的 RIFF WAV 二进制流，且配套提供 Base64 Data URI 与交互式 HTML5 调音台演示。

8、GitHub 仓库链接，需有至少 10 个有效 commits，文档需包含英文和中文，仓库须配置自动化测试流水线
GitHub 仓库链接：https://github.com/zmjknn/moon_sfx
有效提交记录（Commits）：仓库已包含 13 个独立、语义明确的规范提交（涵盖 core 架构、synth 振荡器、envelope 包络、dsp 滤波、sfxr 预设、wav 编码、sequencer 音序器、export 工具、cli 终端应用、tests 测试集与 CI 流水线），提交遵循 Conventional Commits 规范，绝无无意义拆分。
中英文双语文档：仓库已完整配备详实的中文文档与英文技术文档：
中文说明：PROPOSAL.md（项目申报书）与 README.md 中文架构解析；
英文文档：README.md 与 README.mbt.md（包含完整 API Reference、使用范例与架构设计说明）。
自动化测试流水线（CI）：仓库已在 .github/workflows/ci.yml 中配置完整的 GitHub Actions CI 流水线。包含 26 组全覆盖单元与基准测试（moon test）、项目静态检查（moon check）、工程构建（moon build）与 CLI 演示执行（moon run cmd/main）。当前流水线全部处于 全绿灯通过（Status: Completed, Conclusion: Success）状态。
