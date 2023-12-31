// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import "./ICloneableV2.sol";
import "./ICloneableFactoryV2.sol";
import "./DeployerDiscoverableMetaV1.sol";
import "./Clones.sol";

/// Thrown when an implementation has zero code size which is always a mistake.
error ZeroImplementationCodeSize();

/// Thrown when initialization fails.
error InitializationFailed();

/// @dev Expected hash of the clone factory rain metadata.
bytes32 constant CLONE_FACTORY_META_HASH = bytes32(0x1efc6b18f7f4aa4266a7801e1b611be09f1977d4e1a6c3c5c17ac27abf81027e);

/// @title CloneFactory
/// @notice A fairly minimal implementation of `ICloneableFactoryV2` and
/// `DeployerDiscoverableMetaV1` that uses Open Zeppelin `Clones` to create
/// EIP1167 clones of a reference bytecode. The reference bytecode MUST implement
/// `ICloneableV2`.
contract CloneFactory is ICloneableFactoryV2, DeployerDiscoverableMetaV1 {
    constructor(DeployerDiscoverableMetaV1ConstructionConfig memory config)
        DeployerDiscoverableMetaV1(CLONE_FACTORY_META_HASH, config)
    {}

    /// @inheritdoc ICloneableFactoryV2
    function clone(address implementation, bytes calldata data) external returns (address) {
        // Explicitly check that the implementation has code. This is a common
        // mistake that will cause the clone to fail. Notably this catches the
        // case of address(0). This check is not strictly necessary as a zero
        // sized implementation will fail to initialize the child, but it gives
        // a better error message.
        if (implementation.code.length == 0) {
            revert ZeroImplementationCodeSize();
        }
        // Standard Open Zeppelin clone here.
        address child = Clones.clone(implementation);
        // NewClone does NOT include the data passed to initialize.
        // The implementation is responsible for emitting an event if it wants.
        emit NewClone(msg.sender, implementation, child);
        // Checking the return value of initialize is mandatory as per
        // ICloneableFactoryV2.
        if (ICloneableV2(child).initialize(data) != ICLONEABLE_V2_SUCCESS) {
            revert InitializationFailed();
        }
        return child;
    }
}
