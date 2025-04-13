/// @notice Registry to map an address to its stealth key information.
interface IERC5564Registry {
    /// @notice Returns the stealth public keys for the given `registrant` to compute a stealth
    /// address accessible only to that `registrant` using the provided `generator` contract.
    /// @dev MUST return zero if a registrant has not registered keys for the given generator.
    function stealthKeys(address registrant, address generator)
        external
        view
        returns (bytes memory spendingPubKey, bytes memory viewingPubKey);

    /// @notice Sets the caller's stealth public keys for the `generator` contract.
    function registerKeys(address generator, bytes memory spendingPubKey, bytes memory viewingPubKey)
        external;

    /// @notice Sets the `registrant`s stealth public keys for the `generator` contract using their
    /// `signature`.
    /// @dev MUST support both EOA signatures and EIP-1271 signatures.
    function registerKeysOnBehalf(
        address registrant,
        address generator,
        bytes memory signature,
        bytes memory spendingPubKey,
        bytes memory viewingPubKey
    ) external;

    /// @dev Emitted when a registrant updates their registered stealth keys.
    event StealthKeyChanged(
        address indexed registrant, address indexed generator, bytes spendingPubKey, bytes viewingPubKey
    );
}