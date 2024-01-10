/// Listen to the kids, bro

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

/// @title Bonding Curve
/// @author neuroswish
/// @notice Bonding curve functions governing the exchange of continuous tokens

import "./Power.sol";

contract BondingCurve is Power {

    // ======== Storage ========

    uint256 public constant maxRatio = 1000000; // Maximum reserve ratio

    // ======== Errors ========

	/// @notice Thrown when supply input is invalid
	error InvalidSupply();

	/// @notice Thrown when pool balance input is invalid
	error InvalidPoolBalance();

    // ======== Functions ========

    /// @notice Calculate tokens received given ETH input
	/// @param _supply Token supply in circulation
	/// @param _poolBalance ETH pool balance
	/// @param _reserveRatio Reserve ratio
    /// @param _price ETH sent to contract in exchange for tokens
	/// @return Tokens
    function calculatePurchaseReturn(
        uint256 _supply,
        uint256 _poolBalance,
        uint256 _reserveRatio,
        uint256 _price
    ) public view returns (uint256) {
        if (_supply < 0) revert InvalidSupply();
        if (_poolBalance < 0) revert InvalidPoolBalance();
        (uint256 result, uint8 precision) = power(
            (_price + _poolBalance),
            _poolBalance,
            _reserveRatio,
            maxRatio
        );
        uint256 temp = (_supply * result) >> precision;
        return (temp - _supply);
    }

    /// @notice Calculate ETH amount needed to purchase specified amount of tokens
	/// @param _supply Token supply in circulation
	/// @param _poolBalance ETH pool balance
	/// @param _reserveRatio Reserve ratio
    /// @param _tokens Specified amount of tokens to purchase
	/// @return ETH
    function calculatePurchasePrice(
        uint256 _supply,
        uint256 _poolBalance,
        uint256 _reserveRatio,
        uint256 _tokens
    ) public view returns (uint256) {
        if (_supply < 0) revert InvalidSupply();
        if (_poolBalance < 0) revert InvalidPoolBalance();
        (uint256 result, uint8 precision) = power(
            (_tokens + _supply),
            _supply,
            maxRatio,
            _reserveRatio
        );
        uint256 temp = (_poolBalance * result) >> precision;
        return (temp - _poolBalance);
    }

    /// @notice Calculate ETH received given token input
	/// @param _supply Token supply in circulation
	/// @param _poolBalance ETH pool balance
	/// @param _reserveRatio Reserve ratio
    /// @param _tokens Tokens sent to contract in exchange for ETH
	/// @return ETH
    function calculateSaleReturn(
        uint256 _supply,
        uint256 _poolBalance,
        uint256 _reserveRatio,
        uint256 _tokens
    ) public view returns (uint256) {
        if (_supply < 0) revert InvalidSupply();
        if (_poolBalance < 0) revert InvalidPoolBalance();
        if (_tokens == _supply) {
            return _poolBalance;
        }
        (uint256 result, uint8 precision) = power(
            _supply,
            (_supply - _tokens),
            maxRatio,
            _reserveRatio
        );
        return ((_poolBalance * result) - (_poolBalance << precision)) / result;
    }

    /// @notice Calculate token amount needed to sell to receive specified amount of ETH
	/// @param _supply Token supply in circulation
	/// @param _poolBalance ETH pool balance
	/// @param _reserveRatio Reserve ratio
    /// @param _price Specified amount of ETH to receive
	/// @return Tokens
    function calculateSalePrice(
        uint256 _supply,
        uint256 _poolBalance,
        uint256 _reserveRatio,
        uint256 _price
    ) public view returns (uint256) {
        if (_supply < 0) revert InvalidSupply();
        if (_poolBalance < 0) revert InvalidPoolBalance();
        if (_price == _poolBalance) {
            return _supply;
        }
        (uint256 result, uint8 precision) = power(
            _poolBalance,
            (_poolBalance - _price),
            _reserveRatio,
            maxRatio
        );

        return ((_supply * result) - (_supply << precision)) / result;

    }

    /// @notice Calculate tokens received given ETH input when initializing supply
	/// @param _price ETH sent to contract
	/// @param _reserveRatio Reserve ratio
    /// @param _slopeInit Initial slope value to determine price curve
	/// @return Tokens
    function calculateInitializationReturn(uint256 _price, uint256 _reserveRatio, uint256 _slopeInit)
        public
        view
        returns (uint256)
    {
        if (_reserveRatio == maxRatio) {
            return (_price * _slopeInit);
        }
        (uint256 temp, uint256 precision) = powerInitial(
            (_price * _slopeInit),
            _reserveRatio,
            maxRatio,
            _reserveRatio,
            maxRatio
        );
        return (temp >> precision);
    }

    /// @notice Calculate ETH needed to purchase specified tokens when initializing supply
	/// @param _tokens Specified amount of tokens to purchase
	/// @param _reserveRatio Reserve ratio
    /// @param _slopeInit Initial slope value to determine price curve
	/// @return ETH
    function calculateInitializationPrice(uint256 _tokens, uint256 _reserveRatio, uint256 _slopeInit)
        public
        view
        returns (uint256)
    {
        if (_reserveRatio == maxRatio) {
            return (_tokens / _slopeInit);
        }
        (uint256 result, uint8 precision) = power(
            _tokens,
            (10**3),
            maxRatio,
            _reserveRatio
        );
        uint256 temp = result >> precision;
        return (temp * _reserveRatio) / maxRatio;
    }
}