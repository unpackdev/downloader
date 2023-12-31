// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";

/// @title An interface for a custom ERC20 contract used in the bridge
interface IWrappedERC20 is IERC20Upgradeable {

    /// @notice Returns the name of the token
    /// @return The name of the token
    function name() external view returns(string memory);

    /// @notice Returns the symbol of the token
    /// @return The symbol of the token
    function symbol() external view returns(string memory);

    /// @notice Returns number of decimals of the token
    /// @return The number of decimals of the token
    function decimals() external view returns(uint8);

    /// @notice Returns the address of the bridge contract
    /// @return The address of the bridge contract
    function bridge() external view returns(address);

    /// @notice Creates tokens and assigns them to account, increasing the total supply.
    /// @param to The receiver of tokens
    /// @param amount The amount of tokens to mint
    function mint(address to, uint256 amount) external;

    /// @notice Destroys tokens from account, reducing the total supply.
    /// @param from The address holding the tokens
    /// @param amount The amount of tokens to burn
    function burn(address from, uint256 amount) external;

    /// @notice Is emitted on every mint of the token
    event Mint(address indexed account, uint256 amount);
    
    /// @notice Is emitted on every burn of the token
    event Burn(address indexed account, uint256 amount);
}
