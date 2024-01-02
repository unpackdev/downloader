// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// dependencies
import "./AggregatorV3Interface.sol";
import "./EnumerableSet.sol";
import "./SafeCast.sol";
import "./Multicall.sol";
// interfaces
import "./ICurrencyController.sol";
// libraries
import "./Constants.sol";
import "./RoundingUint256.sol";
import "./RoundingInt256.sol";
// utils
import "./Ownable.sol";
import "./Proxyable.sol";
// storages
import "./CurrencyControllerStorage.sol";

/**
 * @notice Implements managing of the supported currencies in the protocol.
 *
 * This contract stores the currency settings and links the currency to the external price feeds.
 * It uses those settings and also has the functions to change prices to other currencies.
 */
contract CurrencyController is ICurrencyController, Ownable, Proxyable, Multicall {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using SafeCast for uint256;
    using SafeCast for int256;
    using RoundingUint256 for uint256;
    using RoundingInt256 for int256;

    uint256 public constant HEARTBEAT_BUFFER = 5 minutes;
    /// @dev Used for decimals of the base currency
    uint256 immutable BASE_CURRENCY_DECIMALS;

    /**
     * @notice Modifier to check if the currency is supported.
     * @param _ccy Currency name in bytes32
     */
    modifier onlySupportedCurrency(bytes32 _ccy) {
        if (!currencyExists(_ccy)) revert InvalidCurrency();
        _;
    }

    /**
     * @notice Contract constructor function.
     * @param _baseCurrencyDecimals The decimals of the base currency
     */
    constructor(uint256 _baseCurrencyDecimals) {
        BASE_CURRENCY_DECIMALS = _baseCurrencyDecimals;
    }

    /**
     * @notice Initializes the contract.
     * @dev Function is invoked by the proxy contract when the contract is added to the ProxyController.
     * @param _owner The address of the contract owner
     */
    function initialize(address _owner) public initializer onlyProxy {
        _transferOwnership(_owner);
    }

    /**
     * @notice Gets aggregated and cached decimals of the price feeds for the selected currency.
     * @param _ccy Currency name in bytes32
     */
    function getDecimals(bytes32 _ccy) external view override returns (uint8) {
        return Storage.slot().decimalsCaches[_ccy];
    }

    /**
     * @notice Gets all currencies.
     * @return The array of the currency
     */
    function getCurrencies() external view override returns (bytes32[] memory) {
        return Storage.slot().currencies.values();
    }

    /**
     * @notice Gets haircut ratio for the selected currency.
     * Haircut is used in bilateral netting cross-calculation.
     * @param _ccy Currency name in bytes32
     */
    function getHaircut(bytes32 _ccy) external view override returns (uint256) {
        return Storage.slot().haircuts[_ccy];
    }

    /**
     * @notice Gets price feed for the selected currency.
     * @param _ccy Currency name in bytes32
     */
    function getPriceFeed(bytes32 _ccy) external view override returns (PriceFeed memory) {
        return Storage.slot().priceFeeds[_ccy];
    }

    /**
     * @notice Gets if the selected currency is supported.
     * @param _ccy Currency name in bytes32
     * @return The boolean if the selected currency is supported or not
     */
    function currencyExists(bytes32 _ccy) public view override returns (bool) {
        return Storage.slot().currencies.contains(_ccy);
    }

    /**
     * @notice Adds new currency into the protocol and links with existing price feed.
     * @param _ccy Currency name in bytes32k
     * @param _decimals Currency decimals
     * @param _haircut Remaining ratio after haircut
     * @param _priceFeeds Array with the contract address of price feed
     * @param _heartbeats Array with the heartbeat of price feed
     */
    function addCurrency(
        bytes32 _ccy,
        uint8 _decimals,
        uint256 _haircut,
        address[] calldata _priceFeeds,
        uint256[] calldata _heartbeats
    ) public override onlyOwner {
        Storage.slot().currencies.add(_ccy);

        _updateHaircut(_ccy, _haircut);
        _updatePriceFeed(_ccy, _decimals, _priceFeeds, _heartbeats);

        emit CurrencyAdded(_ccy, _haircut);
    }

    /**
     * @notice Updates the flag indicating if the currency is supported in the protocol.
     * @param _ccy Currency name in bytes32
     */
    function removeCurrency(bytes32 _ccy) public override onlyOwner {
        Storage.slot().currencies.remove(_ccy);
        emit CurrencyRemoved(_ccy);
    }

    /**
     * @notice Updates the haircut ratio for supported currency
     * @param _ccy Currency name in bytes32
     * @param _haircut Remaining ratio after haircut
     */
    function updateHaircut(
        bytes32 _ccy,
        uint256 _haircut
    ) public override onlyOwner onlySupportedCurrency(_ccy) {
        _updateHaircut(_ccy, _haircut);
    }

    /**
     * @notice Update the price feed contract addresses.
     * @param _ccy Currency name in bytes32
     * @param _decimals Currency decimals
     * @param _priceFeeds Array with the contract address of price feed
     * @param _heartbeats Array with the heartbeat of price feed
     */
    function updatePriceFeed(
        bytes32 _ccy,
        uint8 _decimals,
        address[] calldata _priceFeeds,
        uint256[] calldata _heartbeats
    ) public override onlyOwner onlySupportedCurrency(_ccy) {
        _updatePriceFeed(_ccy, _decimals, _priceFeeds, _heartbeats);
    }

    /**
     * @notice Gets the last price of the selected currency in the base currency.
     * @param _ccy Currency name in bytes32
     * @return price The last price
     */
    function getLastPrice(bytes32 _ccy) public view override returns (int256 price) {
        price = _getAggregatedLastPrice(_ccy);
        PriceFeed memory priceFeeds = Storage.slot().priceFeeds[_ccy];

        for (uint256 i; i < priceFeeds.instances.length - 1; i++) {
            uint8 decimals = priceFeeds.instances[i].decimals();
            price = price.div((10 ** decimals).toInt256());
        }
    }

    /**
     * @notice Gets the last price of the selected currency in the base currency.
     * This price is returned in the aggregated decimals of all price feeds.
     * @param _ccy Currency name in bytes32
     * @return price The last price
     */
    function getAggregatedLastPrice(bytes32 _ccy) public view override returns (int256 price) {
        price = _getAggregatedLastPrice(_ccy);
    }

    /**
     * @notice Gets the converted amount of currency.
     * @param _fromCcy Currency to convert from
     * @param _toCcy Currency to convert to
     * @param _amount Amount to be converted
     * @return amount The converted amount
     */
    function convert(
        bytes32 _fromCcy,
        bytes32 _toCcy,
        uint256 _amount
    ) external view override returns (uint256 amount) {
        if (_fromCcy == _toCcy) return _amount;
        if (_amount == 0) return 0;

        int256 fromPrice = _getAggregatedLastPrice(_fromCcy);
        int256 toPrice = _getAggregatedLastPrice(_toCcy);

        amount = (_amount * uint256(fromPrice) * 10 ** Storage.slot().decimalsCaches[_toCcy]).div(
            10 ** Storage.slot().decimalsCaches[_fromCcy] * uint256(toPrice)
        );
    }

    /**
     * @notice Gets the converted amounts of currency.
     * @param _fromCcy Currency to convert from
     * @param _toCcy Currency to convert to
     * @param _amounts Amounts to be converted
     * @return amounts The converted amounts
     */
    function convert(
        bytes32 _fromCcy,
        bytes32 _toCcy,
        uint256[] calldata _amounts
    ) external view override returns (uint256[] memory amounts) {
        if (_fromCcy == _toCcy) return _amounts;

        int256 fromPrice = _getAggregatedLastPrice(_fromCcy);
        int256 toPrice = _getAggregatedLastPrice(_toCcy);
        uint256 toDecimals = Storage.slot().decimalsCaches[_toCcy];
        uint256 fromDecimals = Storage.slot().decimalsCaches[_fromCcy];
        amounts = new uint256[](_amounts.length);

        for (uint256 i; i < _amounts.length; i++) {
            if (_amounts[i] == 0) continue;

            amounts[i] = (_amounts[i] * uint256(fromPrice) * 10 ** toDecimals).div(
                10 ** fromDecimals * uint256(toPrice)
            );
        }
    }

    /**
     * @notice Gets the converted amount in the base currency.
     * @param _ccy Currency that has to be converted to the base currency
     * @param _amount Amount to be converted
     * @return amount The converted amount
     */
    function convertToBaseCurrency(
        bytes32 _ccy,
        uint256 _amount
    ) public view override returns (uint256 amount) {
        if (_amount == 0) return 0;

        amount = (_amount * _getAggregatedLastPrice(_ccy).toUint256()).div(
            10 ** Storage.slot().decimalsCaches[_ccy]
        );
    }

    /**
     * @notice Gets the converted amount in the base currency.
     * @param _ccy Currency that has to be converted to the base currency.
     * @param _amount Amount to be converted
     * @return amount The converted amount
     */
    function convertToBaseCurrency(
        bytes32 _ccy,
        int256 _amount
    ) external view override returns (int256 amount) {
        if (_amount == 0) return 0;

        amount = (_amount * _getAggregatedLastPrice(_ccy)).div(
            (10 ** Storage.slot().decimalsCaches[_ccy]).toInt256()
        );
    }

    /**
     * @notice Gets the converted amounts in the base currency.
     * @param _ccy Currency that has to be converted to the base currency.
     * @param _amounts Amounts to be converted
     * @return amounts The converted amounts
     */
    function convertToBaseCurrency(
        bytes32 _ccy,
        uint256[] calldata _amounts
    ) public view override returns (uint256[] memory amounts) {
        amounts = new uint256[](_amounts.length);
        uint256 price = _getAggregatedLastPrice(_ccy).toUint256();
        uint256 decimals = Storage.slot().decimalsCaches[_ccy];

        for (uint256 i; i < _amounts.length; i++) {
            if (_amounts[i] == 0) continue;
            amounts[i] = (_amounts[i] * price).div(10 ** decimals);
        }
    }

    /**
     * @notice Gets the converted amount to the selected currency from the base currency.
     * @param _ccy Currency that has to be converted from the base currency.
     * @param _amount Amount in the base currency to be converted
     * @return amount The converted amount
     */
    function convertFromBaseCurrency(
        bytes32 _ccy,
        uint256 _amount
    ) public view override returns (uint256 amount) {
        if (_amount == 0) return 0;

        amount = (_amount * 10 ** Storage.slot().decimalsCaches[_ccy]).div(
            _getAggregatedLastPrice(_ccy).toUint256()
        );
    }

    /**
     * @notice Gets the converted amounts to the selected currency from the base currency.
     * @param _ccy Currency that has to be converted to the base currency.
     * @param _amounts Amounts in the base currency to be converted
     * @return amounts The converted amounts
     */
    function convertFromBaseCurrency(
        bytes32 _ccy,
        uint256[] calldata _amounts
    ) public view override returns (uint256[] memory amounts) {
        amounts = new uint256[](_amounts.length);
        uint256 price = _getAggregatedLastPrice(_ccy).toUint256();
        uint256 decimals = Storage.slot().decimalsCaches[_ccy];

        for (uint256 i; i < _amounts.length; i++) {
            if (_amounts[i] == 0) continue;

            amounts[i] = (_amounts[i] * 10 ** decimals).div(price);
        }
    }

    function _getAggregatedLastPrice(bytes32 _ccy) internal view returns (int256 totalPrice) {
        PriceFeed memory priceFeeds = Storage.slot().priceFeeds[_ccy];
        totalPrice = 1;

        for (uint256 i; i < priceFeeds.instances.length; i++) {
            (, int256 price, , uint256 updatedAt, ) = priceFeeds.instances[i].latestRoundData();

            if (
                price <= 0 ||
                updatedAt < block.timestamp - priceFeeds.heartbeats[i] - HEARTBEAT_BUFFER
            ) {
                revert StalePriceFeed(
                    address(priceFeeds.instances[i]),
                    priceFeeds.heartbeats[i],
                    updatedAt,
                    block.timestamp
                );
            }
            totalPrice = totalPrice * price;
        }
    }

    function _updateHaircut(bytes32 _ccy, uint256 _haircut) internal {
        if (_haircut > Constants.PCT_DIGIT) revert InvalidHaircut();

        Storage.slot().haircuts[_ccy] = _haircut;

        emit HaircutUpdated(_ccy, _haircut);
    }

    function _updatePriceFeed(
        bytes32 _ccy,
        uint8 _decimals,
        address[] calldata _priceFeeds,
        uint256[] calldata _heartbeats
    ) internal {
        if (_priceFeeds.length == 0 || _priceFeeds.length != _heartbeats.length)
            revert InvalidPriceFeedInputs();

        AggregatorV3Interface[] memory priceFeeds = new AggregatorV3Interface[](_priceFeeds.length);

        for (uint256 i; i < _priceFeeds.length; i++) {
            priceFeeds[i] = AggregatorV3Interface(_priceFeeds[i]);

            uint8 decimals = priceFeeds[i].decimals();
            if (
                decimals > 18 || (i == _priceFeeds.length - 1 && decimals != BASE_CURRENCY_DECIMALS)
            ) revert InvalidDecimals(_priceFeeds[i], decimals);

            (, int256 price, , uint256 updatedAt, ) = priceFeeds[i].latestRoundData();
            if (price <= 0 || updatedAt < block.timestamp - _heartbeats[i] - HEARTBEAT_BUFFER)
                revert InvalidPriceFeed();
        }

        Storage.slot().priceFeeds[_ccy] = PriceFeed(priceFeeds, _heartbeats);
        Storage.slot().decimalsCaches[_ccy] = _decimals;

        emit PriceFeedUpdated(_ccy, _decimals, _priceFeeds);
    }
}
