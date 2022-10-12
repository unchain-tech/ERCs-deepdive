# Admin は高額な手数料を設定できる

## 🔗 URL

https://github.com/code-423n4/2022-06-infinity-findings/issues/269

## ⛳️ Condition

1. Admin が設定できる fee の上限や下限が設定されていない

https://github.com/code-423n4/2022-06-infinity/blob/765376fa238bbccd8b1e2e12897c91098c7e5ac6/contracts/core/InfinityExchange.sol#L1266-L1269

```solidity
function setProtocolFee(uint16 _protocolFeeBps) external onlyOwner {
PROTOCOL_FEE_BPS = _protocolFeeBps;
emit NewProtocolFee(_protocolFeeBps);
}
```

## 👨‍💻 PoC

PROTOCOL_FEE_BPS = 500

1. Alice が高額の取引をこのプラットフォームで行うためのトランザクションを送信する
2. Admin は フロントランをして Alice のトランザクションよりも前に Fee を`setProtocolFee()`関数で 10000 に設定をする
3. Alice が高額な手数料を支払った後に、`setProtocolFee()`関数で 500 に戻す
4. Alice は気づかない間に高額な手数料を支払うことになる

## ✅ Recommendation

PROTOCOL_FEE_BPS の上限値を設定してください

```solidity
// before
function setProtocolFee(uint16 _protocolFeeBps) external onlyOwner {
PROTOCOL_FEE_BPS = _protocolFeeBps;
emit NewProtocolFee(_protocolFeeBps);
}

// after
uin16 MAX_PROTOCOL_FEE_BPS = 2000;
function setProtocolFee(uint16 _protocolFeeBps) external onlyOwner {
require(_protocolFeeBps < MAX_PROTOCOL_FEE_BPS);
PROTOCOL_FEE_BPS = _protocolFeeBps;
emit NewProtocolFee(_protocolFeeBps);
}
```

## 👬 Similar Issue

https://github.com/code-423n4/2022-05-cally-findings/issues/48
