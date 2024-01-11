// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ILendingPool.sol";

interface IInitializableKToken {
    /**
    * @dev Emitted when an kToken is initialized
    * @param underlyingAsset The address of the underlying asset
    * @param pool The address of the associated lending pool
    * @param treasury The address of the treasury
    * @param kTokenDecimals the decimals of the underlying
    * @param kTokenName the name of the kToken
    * @param kTokenSymbol the symbol of the kToken
    * @param params A set of encoded parameters for additional initialization
    **/
    event Initialized(
        address indexed underlyingAsset,
        address indexed pool,
        address treasury,
        uint8 kTokenDecimals,
        string kTokenName,
        string kTokenSymbol,
        bytes params
    );

    /**
    * @dev Initializes the kToken
    * @param pool The address of the lending pool where this kToken will be used
    * @param treasury The address of the Kyoko treasury, receiving the fees on this kToken
    * @param underlyingAsset The address of the underlying asset of this kToken (E.g. USDT for kUSDT)
    * @param kTokenDecimals The decimals of the kToken, same as the underlying asset's
    * @param kTokenName The name of the kToken
    * @param kTokenSymbol The symbol of the kToken
    */
    function initialize(
        ILendingPool pool,
        address treasury,
        address underlyingAsset,
        uint8 kTokenDecimals,
        string calldata kTokenName,
        string calldata kTokenSymbol,
        bytes calldata params
    ) external;
}