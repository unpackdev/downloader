// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IERC20MintBurnable is IERC20 {
    /// Mints tokens to a specific account.
    /// @dev Should be locked behind a permission.
    /// @param account The account that will receive the minted tokens.
    /// @param amount The amount of tokens to mint.
    function mint(address account, uint256 amount) external;

    /// Burns tokens from your account.
    /// @param amount The amount of tokens to burn.
    function burn(uint256 amount) external;
}
