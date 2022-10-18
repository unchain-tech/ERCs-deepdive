# Slot の衝突が起きる

## 🔗 URL

https://github.com/code-423n4/2022-03-joyn-findings/issues/108

## ⛳️ Condition

1. Proxy を実装している
2. EIP1967 のように Slot の衝突を避けるような実装がない

https://github.com/code-423n4/2022-03-lifinance/blob/main/src/Facets/DexManagerFacet.sol#L62-L77

```solidity
contract CoreProxy is Ownable {
       address private immutable _implement;
}
```

## 👨‍💻 PoC

```
/* Bug Pattern */
|Proxy                     |Implementation           |
|--------------------------|-------------------------|
|address _implementation   |address _owner           | <=== Storage collision!
|...                       |mapping _balances        |
|                          |uint256 _supply          |
|                          |...                      |
------------------------------------------------------
```

## ✅ Recommendation

EIP1967 のような実装をして Slot の衝突をさける
https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies

```
/* EIP1967 */
|Proxy                     |Implementation           |
|--------------------------|-------------------------|
|...                       |address _owner           |
|...                       |mapping _balances        |
|...                       |uint256 _supply          |
|...                       |...                      |
|...                       |                         |
|address _implementation   |                         | <=== Randomized slot.
|...                       |                         |
|...                       |                         |

```

## 👬 Similar Issue

https://github.com/code-423n4/2022-05-rubicon-findings/issues/441
