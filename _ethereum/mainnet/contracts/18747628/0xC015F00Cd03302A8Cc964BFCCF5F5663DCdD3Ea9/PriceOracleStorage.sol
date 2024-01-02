// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./ERC165Upgradeable.sol";

import "./IPriceOracleStorage.sol";

abstract contract PriceOracleStorage is IPriceOracleStorage, ERC165Upgradeable {
    address public override registry;
    address public override eth;
    address public override gasPriceFeed;

    // PriceDrop of asset A relative to asset B
    mapping(address => mapping(address => uint256)) public override pairPriceDrops;

    /**
     * @notice The mapping stores priceDrop feeds adresses associated with the asset pair.
     * @dev 'The address of the first asset in the pair' -> ' The address of the second asset in the pair' -> 'priceDrop feed address'
     */
    mapping(address => mapping(address => address)) internal oraclePriceDropFeeds;

    /**
     * @notice The mapping stores price feeds for currency pairs.
     * @dev 'base currency address' -> 'quote currency address' -> 'price feed address'
     */
    mapping(address => mapping(address => address)) internal chainLinkPriceFeeds;
}
