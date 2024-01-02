// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./CurrencyControllerStorage.sol";

/**
 * @dev Currency Controller contract is responsible for managing supported
 * currencies in Secured Finance Protocol
 *
 * Contract links new currencies to ETH Chainlink price feeds, without existing price feed
 * contract owner is not able to add a new currency into the protocol
 */
interface ICurrencyController {
    error InvalidCurrency();
    error InvalidHaircut();
    error InvalidPriceFeed();
    error InvalidDecimals(address priceFeed, uint8 decimals);
    error InvalidPriceFeedInputs();
    error StalePriceFeed(
        address priceFeed,
        uint256 heartbeat,
        uint256 updatedAt,
        uint256 blockTimestamp
    );

    event CurrencyAdded(bytes32 indexed ccy, uint256 haircut);
    event CurrencyRemoved(bytes32 indexed ccy);

    event HaircutUpdated(bytes32 indexed ccy, uint256 haircut);

    event PriceFeedUpdated(bytes32 ccy, uint256 decimals, address[] indexed priceFeeds);

    function convert(
        bytes32 _fromCcy,
        bytes32 _toCcy,
        uint256 _amount
    ) external view returns (uint256 amount);

    function convert(
        bytes32 _fromCcy,
        bytes32 _toCcy,
        uint256[] calldata _amounts
    ) external view returns (uint256[] memory amounts);

    function convertToBaseCurrency(
        bytes32 _ccy,
        uint256 _amount
    ) external view returns (uint256 amount);

    function convertToBaseCurrency(
        bytes32 _ccy,
        int256 _amount
    ) external view returns (int256 amount);

    function convertToBaseCurrency(
        bytes32 _ccy,
        uint256[] calldata _amounts
    ) external view returns (uint256[] memory amounts);

    function convertFromBaseCurrency(
        bytes32 _ccy,
        uint256 _amountETH
    ) external view returns (uint256 amount);

    function convertFromBaseCurrency(
        bytes32 _ccy,
        uint256[] calldata _amounts
    ) external view returns (uint256[] memory amounts);

    function getDecimals(bytes32) external view returns (uint8);

    function getCurrencies() external view returns (bytes32[] memory);

    function getHaircut(bytes32 _ccy) external view returns (uint256);

    function getPriceFeed(bytes32 _ccy) external view returns (PriceFeed memory);

    function getLastPrice(bytes32 _ccy) external view returns (int256 price);

    function getAggregatedLastPrice(bytes32 _ccy) external view returns (int256);

    function currencyExists(bytes32 _ccy) external view returns (bool);

    function updatePriceFeed(
        bytes32 _ccy,
        uint8 _decimals,
        address[] calldata _priceFeeds,
        uint256[] calldata _heartbeats
    ) external;

    function addCurrency(
        bytes32 _ccy,
        uint8 _decimals,
        uint256 _haircut,
        address[] calldata _priceFeeds,
        uint256[] calldata _heartbeats
    ) external;

    function updateHaircut(bytes32 _ccy, uint256 _haircut) external;

    function removeCurrency(bytes32 _ccy) external;
}
