// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// @dev This hash MUST be returned when an `ICloneableV2` is successfully
/// initialized.
bytes32 constant ICLONEABLE_V2_SUCCESS = keccak256("ICloneableV2.initialize");

/// @title ICloneableV2
/// @notice Interface for cloneable contracts that support initialization.
interface ICloneableV2 {
    /// Overloaded initialize function MUST revert with this error.
    error InitializeSignatureFn();

    /// Initialize is intended to work like constructors but for cloneable
    /// proxies. The `ICloneableV2` contract MUST ensure that initialize can NOT
    /// be called more than once. The `ICloneableV2` contract is designed to be
    /// deployed by an `ICloneableFactoryV2` but MUST NOT assume that it will be.
    /// It is possible for someone to directly deploy an `ICloneableV2` and fail
    /// to call initialize before other functions are called, and end users MAY
    /// NOT realise or know how to confirm a safe deployment state. The
    /// `ICloneableV2` MUST take appropriate measures to ensure that functions
    /// called before initialize are safe to do so, or revert.
    ///
    /// To be fully generic, `initilize` accepts `bytes` and so MUST ABI decode
    /// within the initialize function. This allows a single factory to service
    /// arbitrary cloneable proxies but also erases the type of the
    /// initialization config from the ABI. As tooling will inevitably require
    /// the ABI to be known, it is RECOMMENDED that the `ICloneableV2` contract
    /// implements a typed `initialize` function that overloads the generic
    /// `initialize(bytes)` function. This overloaded function MUST revert with
    /// `InitializeSignatureFn` always, so that it is NEVER accidentally called.
    /// This avoids complex and expensive delegate call style patterns where a
    /// typed overload has to call back to itself and preserve the sender,
    /// instead we force the caller to know the correct signature and call the
    /// correct function directly with encoded bytes.
    ///
    /// If initialization is successful the `ICloneableV2` MUST return the
    /// keccak256 hash of the string "ICloneableV2.initialize". This avoids false
    /// positives where a contract building a proxy, such as an
    /// `ICloneableFactoryV2`, may incorrectly believe that the clone has been
    /// initialized but the implementation doesn't support `ICloneableV2`.
    ///
    /// @dev The `ICloneableV2` interface is identical to `ICloneableV1` except
    /// that it returns a `bytes32` success hash.
    /// @param data The initialization data.
    /// @return success keccak256("ICloneableV2.initialize") if successful.
    function initialize(bytes calldata data) external returns (bytes32 success);
}
