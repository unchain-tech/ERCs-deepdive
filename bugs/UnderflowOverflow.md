# Underflows / Overflows

## Underflow

Underflow が起こる

### 🔗 URL

https://github.com/code-423n4/2022-03-timeswap-findings/issues/32

### ⛳️ Condition

1. 変数の型が`uint`で、引き算の結果が 0 よりも小さくなる

https://github.com/code-423n4/2022-03-timeswap/blob/main/Timeswap/Convenience/contracts/libraries/Borrow.sol#L121-L127

```javascript
if (maxCollateral > dueOut.collateral) {
    uint256 excess; // default by 0
    unchecked {
        excess -= dueOut.collateral; // excess <= 0
    }
    ETH.transfer(payable(msg.sender), excess);
}
```

### 👨‍💻 PoC

1. `uint256 excess;`で、excess 変数が`uint256`の型で宣言されている。デフォルトの値は 0 なので、excess はこの時点で 0。
2. `dueOut.collateral`が 1 だとすると、`unchecked`キーワードの影響で revert は帰さず excess の値は`2^256-1`の値になる
3. `ETH.transfer(payable(msg.sender), excess);`において excess は量を表すため、予期しない大量のトークンを送信することになるのか、資金不足でトランザクションが revert される

## ✅ Recommendation

ここでは同じコントラクトを参考にすると、`excess`は 0 ではなく、`maxCollateral`を代入すべきである
https://github.com/code-423n4/2022-03-timeswap/blob/main/Timeswap/Convenience/contracts/libraries/Borrow.sol#L347

そして underflow が起きないようにチェックが必要である

```javascript
// Underflow Check
if (maxCollateral > dueOut.collateral) {

    // declare excess as a maxColalteral
    uint256 excess = maxCollateral;
    unchecked {
        excess -= dueOut.collateral;
    }
    ETH.transfer(payable(msg.sender), excess);
}
```

### 👬 Similar Issue

https://github.com/code-423n4/2022-04-backd-findings/issues/50
