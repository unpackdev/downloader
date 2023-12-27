// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./Clones.sol";

import "./Safe.sol";

import "./WaymontSafePolicyGuardianSigner.sol";
import "./WaymontSafeAdvancedSigner.sol";
import "./WaymontSafeTimelockedRecoveryModule.sol";

/// @title WaymontSafeFactory
/// @notice Creates EIP-1167 minimal proxy contract clones of `WaymontSafeAdvancedSigner` and `WaymontSafeTimelockedRecoveryModule`.
/// These contracts are meant to be used with Safe contracts v1.4.1 (https://github.com/safe-global/safe-contracts/tree/v1.4.1). It can also be used with v1.4.0.
/// @dev Using the Safe Singleton Factory is recommended method of deployment of this factory: https://github.com/safe-global/safe-singleton-factory
contract WaymontSafeFactory {
    /// @notice `WaymontSafePolicyGuardianSigner` contract.
    WaymontSafePolicyGuardianSigner public immutable policyGuardianSigner;

    /// @dev `WaymontSafeAdvancedSigner` implementation/logic contract address.
    address public immutable advancedSignerImplementation;

    /// @dev `WaymontSafeTimelockedRecoveryModule` implementation/logic contract address.
    address public immutable timelockedRecoveryModuleImplementation;

    /// @dev Constructor to initialize the factory by deploying the 3 other Waymont contracts.
    constructor(address _policyGuardianManager) {
        policyGuardianSigner = new WaymontSafePolicyGuardianSigner(_policyGuardianManager);
        advancedSignerImplementation = address(new WaymontSafeAdvancedSigner());
        timelockedRecoveryModuleImplementation = address(new WaymontSafeTimelockedRecoveryModule());
    }

    /// @notice Deploys a (non-upgradeable) minimal proxy contract over `WaymontSafeAdvancedSigner`.
    /// @dev See `WaymontSafeAdvancedSigner` for other params.
    /// @param deploymentNonce The unique nonce for the deployed signer contract. If the contract address of the `WaymontSafeFactory` and the `WaymontSafeAdvancedSigner` implementation is the same across each chain (which it will be if the same private key deploys them with the same nonces), then the contract addresses of the `WaymontSafeAdvancedSigner` instances created will also be the same across all chains according to the combination of initialization parameters (`safe`, `signers`, `threshold`, and `deploymentNonce`).
    /// @return `WaymontSafeAdvancedSigner` interface for the deployed proxy.
    function createAdvancedSigner(
        Safe safe,
        address[] calldata signers,
        uint256 threshold,
        uint256 deploymentNonce
    ) external returns (WaymontSafeAdvancedSigner) {
        WaymontSafeAdvancedSigner instance;
        {
            bytes32 salt = keccak256(abi.encode(safe, signers, threshold, deploymentNonce));
            instance = WaymontSafeAdvancedSigner(payable(Clones.cloneDeterministic(advancedSignerImplementation, salt)));
        }
        instance.initialize(safe, signers, threshold);
        return instance;
    }

    /// @notice Deploys a (non-upgradeable) minimal proxy contract over `WaymontSafeTimelockedRecoveryModule`.
    /// @dev See `WaymontSafeTimelockedRecoveryModule` for other params.
    /// @param deploymentNonce The unique nonce for the deployed signer contract. If the contract address of the `WaymontSafeFactory` and the `WaymontSafeTimelockedRecoveryModule` implementation is the same across each chain (which it will be if the same private key deploys them with the same nonces), then the contract addresses of the `WaymontSafeTimelockedRecoveryModule` instances created will also be the same across all chains according to the combination of initialization parameters (`safe`, `signers`, `threshold`, `signingTimelock`, `requirePolicyGuardian`, and `deploymentNonce`).
    /// @return `WaymontSafeTimelockedRecoveryModule` interface for the deployed proxy.
    function createTimelockedRecoveryModule(
        Safe safe,
        address[] calldata signers,
        uint256 threshold,
        uint256 signingTimelock,
        bool requirePolicyGuardian,
        uint256 deploymentNonce
    ) external returns (WaymontSafeTimelockedRecoveryModule) {
        WaymontSafeTimelockedRecoveryModule instance;
        {
            bytes32 salt = keccak256(abi.encode(safe, signers, threshold, signingTimelock, requirePolicyGuardian, deploymentNonce));
            instance = WaymontSafeTimelockedRecoveryModule(payable(Clones.cloneDeterministic(timelockedRecoveryModuleImplementation, salt)));
        }
        instance.initialize(safe, signers, threshold, signingTimelock, requirePolicyGuardian ? policyGuardianSigner : WaymontSafePolicyGuardianSigner(address(0)));
        return instance;
    }

    /// @dev Event emitted when a signature is queued on a `Safe`.
    /// Useful for sending security notifications to `Safe` owners if the policy guardian cannot find record of itself sending the transaction hash associated with a `SignatureQueued` event.
    /// WARNING: The function that emits this event is not access-gated (in the interest of reducing gas costs and avoiding unnecessary smart contract complexity), so make sure to check underlying `Safe` addresses for validity. If events are spammed on a chain and `eth_getLogs` times out, `Safe`s can be checked individually (in descending order of net worth on that chain).
    event SignatureQueued(Safe indexed safe, WaymontSafeTimelockedRecoveryModule indexed timelockedRecoveryModule, address indexed signer, bytes32 signedDataHash);

    /// @dev Emits a `SignatureQueued` event.
    function emitSignatureQueued(address signer, bytes32 signedDataHash) external {
        WaymontSafeTimelockedRecoveryModule timelockedRecoveryModule = WaymontSafeTimelockedRecoveryModule(msg.sender);
        Safe safe = timelockedRecoveryModule.safe();
        require(safe.isModuleEnabled(address(timelockedRecoveryModule)), "The Safe does not have this Waymont module enabled.");
        emit SignatureQueued(safe, timelockedRecoveryModule, signer, signedDataHash);
    }
}
