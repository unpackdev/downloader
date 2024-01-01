// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVault {
    /// @dev Removes an existing implementation address.
    function removeImplementation(address implementation_) external;

    /// @dev Adds new implementation address.
    function addImplementation(
        address implementation_,
        bytes4[] calldata sigs_
    ) external;

    /// @dev Sets new dummy-implementation.
    function setDummyImplementation(address newDummyImplementation_) external;

    /// @dev Sets new admin.
    function setAdmin(address newAdmin_) external;

    /// @notice Re-initializes the vault with new protocol IDs and risk ratios.
    function initializeV2() external;
}
