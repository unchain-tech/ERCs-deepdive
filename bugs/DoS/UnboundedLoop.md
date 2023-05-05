# 長すぎるループ

## 🔗 URL

https://github.com/code-423n4/2022-03-joyn-findings/issues/6

## ⛳️ Condition

1. 誰でも配列のアイテムを追加できる
2. その配列の長さに応じてループ処理をしている

https://github.com/code-423n4/2022-03-joyn/blob/c9297ccd925ebb2c44dbc6eaa3effd8db5d2368a/splits/contracts/Splitter.sol#L50-L59

```
/// Loop
for (uint256 i = 0; i < currentWindow; i++) {
    if (!isClaimed(msg.sender, i)) {
        setClaimed(msg.sender, i);

        amount += scaleAmountByPercentage(
            balanceForWindow[i],
            percentageAllocation
        );
    }
}

/// Add item for array
function incrementWindow(uint256 royaltyAmount) public returns (bool) {
    uint256 wethBalance;

    /* ... */

    // here
    balanceForWindow.push(royaltyAmount);
    currentWindow += 1;
    emit WindowIncremented(currentWindow, royaltyAmount);
    return true;
}
```

## 👨‍💻 PoC

1. Eve が`incrementWindow()`を実行して currentWindow の配列を 1000 まで増加させる
2. `currentWindow`を削除する関数がないため、増加するしかない
3. ループを実行するとガス代がかかりすぎ、ブロックガスリミットを超えるためトランザクションが revert される
4. 最終的にこのループを含む`claimForAllWindows()`が使用できなくなる(Denial of Service = サービスの妨害

## ✅ Recommendation

1. 配列の要素の最大を決める

```
uint256 constant MAX_CURRENT_WINDOW = 100;

function incrementWindow(uint256 royaltyAmount) public returns (bool) {

    /* ... */

    require(balanceForWindow.length < MAX_CURRENT_WINDOW,"TOO MUCH"); // here
    balanceForWindow.push(royaltyAmount);
    currentWindow += 1;
}
```

2. `incrementWindow`を実行できるユーザーを制限する

```

mapping(address=>bool) whitelist;

modifier onlyWhitelist {
    require(whitelist[msg.sender]);
    _;
}

function incrementWindow(uint256 royaltyAmount) public /* add */ onlyWhitelist returns (bool) {

    /* ... */

    require(balanceForWindow.length < MAX_CURRENT_WINDOW,"TOO MUCH"); // here
    balanceForWindow.push(royaltyAmount);
    currentWindow += 1;
}
```

## 👬 Similar Issue

https://github.com/code-423n4/2022-05-aura-findings/issues/197

https://github.com/code-423n4/2022-03-biconomy-findings/issues/24

https://github.com/code-423n4/2022-02-hubble-findings/issues/41
