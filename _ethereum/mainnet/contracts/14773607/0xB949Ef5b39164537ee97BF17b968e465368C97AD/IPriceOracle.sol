// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import "./IVersion.sol";

interface IPriceOracleV2Events {
    // Emits each time new configurator is set up
    event NewPriceFeed(address indexed token, address indexed priceFeed);
}

interface IPriceOracleV2Exceptions {
    /// @dev throws if token has decimals > 18
    error TokenDecimalsGreater18ForbiddenException();

    /// @dev throws if pricefeed decimals != 8
    error PriceFeedDecimalsNotEqual8Exception();

    /// @dev throws if there is no connected priceFeed for provided token
    error PriceOracleNotExistsException();

    /// @dev throws if returned price equals 0
    error ZeroPriceException();
}

/// @title Price oracle interface
interface IPriceOracleV2 is
    IPriceOracleV2Events,
    IPriceOracleV2Exceptions,
    IVersion
{
    /// Converts one asset into USD (decimals = 8). Reverts if priceFeed doesn't exist
    /// @param amount Amount to convert
    /// @param token Token address converts from
    /// @return Amount converted to USD
    function convertToUSD(
        address creditAccount,
        uint256 amount,
        address token
    ) external view returns (uint256);

    /// @dev Converts one asset into another using price feed rate. Reverts if price feed doesn't exist
    /// @param amount Amount to convert
    /// @param token Token address converts from
    /// @return Amount converted to tokenTo asset
    function convertFromUSD(
        address creditAccount,
        uint256 amount,
        address token
    ) external view returns (uint256);

    /// @dev Converts one asset into another using rate. Reverts if price feed doesn't exist
    ///
    /// @param amount Amount to convert
    /// @param tokenFrom Token address converts from
    /// @param tokenTo Token address - converts to
    /// @return Amount converted to tokenTo asset
    function convert(
        address creditAccount,
        uint256 amount,
        address tokenFrom,
        address tokenTo
    ) external view returns (uint256);

    function fastCheck(
        address creditAccount,
        uint256 amountFrom,
        address tokenFrom,
        uint256 amountTo,
        address tokenTo
    ) external view returns (uint256 collateralFrom, uint256 collateralTo);

    /// @dev Returns pricefeed and priceFeed type
    function priceFeeds(address token)
        external view
        returns (address priceFeed);
}

interface IPriceOracleV2Ext {
    /// @dev Sets price feed if it doesn't exist. If price feed is already set, it changes nothing
    /// This logic is done to protect Gearbox from priceOracle attack
    /// when potential attacker can get access to price oracle, change them to fraud ones
    /// and then liquidate all funds
    /// @param token Address of token
    /// @param priceFeed Address of chainlink price feed token => Eth
    function addPriceFeed(address token, address priceFeed) external;
}
