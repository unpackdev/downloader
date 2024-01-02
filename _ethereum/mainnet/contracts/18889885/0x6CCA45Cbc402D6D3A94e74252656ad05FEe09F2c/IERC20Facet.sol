// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

/// @title ERC20 Facet Interface
/// @author Daniel <danieldegendev@gmail.com>
interface IERC20Facet {
    /// Minting an amount of tokens for a designated receiver
    /// @param _to receiver address of the token
    /// @param _amount receiving amount
    /// @return _success Returns true is operation succeeds
    /// @notice It allows to mint specified amount until the bridge supply cap is reached
    function mint(address _to, uint256 _amount) external returns (bool _success);

    /// Burning an amount of tokens from sender
    /// @param _amount burnable amount
    /// @return _success Returns true is operation succeeds
    /// @notice It allows to burn a bridge supply until its supply is 0, even if the cap is already set to 0
    function burn(uint256 _amount) external returns (bool _success);

    /// Burning an amount of tokens from a designated holder
    /// @param _from holder address to burn the tokens from
    /// @param _amount burnable amount
    /// @return _success Returns true is operation succeeds
    /// @notice It allows to burn a bridge supply until its supply is 0, even if the cap is already set to 0
    function burn(address _from, uint256 _amount) external returns (bool _success);

    /// Burning an amount of tokens from a designated holder
    /// @param _from holder address to burn the tokens from
    /// @param _amount burnable amount
    /// @return _success Returns true is operation succeeds
    /// @notice It allows to burn a bridge supply until its supply is 0, even if the cap is already set to 0
    function burnFrom(address _from, uint256 _amount) external returns (bool _success);

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

    /// Adds a liquidity pool address
    /// @param _lp address of the liquidity pool of the token
    function addLP(address _lp) external;

    /// Removes a liquidity pool address
    /// @param _lp address of the liquidity pool of the token
    function removeLP(address _lp) external;

    /// Returns the existence of an lp address
    /// @return _has has lp or not
    function hasLP(address _lp) external view returns (bool _has);

    /// Adds a buy fee based on a fee id
    /// @param _id fee id
    function addBuyFee(bytes32 _id) external;

    /// Adds a sell fee based on a fee id
    /// @param _id fee id
    function addSellFee(bytes32 _id) external;
}
