// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./IERC165Upgradeable.sol";
import "./IAccessControl.sol";
import "./IERC20Metadata.sol";
import "./AggregatorV3Interface.sol";
import "./WadRayMath.sol";

import "./PriceOracleStorage.sol";
import "./Errors.sol";

import "./Constants.sol";
import "./IPriceOracle.sol";

contract PriceOracle is IPriceOracle, PriceOracleStorage {
    using WadRayMath for uint256;

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Modifier that checks if the caller has a specific role.
     * @param role The role identifier to check.
     */
    modifier onlyRole(bytes32 role) {
        _require(IAccessControl(registry).hasRole(role, msg.sender), Errors.FORBIDDEN.selector);
        _;
    }

    /**
     * @inheritdoc IPriceOracle
     */
    function initialize(address _registry, address _eth) external override initializer {
        _require(
            IERC165Upgradeable(_registry).supportsInterface(type(IAccessControl).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        registry = _registry;
        eth = _eth;
        __ERC165_init();
    }

    /**
     * @inheritdoc IPriceOracle
     */
    function increasePairPriceDrop(
        address _assetA,
        address _assetB,
        uint256 _pairPriceDrop
    ) external override onlyRole(EMERGENCY_ADMIN) {
        _require(
            _pairPriceDrop > pairPriceDrops[_assetA][_assetB] && _pairPriceDrop <= WadRayMath.WAD / 2,
            Errors.PAIR_PRICE_DROP_IS_NOT_CORRECT.selector
        );
        _setPairPriceDrop(_assetA, _assetB, _pairPriceDrop);
    }

    /**
     * @inheritdoc IPriceOracle
     */
    function setPairPriceDrop(
        address _assetA,
        address _assetB,
        uint256 _pairPriceDrop
    ) external override onlyRole(SMALL_TIMELOCK_ADMIN) {
        _require(_pairPriceDrop > 0 && _pairPriceDrop < WadRayMath.WAD, Errors.PAIR_PRICE_DROP_IS_NOT_CORRECT.selector);
        _setPairPriceDrop(_assetA, _assetB, _pairPriceDrop);
    }

    /**
     * @inheritdoc IPriceOracle
     */
    function updatePriceDropFeed(
        address assetA,
        address assetB,
        address priceDropFeed
    ) external override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        _require(assetA != assetB, Errors.IDENTICAL_TOKEN_ADDRESSES.selector);
        oraclePriceDropFeeds[assetA][assetB] = priceDropFeed;
        emit PriceDropFeedUpdated(assetA, assetB, priceDropFeed);
    }

    /**
     * @inheritdoc IPriceOracle
     */
    function updatePriceFeed(
        address assetA,
        address assetB,
        address priceFeed
    ) external override onlyRole(BIG_TIMELOCK_ADMIN) {
        _require(assetA != assetB, Errors.IDENTICAL_TOKEN_ADDRESSES.selector);
        chainLinkPriceFeeds[assetA][assetB] = priceFeed;
        emit PriceFeedUpdated(assetA, assetB, priceFeed);
    }

    /**
     * @inheritdoc IPriceOracle
     */
    function getExchangeRate(address assetA, address assetB) external view override returns (uint256, bool) {
        address priceFeed = chainLinkPriceFeeds[assetA][assetB];
        bool isForward = true;

        if (priceFeed == address(0)) {
            priceFeed = chainLinkPriceFeeds[assetB][assetA];
            if (priceFeed == address(0)) {
                (address basePriceFeed, address quotePriceFeed) = getPriceFeedsPair(assetA, assetB);

                (, int256 basePrice, , , ) = AggregatorV3Interface(basePriceFeed).latestRoundData();
                (, int256 quotePrice, , , ) = AggregatorV3Interface(quotePriceFeed).latestRoundData();

                _require(basePrice > 0 && quotePrice > 0, Errors.ZERO_EXCHANGE_RATE.selector);
                //the return value will always be 18 decimals if the basePrice and quotePrice have the same decimals
                return (uint256(basePrice).wdiv(uint256(quotePrice)), true);
            }
            isForward = false;
        }

        (, int256 answer, , , ) = AggregatorV3Interface(priceFeed).latestRoundData();
        _require(answer > 0, Errors.ZERO_EXCHANGE_RATE.selector);

        uint256 answerDecimals = AggregatorV3Interface(priceFeed).decimals();
        return ((uint256(answer) * 10 ** (18 - answerDecimals)), isForward);
    }

    /**
     * @inheritdoc IPriceOracle
     */
    function getDirectPriceFeed(address assetA, address assetB) external view override returns (address) {
        _require(assetA != assetB, Errors.IDENTICAL_TOKEN_ADDRESSES.selector);
        address priceFeed = chainLinkPriceFeeds[assetA][assetB];
        _require(priceFeed != address(0), Errors.NO_PRICEFEED_FOUND.selector);
        return priceFeed;
    }

    /**
     * @inheritdoc IPriceOracle
     */
    function getPairPriceDrop(address _assetA, address _assetB) external view override returns (uint256 priceDrop) {
        uint256 oraclePairPriceDrop = getOraclePriceDrop(_assetA, _assetB);
        uint256 pairPriceDrop = pairPriceDrops[_assetA][_assetB];
        priceDrop = pairPriceDrop > oraclePairPriceDrop ? pairPriceDrop : oraclePairPriceDrop;
        if (priceDrop > WadRayMath.WAD) return WadRayMath.WAD;
        return priceDrop;
    }

    /**
     * @inheritdoc IPriceOracle
     */
    function getOraclePriceDropFeed(address assetA, address assetB) external view override returns (address) {
        _require(assetA != assetB, Errors.IDENTICAL_TOKEN_ADDRESSES.selector);
        address priceDropFeed = oraclePriceDropFeeds[assetA][assetB];
        _require(priceDropFeed != address(0), Errors.NO_PRICE_DROP_FEED_FOUND.selector);
        return priceDropFeed;
    }

    /**
     * @inheritdoc IPriceOracle
     */
    function setGasPriceFeed(address priceFeed) public override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        gasPriceFeed = priceFeed;
        emit GasPriceFeedChanged(priceFeed);
    }

    /**
     * @inheritdoc IPriceOracle
     */
    function getOraclePriceDrop(address assetA, address assetB) public view override returns (uint256) {
        address priceDropFeed = oraclePriceDropFeeds[assetA][assetB];
        if (priceDropFeed == address(0)) return 0;
        (, int256 answer, , , ) = AggregatorV3Interface(priceDropFeed).latestRoundData();
        uint256 answerDecimals = AggregatorV3Interface(priceDropFeed).decimals();
        return (uint256(answer) * 10 ** (18 - answerDecimals));
    }

    /**
     * @inheritdoc IPriceOracle
     */
    function getPriceFeedsPair(
        address baseAsset,
        address quoteAsset
    ) public view override returns (address basePriceFeed, address quotePriceFeed) {
        _require(baseAsset != quoteAsset, Errors.IDENTICAL_TOKEN_ADDRESSES.selector);
        basePriceFeed = chainLinkPriceFeeds[baseAsset][USD];
        quotePriceFeed = chainLinkPriceFeeds[quoteAsset][USD];

        if (basePriceFeed == address(0) || quotePriceFeed == address(0)) {
            basePriceFeed = chainLinkPriceFeeds[baseAsset][eth];
            quotePriceFeed = chainLinkPriceFeeds[quoteAsset][eth];
            _require(basePriceFeed != address(0) && quotePriceFeed != address(0), Errors.NO_PRICEFEED_FOUND.selector);
        }
    }

    /**
     * @inheritdoc IPriceOracle
     */
    function getGasPrice() public view override returns (int256 price) {
        if (gasPriceFeed != address(0)) (, price, , , ) = AggregatorV3Interface(gasPriceFeed).latestRoundData();
    }

    /**
     * @notice Interface checker
     * @param _interfaceId The interface id to check
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IPriceOracle).interfaceId || super.supportsInterface(_interfaceId);
    }

    /**
     * @notice Sets the priceDrop for a pair of assets.
     * @param _assetA The address of the first asset in the pair.
     * @param _assetB The address of the second asset in the pair.
     * @param _pairPriceDrop The priceDrop value in WAD format to be set for the pair.
     */
    function _setPairPriceDrop(address _assetA, address _assetB, uint256 _pairPriceDrop) internal {
        _require(_assetA != address(0) && _assetB != address(0), Errors.ASSET_ADDRESS_NOT_SUPPORTED.selector);
        _require(_assetA != _assetB, Errors.IDENTICAL_ASSET_ADDRESSES.selector);
        pairPriceDrops[_assetA][_assetB] = _pairPriceDrop;
        emit PairPriceDropChanged(_assetA, _assetB, _pairPriceDrop);
    }
}
