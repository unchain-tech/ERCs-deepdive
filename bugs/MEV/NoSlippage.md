# スリッページの制限を設けない

## 🔗 URL

https://github.com/code-423n4/2022-06-illuminate-findings/issues/289

## ⛳️ Condition

1. ユーザーが得られるトークンの最低量が設定できない 例: swap, sell, buy

https://github.com/code-423n4/2022-06-illuminate/blob/912be2a90ded4a557f121fe565d12ec48d0c4684/lender/Lender.sol#L641-L654

```solidity
function yield(
    address u,
    address y,
    uint256 a,
    address r
) internal returns (uint256) {
    // preview exact swap slippage on yield
    uint128 returned = IYield(y).sellBasePreview(Cast.u128(a));

    // send the remaing amount to the given yield pool
    Safe.transfer(IERC20(u), y, a);

    // lend out the remaining tokens in the yield pool
    IYield(y).sellBase(r, returned);

    return returned;
}
```

## 👨‍💻 PoC

`sellBasePreview`で取得した`returned`に関して値のチェックをしていないため、ユーザーが予想していなかった価格になる可能性がある。
このような関数は front-run アタックの標的になりうる

## ✅ Recommendation

ユーザーが`min_returned`などの引数を設定できるようにして、最低価格を下回る際にはトランザクションを中止させる

```solidity
function yield(
    address u,
    address y,
    uint256 a,
    address r,
    uint256 min_returned
) internal returns (uint256) {
    // preview exact swap slippage on yield
    uint128 returned = IYield(y).sellBasePreview(Cast.u128(a));

    require(returned >= min_returned,"TOO SMALL RETURNED"); // add

    // send the remaing amount to the given yield pool
    Safe.transfer(IERC20(u), y, a);

    // lend out the remaining tokens in the yield pool
    IYield(y).sellBase(r, returned);

    return returned;
}
```

## 👬 Similar Issue

https://github.com/code-423n4/2022-02-hubble-findings/issues/113
