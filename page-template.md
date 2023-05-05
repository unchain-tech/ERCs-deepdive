# Title

ここにバグのタイトルを記述してください

## 🔗 URL

ここに該当する Bug の URL を記載してください

例: https://github.com/code-423n4/2022-03-lifinance-findings/issues/34

## ⛳️ Condition

ここにバグが起こる条件を記載してください
例：

1. ループ内で return を使用している

_該当するコードがあると Good👍_

https://github.com/code-423n4/2022-03-lifinance/blob/main/src/Facets/DexManagerFacet.sol#L62-L77

```
function batchRemoveDex(address[] calldata _dexs) external {
    LibDiamond.enforceIsContractOwner();

    for (uint256 i; i < _dexs.length; i++) {
        if (s.dexWhitelist[_dexs[i]] == false) {
            continue;
        }
        s.dexWhitelist[_dexs[i]] = false;
        for (uint256 j; j < s.dexs.length; j++) {
            if (s.dexs[j] == _dexs[i]) {
                _removeDex(j);
                return; // here
            }
        }
    }
}
```

## 👨‍💻 PoC

ここに実際にバグが起こるまでの具体的な道筋を記載してください

例:
dexs.lengh = 20 とする

1. 最初のループで `if (s.dexs[j] == _dexs[i])`が true になる
2. `_removeDex`が実行され、return される
3. 残りの 19 のループが実行されずに`batchRemoveDex`関数が終了する

## ✅ Recommendation

ここにバグを修正する方法を記載してください

例: 下記のように変更してください

```
// before
for (uint256 j; j < s.dexs.length; j++) {
    if (s.dexs[j] == _dexs[i]) {
        _removeDex(j);
        return;
    }
}

// after
for (uint256 j; j < s.dexs.length; j++) {
    if (s.dexs[j] == _dexs[i]) {
        _removeDex(j);
        break;
    }
}
```

## 👬 Similar Issue

ここに同じパターンのバグがあったらリンクを記載してください

例: https://code4rena.com/reports
