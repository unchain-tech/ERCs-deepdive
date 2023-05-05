# Low-level calls

## ReturnTrueNotExist

低レベルの Call はアドレスが存在しない場合でも true を返す

### 🔗 URL

https://github.com/code-423n4/2022-04-axelar-findings/issues/11

## ⛳️ Condition

1. 外部のコントラクトアドレスを呼び出すために`call`を使用している
2. そのコントラクトアドレスが存在するのかを確認していない

https://github.com/code-423n4/2022-04-axelar/blob/dee2f2d352e8f20f20027977d511b19bfcca23a3/src/AxelarGateway.sol#L545-L548

```
function _callERC20Token(address tokenAddress, bytes memory callData) internal returns (bool) {
    (bool success, bytes memory returnData) = tokenAddress.call(callData);
    return success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
}
```

## 👨‍💻 PoC

Solidity のドキュメントに書かれているように、低レベル関数 call、delegatecall、staticcall は、EVM の設計の一部として、呼び出されたアカウントが存在しない場合、最初の戻り値として true を返します。
https://docs.soliditylang.org/en/develop/control-structures.html#error-handling-assert-require-revert-and-exceptions

1. 悪意のないユーザーが誤って`_callERC20Token`の`tokenAddress`にまだ deploy されていないアドレスを入力したとする
2. 関数を実行しても true を返すためユーザーは関数が正常に実行されていないことに気づくことができない

## ✅ Recommendation

外部のコントラクトアドレスが存在するのかを確認する

https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/utils/Address.sol#L36-L42

```
function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize/address.code.length, which returns 0
    // for contracts in construction, since the code is only stored at the end
    // of the constructor execution.

    return account.code.length > 0;
}

function _callERC20Token(address tokenAddress, bytes memory callData) isContract(tokenAddress) internal returns (bool) {
    (bool success, bytes memory returnData) = tokenAddress.call(callData);
    return success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
}
```

## 👬 Similar Issue

https://github.com/code-423n4/2022-03-rolla-findings/issues/46
