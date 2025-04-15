## ✨模块介绍

- 使用 Root 管理器自带的定时任务执行文件清理
- 采用黑白名单机制，支持跳过指定路径
- 路径匹配支持使用 Glob 通配符
- 仅在解锁屏幕时执行操作
- 可自定义执行时段
- 带启停按钮



## 📄文件列表

```
com.haremu.clean/
├── bin/
│   └── bash             <--- 核心脚本的解析器
├── config/              <--- 指向 "/data/adb/crond_clean"
│   ├── 白名单.prop
│   ├── 黑名单.prop
│   └── 计划任务.prop
├── task/
│   └── root             <--- Crontab
├── temp/
│   ├── dir              <--- 已删除目录的计数
│   ├── file             <--- 已删除文件的计数
│   ├── lock             <--- 锁屏状态
│   ├── log              <--- 模块日志
│   └── omit             <--- 不再打印日志列表
├── action.sh            <--- 管理器的执行按钮
├── main.sh              <--- 模块核心脚本
├── module.prop          <--- 模块描述文件
├── module.prop.bak      <--- 模块描述文件备份
└── service.sh           <--- 模块开机启动脚本
```



## 💡模块说明

- 黑名单指的是要 **删除** 的文件或目录，白名单指的是要 **保护** 的文件或目录
- 模块没有内置或启用任何黑名单规则，需要你自行填写！



## 🙏致谢名单

- 本模块代码思路参考了如下项目，对此表示由衷的感谢！
- [black_and_white_list](https://github.com/Petit-Abba/black_and_white_list)



## 📢项目声明

- 二次修改分发建议保留本项目作者署名，感谢你的支持！
- [Crond_Clean](https://github.com/galnetwen/Crond_Clean)



## 🌏免责声明

- 本项目不承担任何责任
- 使用本模块即代表你已愿意承担一切后果
- 由于删除操作本身就有高危特性，填错路径导致资料丢失概不负责
