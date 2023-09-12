# ERC20-related bugs

## ZeroAmountTransfer

amount=0 で transfer するとエラーが発生する

### 🔗 URL

https://github.com/code-423n4/2022-02-hubble-findings/issues/29

### ⛳️ Condition

- ERC20 トークンが transfer される際に、amount が 0 でないことを確認していない
- トークンの制限をしていないため、どんな ERC20 トークンでも transfer する可能性がある

https://github.com/code-423n4/2022-05-sturdy/blob/78f51a7a74ebe8adfd055bdbaedfddc05632566f/smart-contracts/ConvexCurveLPVault.sol#L70-L85

```javascript
  function _transferYield(address _asset) internal {
    require(_asset != address(0), Errors.VT_PROCESS_YIELD_INVALID);
    uint256 yieldAmount = IERC20(_asset).balanceOf(address(this));

    // transfer to treasury
    if (_vaultFee > 0) {
      uint256 treasuryAmount = _processTreasury(_asset, yieldAmount);
      yieldAmount = yieldAmount.sub(treasuryAmount);
    }

    // transfer to yieldManager
    address yieldManager = _addressesProvider.getAddress('YIELD_MANAGER');
    TransferHelper.safeTransfer(_asset, yieldManager, yieldAmount);

    emit ProcessYield(_asset, yieldAmount);
  }
```

### 👨‍💻 PoC

ERC20 トークンの中には、ゼロ枚の transfer で revert されるものがあります（例：LEND)

参照: https://github.com/d-xo/weird-erc20#revert-on-zero-value-transfers

1. `_asset`に LEND トークンが入力される
2. `yieldAmount`が 0 になる
3. 下記のように関数が実行される
   `TransferHelper.safeTransfer(LEND_TOKEN_ADDRESS, yieldManager, 0);`
4. トランザクションが revert される

```javascript
    // transfer to treasury
    if (_vaultFee > 0) {
      uint256 treasuryAmount = _processTreasury(_asset, yieldAmount);
      yieldAmount = yieldAmount.sub(treasuryAmount);
    }

    // transfer to yieldManager
    address yieldManager = _addressesProvider.getAddress('YIELD_MANAGER');
    TransferHelper.safeTransfer(_asset, yieldManager, yieldAmount);
```

### ✅ Recommendation

例: 下記のように変更してください

```javascript
+	if (yieldAmount > 0) {
	    // transfer to treasury
	    if (_vaultFee > 0) {
	      uint256 treasuryAmount = _processTreasury(_asset, yieldAmount);
	      yieldAmount = yieldAmount.sub(treasuryAmount);
	    }

	    // transfer to yieldManager
	    address yieldManager = _addressesProvider.getAddress('YIELD_MANAGER');
	    TransferHelper.safeTransfer(_asset, yieldManager, yieldAmount);
+  }
```

### 👬 Similar Issue

https://github.com/code-423n4/2022-02-concur-findings/issues/231
