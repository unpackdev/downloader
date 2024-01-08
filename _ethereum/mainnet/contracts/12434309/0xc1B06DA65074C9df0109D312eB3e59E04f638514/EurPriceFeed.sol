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

    /// @dev mapping between an asset and its feed. It returs how many ETH is 1eAssetDecimal asset.
    mapping(address => address) public assetEthFeed;

    /// @dev EUR/USD feed. It returs how many USD is 1 EUR.
    address public eurUsdFeed;

    /// @dev ETH/USD feed. It returs how many USD is 1 ETH.
    address public ethUsdFeed;

    /**
     * @dev Emitted when `eurUsdFeed` address is set.
     */
    event EurUsdFeedSet(address indexed newEurUsdFeed);

    /**
     * @dev Emitted when `ethUsdFeed` address is set.
     */
    event EthUsdFeedSet(address indexed newEthUsdFeed);

    /**
     * @dev Emitted when a feed address is set for an asset.
     */
    event AssetEthFeedSet(address indexed asset, address indexed feed);

    /**
     * @dev Sets the values for {eurUsdFeed}, {ethUsdFeed} and {assetUsdFeed}.
     *
     * Grants the contract deployer the default admin role.
     *
     */
    constructor(
        address _eurUsdFeed,
        address _ethUsdFeed,
        address[] memory _assets,
        address[] memory _feeds
    ) {
        require(_eurUsdFeed != address(0), "eur/usd price feed is the zero address");
        require(_ethUsdFeed != address(0), "eth/usd price feed is the zero address");

        eurUsdFeed = _eurUsdFeed;
        emit EurUsdFeedSet(_eurUsdFeed);

        ethUsdFeed = _ethUsdFeed;
        emit EthUsdFeedSet(_ethUsdFeed);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setAssetsFeeds(_assets, _feeds);
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
     * @dev Sets `_ethUsdFeed` as the new ERU/USD feed.
     *
     * Requirements:
     *
     * - the caller must have FEEDS_MANAGER_ROLE.
     * - `_ethUsdFeed` should not be the zero address.
     *
     * @param _ethUsdFeed The address of the new ERU/USD feed.
     */
    function setEthUsdFeed(address _ethUsdFeed) external onlyFeedsManager {
        require(_ethUsdFeed != address(0), "eth/usd price feed is the zero address");
        emit EthUsdFeedSet(_ethUsdFeed);
        ethUsdFeed = _ethUsdFeed;
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
     *
     * @param _assets Array of assets addresses.
     * @param _feeds Array of asset/ETH price feeds.
     */
    function setAssetsFeeds(address[] memory _assets, address[] memory _feeds) external override onlyFeedsManager {
        _setAssetsFeeds(_assets, _feeds);
    }

    /**
     * @dev Sets feed addresses for a given assets.
     *
     * Requirements:
     *
     * - the caller must have FEEDS_MANAGER_ROLE.
     * - `_asset` should not be the zero address .
     * - `_feed` should not be the zero address .
     *
     * @param _asset Asset address.
     * @param _feed Asset/ETH price feed.
     */
    function setAssetFeed(address _asset, address _feed) external override onlyFeedsManager {
        _setAssetFeed(_asset, _feed);
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
     * @dev Sets feed addresses for a given group of assets.
     *
     * Requirements:
     *
     * - `_assets` and `_feeds` lengths must match.
     * - every address in `_assets` should not be the zero address .
     * - every address in `_feeds` should not be the zero address .
     *
     * @param _assets Array of assets addresses.
     * @param _feeds Array of asset/ETH price feeds.
     */
    function _setAssetsFeeds(address[] memory _assets, address[] memory _feeds) internal {
        require(_assets.length == _feeds.length, "assets and feeds lengths not match");

        for (uint256 i = 0; i < _assets.length; i++) {
            _setAssetFeed(_assets[i], _feeds[i]);
        }
    }

    /**
     * @dev Sets feed addresses for a given assets.
     *
     * Requirements:
     *
     * - `_asset` should not be the zero address .
     * - `_feed` should not be the zero address .
     *
     * @param _asset Asset address.
     * @param _feed Asset/ETH price feed.
     */
    function _setAssetFeed(address _asset, address _feed) internal {
        require(_asset != address(0), "asset is the zero address");
        require(_feed != address(0), "asset feed is the zero address");
        emit AssetEthFeedSet(_asset, _feed);
        assetEthFeed[_asset] = _feed;
    }

    /**
     * @dev Gets the price 1 `_asset` in EUR.
     *
     * @param _asset address of asset to get the price.
     *
     * @return price scaled by 1e18, denominated in EUR
     */
    function _getPrice(address _asset) internal view returns (uint256) {
        if (assetEthFeed[_asset] == address(0)) {
            return 0;
        }

        uint256 eurUsdDecimals = AggregatorV2V3Interface(eurUsdFeed).decimals();
        int256 eurUsdPrice = AggregatorV2V3Interface(eurUsdFeed).latestAnswer();

        uint256 ethUsdDecimals = AggregatorV2V3Interface(ethUsdFeed).decimals();

        int256 ethUsdPrice = AggregatorV2V3Interface(ethUsdFeed).latestAnswer();

        uint256 assetEthDecimals = AggregatorV2V3Interface(assetEthFeed[_asset]).decimals();
        int256 assetEthPrice = AggregatorV2V3Interface(assetEthFeed[_asset]).latestAnswer();

        if (eurUsdPrice <= 0 || ethUsdPrice <= 0 || assetEthPrice <= 0) {
            return 0;
        }

        // (X x* 1e18)/(Y * 1e18) = X/Y = Z ==> (X * 1e18) * 1e8 / (Y * 1e18) = Z * 1e8
        // ETH/EUR
        // ETH/USD ==> 1 ETH -> 125375000000 USD (scale 1e8)
        // EUR/USD ==> 1 EUR -> 121376500 USD (scaled 1e8)
        //  125375000000 * 1e(18-8) USD  = 1e18 ETH
        //  121376500 * 1e(18-8) USD     = 1 EUR
        //  125375000000*1e(18-8) USD (1e18 ETH) = 125375000000*1e(18-8) / 121376500 * 1e(18-8) EUR

        uint256 num = uint256(ethUsdPrice).mul(10**(18 - ethUsdDecimals)).mul(10**18);
        uint256 den = uint256(eurUsdPrice).mul(10**(18 - eurUsdDecimals));

        uint256 ethEurPrice = num.div(den);

        // asset/EUR
        // DAI/ETH ==> 1 DAI -> 802500000000000 ETH (scaled 1e18)
        // 10**(18-daiUsdDecimal) DAI = 802500000000000 ETH
        // 1e18 ETH                   = ethEurPrice EUR
        // 802500000000000 ETH (1e18 DAI)_= (802500000000000 ETH * ethEurPrice / 1e18) EUR
        uint256 assetEurPrice = uint256(assetEthPrice).mul(10**(18 - assetEthDecimals)).mul(ethEurPrice).div(10**18);

        return assetEurPrice;
    }
}
