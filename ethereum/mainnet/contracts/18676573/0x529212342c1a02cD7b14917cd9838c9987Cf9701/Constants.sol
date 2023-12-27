/// SPDX-License-Identifier: BUSL-1.1

/// Copyright (C) 2023 Brahma.fi

pragma solidity 0.8.19;

/**
 * @title Constants
 * @author Brahma.fi
 * @notice Contains constants used by multiple contracts
 * @dev Inflates bytecode size by approximately 560 bytes on deployment, but saves gas on runtime
 */
abstract contract Constants {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        REGISTRIES                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    /// @notice Key to map address of ExecutorRegistry
    bytes32 internal constant _EXECUTOR_REGISTRY_HASH = bytes32(uint256(keccak256("console.core.ExecutorRegistry")) - 1);

    /// @notice Key to map address of WalletRegistry
    bytes32 internal constant _WALLET_REGISTRY_HASH = bytes32(uint256(keccak256("console.core.WalletRegistry")) - 1);

    /// @notice Key to map address of PolicyRegistry
    bytes32 internal constant _POLICY_REGISTRY_HASH = bytes32(uint256(keccak256("console.core.PolicyRegistry")) - 1);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          CORE                              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    /// @notice Key to map address of ExecutorPlugin
    bytes32 internal constant _EXECUTOR_PLUGIN_HASH = bytes32(uint256(keccak256("console.core.ExecutorPlugin")) - 1);

    /// @notice Key to map address of ConsoleFallbackHandler
    bytes32 internal constant _CONSOLE_FALLBACK_HANDLER_HASH =
        bytes32(uint256(keccak256("console.core.FallbackHandler")) - 1);

    /// @notice Key to map address of Safe FallbackHandler
    bytes32 internal constant _SAFE_FALLBACK_HANDLER_HASH = bytes32(uint256(keccak256("safe.FallbackHandler")) - 1);

    /// @notice Key to map address of Safe MultiSend
    bytes32 internal constant _SAFE_MULTI_SEND_HASH = bytes32(uint256(keccak256("safe.MultiSend")) - 1);

    /// @notice Key to map address of SafeProxyFactory
    bytes32 internal constant _SAFE_PROXY_FACTORY_HASH = bytes32(uint256(keccak256("safe.ProxyFactory")) - 1);

    /// @notice Key to map address of SafeSingleton
    bytes32 internal constant _SAFE_SINGLETON_HASH = bytes32(uint256(keccak256("safe.Singleton")) - 1);

    /// @notice Key to map address of PolicyValidator
    bytes32 internal constant _POLICY_VALIDATOR_HASH = bytes32(uint256(keccak256("console.core.PolicyValidator")) - 1);

    /// @notice Key to map address of SafeDeployer
    bytes32 internal constant _SAFE_DEPLOYER_HASH = bytes32(uint256(keccak256("console.core.SafeDeployer")) - 1);

    /// @notice Key to map address of SafeEnabler
    bytes32 internal constant _SAFE_ENABLER_HASH = bytes32(uint256(keccak256("console.core.SafeEnabler")) - 1);

    /// @notice Key to map address of SafeModerator
    bytes32 internal constant _SAFE_MODERATOR_HASH = bytes32(uint256(keccak256("console.core.SafeModerator")) - 1);

    /// @notice Key to map address of SafeModeratorOverridable
    bytes32 internal constant _SAFE_MODERATOR_OVERRIDABLE_HASH =
        bytes32(uint256(keccak256("console.core.SafeModeratorOverridable")) - 1);

    /// @notice Key to map address of TransactionValidator
    bytes32 internal constant _TRANSACTION_VALIDATOR_HASH =
        bytes32(uint256(keccak256("console.core.TransactionValidator")) - 1);

    /// @notice Key to map address of ConsoleOpBuilder
    bytes32 internal constant _CONSOLE_OP_BUILDER_HASH =
        bytes32(uint256(keccak256("console.core.ConsoleOpBuilder")) - 1);

    /// @notice Key to map address of ExecutionBlocker
    bytes32 internal constant _EXECUTION_BLOCKER_HASH = bytes32(uint256(keccak256("console.core.ExecutionBlocker")) - 1);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ROLES                             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Key to map address of Role PolicyAuthenticator
    bytes32 internal constant _POLICY_AUTHENTICATOR_HASH =
        bytes32(uint256(keccak256("console.roles.PolicyAuthenticator")) - 1);
}
