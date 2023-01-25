/// @notice Sample IERC5564Generator implementation for the secp256k1 curve.

import './interfaces/IERC5564Generator.sol';
import './interfaces/IERC5564Registry.sol';
import './lib/EllipticCurve.sol';

/**
 * Secp256k1Generator Contract
 */
contract Secp256k1Generator is IERC5564Generator {
    /// @notice Address of this chain's registry contract.
    IERC5564Registry public constant REGISTRY = IERC5564Registry(address(0));

    /// @notice Sample implementation for parsing stealth keys on the secp256k1 curve.
    function stealthKeys(address registrant)
        external
        view
        returns (
        uint256 spendingPubKeyX,
        uint256 spendingPubKeyY,
        uint256 viewingPubKeyX,
        uint256 viewingPubKeyY
        )
    {
        // Fetch the raw spending and viewing keys from the registry.
        (bytes memory spendingPubKey, bytes memory viewingPubKey) = REGISTRY.stealthKeys(registrant, address(this));

        // Parse the keys.
        assembly {
            spendingPubKeyX := mload(add(spendingPubKey, 0x20))
            spendingPubKeyY := mload(add(spendingPubKey, 0x40))
            viewingPubKeyX := mload(add(viewingPubKey, 0x20))
            viewingPubKeyY := mload(add(viewingPubKey, 0x40))
        }
    }

    /// @notice Sample implementation for generating stealth addresses for the secp256k1 curve.
    function generateStealthAddress(address registrant, bytes memory ephemeralPrivKey)
        external
        view
        returns (
            address stealthAddress,
            bytes memory ephemeralPubKey,
            bytes memory sharedSecret,
            bytes32 viewTag
        )
    {
        // Get the ephemeral public key from the private key.
        ephemeralPubKey = EllipticCurve.ecMul(ephemeralPrivKey, G);

        // Get user's parsed public keys.
        (
            uint256 spendingPubKeyX,
            uint256 spendingPubKeyY,
            uint256 viewingPubKeyX,
            uint256 viewingPubKeyY
        ) = stealthKeys(registrant, address(this));

        // Generate shared secret from sender's private key and recipient's viewing key.
        sharedSecret = EllipticCurve.ecMul(ephemeralPrivKey, viewingPubKeyX, viewingPubKeyY);
        bytes32 sharedSecretHash = keccak256(sharedSecret);

        // Generate view tag for enabling faster parsing for the recipient
        viewTag = sharedSecretHash[0:12];

        // Generate a point from the hash of the shared secret
        bytes memory sharedSecretPoint = EllipticCurve.ecMul(sharedSecret, G);

        // Generate sender's public key from their ephemeral private key.
        bytes memory stealthPubKey = EllipticCurve.ecAdd(spendingPubKeyX, spendingPubKeyY, sharedSecretPoint);

        // Compute stealth address from the stealth public key.
        stealthAddress = pubkeyToAddress(stealthPubKey);
    }
}