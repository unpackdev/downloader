// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

/// @title ERC20 Facet Interface
/// @author Daniel <danieldegendev@gmail.com>
interface IERC20Facet {
    /// Minting an amount of tokens for a designated receiver
    /// @param _to receiver address of the token
    /// @param _amount receiving amount
    /// @notice This can only be executed by the MINTER_ROLE which will be bridge related contracts
    function mint(address _to, uint256 _amount) external;

    /// Burning an amount of tokens from a designated holder
    /// @param _from holder address to burn the tokens from
    /// @param _amount burnable amount
    function burn(address _from, uint256 _amount) external;

    /// @notice This enables the transfers of this tokens
    function enable() external;

    /// @notice This disables the transfers of this tokens
    function disable() external;

    /// Exclude an account from being charged on fees
    /// @param _account address to exclude
    function excludeAccountFromTax(address _account) external;

    /// Includes an account againt to pay fees
    /// @param _account address to include
    function includeAccountForTax(address _account) external;

    /// Sets the liquidity pool address
    /// @param _lp address of the liquidity pool of the token
    function setLP(address _lp) external;
}
