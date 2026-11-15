# 宣伝用スクリーンショットの作り方

`frame.html` に、元のスクリーンショット・見出し・説明を URL で渡して、ブラウザで決まったサイズの画像にします。

```
frame.html?w=2868&h=1320&img=<スクリーンショット>&tag=<タグ>&t=<見出し（<br> で改行、<em> でオレンジ）>&s=<説明>
```

- `w` `h`：出力するサイズ（App Store の各端末のサイズ）
- 縦長（h > w）か `col=1` のときは、見出しが上・スクリーンショットが下
- 画像にするには、ヘッドレス Chrome で `--window-size=<w>,<h> --force-device-scale-factor=1 --screenshot` を使う
