// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./Safe.sol";
import "./CheckSignatures.sol";

/// @title WaymontSafeAdvancedSigner
/// @notice Smart contract signer (via ERC-1271) to support a subgroup of signers (with their own threshold) attached as a signer on a Safe.
/// This contract is meant to be used with Safe contracts v1.4.1 (https://github.com/safe-global/safe-contracts/tree/v1.4.1). It can also be used with v1.4.0.
contract WaymontSafeAdvancedSigner is CheckSignatures {
    /// @dev Initializes the contract by setting the `Safe`, signers, and threshold.
    /// @param _safe The `Safe` of which this signer contract will be an owner.
    /// @param signers The signers underlying this signer contract.
    /// @param threshold The threshold required of signers underlying this signer contract.
    /// Can only be called once (because `setupOwners` can only be called once).
    function initialize(Safe _safe, address[] calldata signers, uint256 threshold) external {
        // Input validation
        require(_safe.isOwner(address(this)), "The Safe is not owned by this Waymont signer contract.");

        // Call `setupOwners` (can only be called once)
        setupOwners(signers, threshold);

        // Set the `Safe`
        safe = _safe;
    }

    /// @notice Signature validation function used by the `Safe` overlying this contract to validate underlying signers attached to this contract.
    /// @param _data Data signed in `_signature`.
    /// @param _signature Signature byte array associated with `_data`.
    /// @dev MUST return the bytes4 magic value 0x20c13b0b when function passes.
    /// MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5).
    /// MUST allow external calls.
    function isValidSignature(bytes calldata _data, bytes calldata _signature) external view returns (bytes4) {
        // Check signatures
        checkSignatures(keccak256(_data), _signature);

        // Return success by default
        return bytes4(0x20c13b0b);
    }
}
