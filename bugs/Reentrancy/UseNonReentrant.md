# nonReentrant modifier を使用する

## 🔗 URL

https://github.com/code-423n4/2022-02-redacted-cartel-findings/issues/80

## ⛳️ Condition

1. `safeTransfer`, `safeTransferFrom`が使用されている(fallback function のきっかけになる)
2. Check-Effect-Interaction パターンに従っていない

参照: https://fravoll.github.io/solidity-patterns/checks_effects_interactions.html

https://github.com/code-423n4/2022-02-redacted-cartel/blob/main/contracts/BribeVault.sol#L164-L205

```solidity
function depositBribeERC20(
    bytes32 bribeIdentifier,
    bytes32 rewardIdentifier,
    address token,
    uint256 amount,
    address briber
) external onlyRole(DEPOSITOR_ROLE) {
    require(bribeIdentifier.length > 0, "Invalid bribeIdentifier");
    require(rewardIdentifier.length > 0, "Invalid rewardIdentifier");
    require(token != address(0), "Invalid token");
    require(amount > 0, "Amount must be greater than 0");
    require(briber != address(0), "Invalid briber");

    Bribe storage b = bribes[bribeIdentifier];
    address currentToken = b.token;
    require(
        // If bribers want to bribe with a different token they need a new identifier
        currentToken == address(0) || currentToken == token,
        "Cannot change token"
    );

    // Since this method is called by a depositor contract, we must transfer from the account
    // that called the depositor contract - amount must be approved beforehand
    IERC20(token).safeTransferFrom(briber, address(this), amount);

    b.amount += amount; // Allow bribers to increase bribe

    // Only set the token address and update the reward-to-bribe mapping if not yet set
    if (currentToken == address(0)) {
        b.token = token;
        rewardToBribes[rewardIdentifier].push(bribeIdentifier);
    }

    emit DepositBribe(
        bribeIdentifier,
        rewardIdentifier,
        token,
        amount,
        b.amount,
        briber
    );
}
```

## 👨‍💻 PoC

```solidity
function depositBribeERC20(
    bytes32 bribeIdentifier,
    bytes32 rewardIdentifier,
    address token,
    uint256 amount,
    address briber
) external onlyRole(DEPOSITOR_ROLE) {

    // CHECK
    require(bribeIdentifier.length > 0, "Invalid bribeIdentifier");
    require(rewardIdentifier.length > 0, "Invalid rewardIdentifier");
    require(token != address(0), "Invalid token");
    require(amount > 0, "Amount must be greater than 0");
    require(briber != address(0), "Invalid briber");

    // INTERACTION
    IERC20(token).safeTransferFrom(briber, address(this), amount);

    // EFFECT
    b.amount += amount; // Allow bribers to increase bribe

    /* ... */
}
```

## ✅ Recommendation

OpenZeppelin の`nonReentrant` modifier を使用してください

https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol#L50-L54

また Check-Effect-Interaction パターンに従ってください

```

## 👬 Similar Issue

https://github.com/code-423n4/2022-05-rubicon-findings/issues/283
```
