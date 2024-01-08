// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

/// @title Asset Manager - The asset manager interface
/// @notice This contract is used to manage value asset
interface IAssetManager {

    /// @notice Total asset
    /// @dev This function calculates the net worth or AUM
    /// @return Total asset
    function assets()external view returns(uint256);

    /// @notice Withdraw asset
    /// @dev Only value contract can withdraw asset
    /// @param to Withdraw address
    /// @param amount Withdraw amount
    /// @param scale Withdraw percentage
    function withdraw(address to,uint256 amount,uint256 scale)external;

    /// @notice Withdraw underlying asset
    /// @dev Only value contract can withdraw underlying asset
    /// @param to Withdraw address
    /// @param scale Withdraw percentage
    function withdrawOfUnderlying(address to,uint256 scale)external;
}
