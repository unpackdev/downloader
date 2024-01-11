//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./AccessControl.sol";
import "./AggregatorV2V3Interface.sol";
import "./IEurPriceFeed.sol";

interface IDecimals {
    function decimals() external view returns (uint8);
}

/**
 * @title EurPriceFeed
 * @author Protofire
 * @dev Contract module to retrieve EUR price per asset.
 *
 */
contract EurPriceFeed is IEurPriceFeed, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant FEEDS_MANAGER_ROLE = keccak256("FEEDS_MANAGER_ROLE");

    address public constant USD_DENOMINATION_ADDRESS = address(0);

    uint256 public constant DIGITS = 27;
    uint256 public constant ONE_BASE27 = 10**DIGITS;
    uint256 public constant RETURN_DIGITS_BASE18 = 18;

    /// @dev mapping between an asset and its feed and the denominations used by the feed.
    // If denomination is ZERO address, we asume the price is reported expreced in USD by the feed
    mapping(address => AssetFeed) public assetFeed;

    /// @dev EUR/USD feed. It returs how many USD is 1 EUR.
    address public eurUsdFeed;

    // AssetFeeds using ZERO address as denomination will be considered USD denominated.
    struct AssetFeed {
        address feed;
        address denomination;
    }

    /**
     * @dev Emitted when `eurUsdFeed` address is set.
     */
    event EurUsdFeedSet(address indexed newEurUsdFeed);

    /**
     * @dev Emitted when some asset is used as a denomination for another asset.
     */
    event NonStandardDenominationSet(address indexed denomination);

    /**
     * @dev Emitted when a feed address is set for an asset.
     */
    event AssetFeedSet(address indexed asset, address indexed feed);

    /**
     * @dev Sets the values for {eurUsdFeed}, {ethUsdFeed} and {assetUsdFeed}.
     *
     * Grants the contract deployer the default admin role.
     *
     */
    constructor(
        address _eurUsdFeed,
        address[] memory _assets,
        address[] memory _feeds,
        address[] memory _denominations
    ) {
        require(_eurUsdFeed != address(0), "eur/usd price feed is the zero address");
        eurUsdFeed = _eurUsdFeed;
        emit EurUsdFeedSet(_eurUsdFeed);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setAssetsFeeds(_assets, _feeds, _denominations);
    }

    /**
     * @dev Throws if called by some address with FEEDS_MANAGER_ROLE.
     */
    modifier onlyFeedsManager() {
        require(hasRole(FEEDS_MANAGER_ROLE, _msgSender()), "must have feeds manager role");
        _;
    }

    /**
     * @dev Grants FEEDS_MANAGER_ROLE to `_account`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setFeedsManager(address _account) external {
        grantRole(FEEDS_MANAGER_ROLE, _account);
    }

    /**
     * @dev Sets `_eurUsdFeed` as the new ERU/USD feed.
     *
     * Requirements:
     *
     * - the caller must have FEEDS_MANAGER_ROLE.
     * - `_eurUsdFeed` should not be the zero address.
     *
     * @param _eurUsdFeed The address of the new ERU/USD feed.
     */
    function setEurUsdFeed(address _eurUsdFeed) external onlyFeedsManager {
        require(_eurUsdFeed != address(0), "eur/usd price feed is the zero address");
        emit EurUsdFeedSet(_eurUsdFeed);
        eurUsdFeed = _eurUsdFeed;
    }

    /**
     * @dev Sets feed addresses for a given asset.
     *
     * Requirements:
     *
     * - the caller must have FEEDS_MANAGER_ROLE.
     * - `_asset` should not be the zero address .
     * - `_feed` should not be the zero address .
     * - `_denomination` should be zero address, if and only if, `_feed` reports prices in USD.
     * - `_denomination` should be an already registered assets (denominated in USD),
     * if and only if, `_feed` reports prices in any unit of account different from USD.
     * @param _asset Asset address.
     * @param _feed Asset/ETH price feed.
     */
    function setAssetFeed(
        address _asset,
        address _feed,
        address _denomination
    ) external override onlyFeedsManager {
        _setAssetFeed(_asset, _feed, _denomination);
    }

    /**
     * @dev Sets feed addresses for a given assets.
     *
     * Requirements:
     *
     * - `_asset` should not be the zero address .
     * - `_feed` should not be the zero address .
     * - `_denomination` should be zero address, if and only if, `_feed` reports prices in USD.
     * - `_denomination` should be an already registered assets (denominated in USD),
     * if and only if, `_feed` reports prices in any unit of account different from USD.
     *
     * @param _asset Asset address.
     * @param _feed Asset/ETH price feed.
     */
    function _setAssetFeed(
        address _asset,
        address _feed,
        address _denomination
    ) internal {
        require(_asset != address(0), "asset is the zero address");
        require(_feed != address(0), "asset feed is the zero address");
        require(
            _denomination == USD_DENOMINATION_ADDRESS ||
                (assetFeed[_denomination].feed != address(0) &&
                    assetFeed[_denomination].denomination == USD_DENOMINATION_ADDRESS),
            "invalid denomination"
        );
        assetFeed[_asset].feed = _feed;
        assetFeed[_asset].denomination = _denomination;
        if (_denomination != USD_DENOMINATION_ADDRESS) {
            emit NonStandardDenominationSet(_denomination);
        }
        emit AssetFeedSet(_asset, _feed);
    }

    /**
     * @dev Sets feed addresses for a given group of assets.
     *
     * Requirements:
     *
     * - the caller must have FEEDS_MANAGER_ROLE.
     * - `_assets` and `_feeds` lengths must match.
     * - every address in `_assets` should not be the zero address .
     * - every address in `_feeds` should not be the zero address .
     * - every address in `_denomination` should be an already registered asset
     * (denominated in USD), if and only, address in `_feeds` at the same index
     * reports prices in any unit of account different from USD.
     * - every address in `_denomination` should be USD_DENOMINATION_ADDRESS,
     * if and only, address in `_feeds` at the same index, reports prices USD.
     * - order matters, because denemoniations on greater indexes can depend on assets of lower index.
     *
     * @param _assets Array of assets addresses.
     * @param _feeds Array of asset/ETH price feeds.
     */
    function setAssetsFeeds(
        address[] memory _assets,
        address[] memory _feeds,
        address[] memory _denominations
    ) external override onlyFeedsManager {
        _setAssetsFeeds(_assets, _feeds, _denominations);
    }

    /**
     * @dev Sets feed addresses for a given group of assets.
     *
     * Requirements:
     *
     * - `_assets`, `_feeds` and `_denominations` lengths must match.
     * - every address in `_assets` should not be the zero address .
     * - every address in `_feeds` should not be the zero address .
     *
     * @param _assets Array of assets addresses.
     * @param _feeds Array of asset/ETH price feeds.
     */
    function _setAssetsFeeds(
        address[] memory _assets,
        address[] memory _feeds,
        address[] memory _denominations
    ) internal {
        require(_assets.length == _feeds.length && _feeds.length == _denominations.length, "lengths do not match");
        for (uint256 i = 0; i < _assets.length; i++) {
            _setAssetFeed(_assets[i], _feeds[i], _denominations[i]);
        }
    }

    /**
     * @dev Gets the price 1 `_asset` in EUR.
     *
     * @param _asset address of asset to get the price.
     *
     * @return price scaled by 1e8, denominated in EUR
     * e.g. 17568900000 => 175.689 EUR
     */
    function getPrice(address _asset) external view override returns (uint256) {
        return _getPrice(_asset);
    }

    /**
     * @dev Gets how many EUR represents the `_amount` of `_asset`.
     *
     * @param _asset address of asset to get the price.
     * @param _amount amount of `_asset`.
     */
    function calculateAmount(address _asset, uint256 _amount) external view override returns (uint256) {
        uint8 assetDecimals = IDecimals(_asset).decimals();
        uint256 assetPrice = _getPrice(_asset);

        // 10**assetDecimals (1 ASSET) <-> assetPrice EUR
        // _amount                     <-> x ERU
        // x EUR = _amount *  assetPrice / 10**assetDecimals
        return _amount.mul(assetPrice).div(10**assetDecimals);
    }

    /**
     * @dev Gets the price 1 `_asset` in EUR.
     *
     * @param _asset address of asset to get the price.
     *
     * @return price scaled by 1e18, denominated in EUR
     */
    function _getPrice(address _asset) internal view returns (uint256) {
        if (assetFeed[_asset].feed == address(0)) {
            return 0;
        }

        uint256 eurUsdDecimals = AggregatorV2V3Interface(eurUsdFeed).decimals();
        int256 eurUsdPrice = AggregatorV2V3Interface(eurUsdFeed).latestAnswer();
        int256 denomUsdPrice;
        uint256 denomUsdDecimals;

        if (assetFeed[_asset].denomination == USD_DENOMINATION_ADDRESS) {
            // denomination being zero address, means denominated in USD
            // neutral values in de intermediation calculations are Price = 1, and Decimals = 18
            denomUsdDecimals = 0;
            denomUsdPrice = 1;
        } else {
            // denomination different from zero address, means we need to use a pivot for denominations
            // So another already registered asset will intermediate the calculations
            address denominationFeed = assetFeed[assetFeed[_asset].denomination].feed;
            denomUsdDecimals = AggregatorV2V3Interface(denominationFeed).decimals();
            denomUsdPrice = AggregatorV2V3Interface(denominationFeed).latestAnswer();
        }

        uint256 assetDenomDecimals = AggregatorV2V3Interface(assetFeed[_asset].feed).decimals();
        int256 assetDenomPrice = AggregatorV2V3Interface(assetFeed[_asset].feed).latestAnswer();

        if (eurUsdPrice <= 0 || denomUsdPrice <= 0 || assetDenomPrice <= 0) {
            return 0;
        }

        // Normalization of decimals, considering potentiation properties
        //   10**27 means ONE as standard expression in this contract (one scaled to 27 digits)
        //   10**decimals means ONE for asset's expression
        //   10**(27-decimals) means OneStandard/OneAsset
        //   because (10**27)/(10**decimals)=10**(27-decimals)

        // get the euro to usd price in base 27
        uint256 eurUsdPriceBase27 = uint256(eurUsdPrice).mul(10**(DIGITS.sub(eurUsdDecimals)));

        // get the denominator price in base 27
        uint256 denomUsdPriceBase27 = uint256(denomUsdPrice).mul(10**(DIGITS.sub(denomUsdDecimals)));

        // get the asset price with the defined feed in base 27
        uint256 assetDenomPriceBase27 = uint256(assetDenomPrice).mul(10**(DIGITS.sub(assetDenomDecimals)));

        // get the asset price in usd in base 27
        uint256 priceUsdBase27 = denomUsdPriceBase27.mul(assetDenomPriceBase27).div(ONE_BASE27);

        // get the asset price in eur
        uint256 priceInEurBase27 = ONE_BASE27.mul(priceUsdBase27).div(eurUsdPriceBase27);

        // return the price in base 18
        uint256 assetEurPrice = priceInEurBase27.div(10**(DIGITS - RETURN_DIGITS_BASE18));

        return assetEurPrice;
    }

    /**
     * @dev Gets the feed for one _asset
     *
     * @param _asset address of asset to get the price.
     *
     * @return address of the asset feed
     */     
    function getAssetFeed(address _asset) external override view returns (address) {
        return assetFeed[_asset].feed;
    }
}
