# Reference photos

One folder per pet, named to match the 样本编号 / 用例编号 used in the scoring
workbook (`P01`, `P02`, ... `P10`). Put 2-3 fixed reference photos for that
pet directly inside its folder - `.jpg` / `.jpeg` / `.png` / `.webp`, any
filenames. The same set of photos is reused for every model and every round
for that pet, matching the workbook's requirement that "同一个测试用例在不同
模型中必须使用同一组参考图".

```
pets/
  P01/
    front.jpg
    side.jpg
  P02/
    ref1.png
  ...
  P10/
    ...
```

This folder is gitignored (real pet photos, not code) except for this file.
