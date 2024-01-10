// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IEuler.sol";

interface IEulerMarkets {
    /// @notice Create an Euler pool and associated EToken and DToken addresses.
    /// @param underlying The address of an ERC20-compliant token. There must be an initialised uniswap3 pool for the underlying/reference asset pair.
    /// @return The created EToken, or the existing EToken if already activated.
    function activateMarket(address underlying) external returns (address);

    /// @notice Create a pToken and activate it on Euler. pTokens are protected wrappers around assets that prevent borrowing.
    /// @param underlying The address of an ERC20-compliant token. There must already be an activated market on Euler for this underlying, and it must have a non-zero collateral factor.
    /// @return The created pToken, or an existing one if already activated.
    function activatePToken(address underlying) external returns (address);

    /// @notice Given an underlying, lookup the associated EToken
    /// @param underlying Token address
    /// @return EToken address, or address(0) if not activated
    function underlyingToEToken(address underlying) external view returns (address);

    /// @notice Given an underlying, lookup the associated DToken
    /// @param underlying Token address
    /// @return DToken address, or address(0) if not activated
    function underlyingToDToken(address underlying) external view returns (address);

    /// @notice Given an underlying, lookup the associated PToken
    /// @param underlying Token address
    /// @return PToken address, or address(0) if it doesn't exist
    function underlyingToPToken(address underlying) external view returns (address);

    /// @notice Looks up the Euler-related configuration for a token, and resolves all default-value placeholders to their currently configured values.
    /// @param underlying Token address
    /// @return Configuration struct
    function underlyingToAssetConfig(address underlying) external view returns (IEuler.AssetConfig memory);

    /// @notice Looks up the Euler-related configuration for a token, and returns it unresolved (with default-value placeholders)
    /// @param underlying Token address
    /// @return config Configuration struct
    function underlyingToAssetConfigUnresolved(address underlying) external view returns (IEuler.AssetConfig memory config);

    /// @notice Given an EToken address, looks up the associated underlying
    /// @param eToken EToken address
    /// @return underlying Token address
    function eTokenToUnderlying(address eToken) external view returns (address underlying);

    /// @notice Given an EToken address, looks up the associated DToken
    /// @param eToken EToken address
    /// @return dTokenAddr DToken address
    function eTokenToDToken(address eToken) external view returns (address dTokenAddr);

    /// @notice Looks up an asset's currently configured interest rate model
    /// @param underlying Token address
    /// @return Module ID that represents the interest rate model (IRM)
    function interestRateModel(address underlying) external view returns (uint);

    /// @notice Retrieves the current interest rate for an asset
    /// @param underlying Token address
    /// @return The interest rate in yield-per-second, scaled by 10**27
    function interestRate(address underlying) external view returns (int96);

    /// @notice Retrieves the current interest rate accumulator for an asset
    /// @param underlying Token address
    /// @return An opaque accumulator that increases as interest is accrued
    function interestAccumulator(address underlying) external view returns (uint);

    /// @notice Retrieves the reserve fee in effect for an asset
    /// @param underlying Token address
    /// @return Amount of interest that is redirected to the reserves, as a fraction scaled by RESERVE_FEE_SCALE (4e9)
    function reserveFee(address underlying) external view returns (uint32);

    /// @notice Retrieves the pricing config for an asset
    /// @param underlying Token address
    /// @return pricingType (1=pegged, 2=uniswap3, 3=forwarded)
    /// @return pricingParameters If uniswap3 pricingType then this represents the uniswap pool fee used, otherwise unused
    /// @return pricingForwarded If forwarded pricingType then this is the address prices are forwarded to, otherwise address(0)
    function getPricingConfig(address underlying) external view returns (uint16 pricingType, uint32 pricingParameters, address pricingForwarded);

    /// @notice Retrieves the list of entered markets for an account (assets enabled for collateral or borrowing)
    /// @param account User account
    /// @return List of underlying token addresses
    function getEnteredMarkets(address account) external view returns (address[] memory);

    /// @notice Add an asset to the entered market list, or do nothing if already entered
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param newMarket Underlying token address
    function enterMarket(uint subAccountId, address newMarket) external;

    /// @notice Remove an asset from the entered market list, or do nothing if not already present
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param oldMarket Underlying token address
    function exitMarket(uint subAccountId, address oldMarket) external;
}
