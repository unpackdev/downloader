// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @title IRebalancerCommon
/// @notice Defines a minimal interface that all Rebalancer implementations must support. The
/// deployment process relies on these functions. 

interface IRebalancerCommon {
    /// @notice Initializes the Rebalancer strategy with the initData.
    /// @param vault_ ICHI Vault the rebalancer will control. 
    /// @param owner_ Designated owner of the strategy. 
    /// @param initData Arbitrary data to pass to the initializer() function.
    /// @dev Be sure that all implementations employ the Initializable.initializer() modifier. 
    function initialize(address vault_, address owner_, bytes calldata initData) external;

    /// @notice Returns the address of the associated vault.
    /// @return vault The address of the vault.
    function vault() external view returns (address vault);
}