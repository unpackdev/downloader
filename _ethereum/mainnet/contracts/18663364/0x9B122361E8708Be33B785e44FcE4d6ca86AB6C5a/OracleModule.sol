// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// Oracle core
import "./ChainlinkAdapter.sol";
import "./UniswapAdapter.sol";
import "./Structs.sol";

// Utils
import "./Ownable.sol";
import "./PercentageMath.sol";

// Interfaces
import "./ChainlinkAdapter.sol";

///@title OracleModule contract
///@notice Handle oracle logic, fetch price from chainlink and uniswap v3 TWAP, implement circuit
/// breaker
///        in case of oracle failure the contract will revert.
contract OracleModule is ChainlinkAdapter, UniswapAdapter, Ownable {
  struct OracleData {
    uint256 clPrice;
    uint256 clTimestamp;
    uint256 quoteTokenUsdPrice;
    uint256 uniPrice;
  }

  /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

  ///@notice ETH address for chainlink price feed
  address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  ///@notice WBTC address
  address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

  ///@notice WETH address for Uniswap
  address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  ///@notice Period for checking if chainlink data is stale
  ///@dev At init set at 25 hours, most of the chainlink feed have an heartbeat of 24h
  uint256 public stalePeriod;

  ///@notice twapPeriods for uniswap v3 to be compared
  uint32 public twapPeriodLong;
  uint32 public twapPeriodShort;

  ///@notice Threshold of deviation for oracle price
  uint256 public deviationThreshold;

  ///@notice In case of wrong oracle data we return a manual gwei price
  uint256 public manualGweiPrice;

  ///@notice By default USD pricing, but can be set to ETH pricing --> Allow some assets with no USD
  /// pair on chainlink
  mapping(address => bool) public useChainlinkEthPair;

  constructor(address _feedRegistry, address _gasFeed) Ownable(msg.sender) {
    // mainnet 0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf
    setChainlinkFeedRegistry(_feedRegistry);
    // mainnet 0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C
    setGasFeedAddress(_gasFeed);
    setDeviationThreshold(500); // 5%
    setTwapPeriodLong(1800);
    setTwapPeriodShort(60);
    setStalePeriod(90_000); //25hours
    setManualGweiPrice(50e9);
  }
  /*//////////////////////////////////////////////////////////////
                                 ADMIN
    //////////////////////////////////////////////////////////////*/

  ///@notice Set the address of the chainlink registry
  ///@param feedRegistry Address of the chainlink registry
  ///@dev Address 0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf
  function setChainlinkFeedRegistry(address feedRegistry) public onlyOwner {
    clRegistry = feedRegistry;
  }

  ///@notice Set the address of the gas feed
  ///@param _gasFeed Address of the gas feed
  ///@dev Address 0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C
  function setGasFeedAddress(address _gasFeed) public onlyOwner {
    gasFeed = AggregatorInterface(_gasFeed);
  }

  ///@notice Set the long TWAP window for querying Uniswap price
  ///@param _twapPeriodLong TWAP period in seconds
  function setTwapPeriodLong(uint32 _twapPeriodLong) public onlyOwner {
    twapPeriodLong = _twapPeriodLong;
  }

  ///@notice Set the short TWAP window for querying Uniswap price
  ///@param _twapPeriodShort TWAP period in seconds
  function setTwapPeriodShort(uint32 _twapPeriodShort) public onlyOwner {
    twapPeriodShort = _twapPeriodShort;
  }

  ///@notice Set the stale period
  ///@param _stalePeriod Stale period in seconds
  function setStalePeriod(uint256 _stalePeriod) public onlyOwner {
    stalePeriod = _stalePeriod;
  }

  ///@notice Set the deviation threshold
  ///@param _deviationThreshold Deviation threshold in percentage (500 -> 5%)
  function setDeviationThreshold(uint256 _deviationThreshold) public onlyOwner {
    deviationThreshold = _deviationThreshold;
  }

  ///@notice Set the manual gwei price
  ///@param _gweiPrice Gwei price
  ///@dev In case of gas feed failure we return this gwei price
  function setManualGweiPrice(uint256 _gweiPrice) public onlyOwner {
    manualGweiPrice = _gweiPrice;
  }

  ///@notice Set the useChainlinkEthPair mapping
  ///@param asset Address of the asset
  ///@dev By default if not set use USD pair in chainlink
  function setUseChainlinkEthPair(address asset, bool _useChainlinkEthPair) external onlyOwner {
    useChainlinkEthPair[asset] = _useChainlinkEthPair;
  }

  /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

  ///@notice Get the price of an asset in USD
  ///@param assetAddress Address of the asset to fetch price
  ///@param assetInfo AssetInfo struct
  ///@return Price of the asset in USD
  function getPriceInUSD(address assetAddress, AssetInfo calldata assetInfo)
    external
    view
    returns (uint256)
  {
    OracleData memory oracleData;

    // We fetch price from chainlink we cover WBTC / ETH / ERC20 price
    oracleData = assetAddress == WBTC
      ? _setWbtcPrice(oracleData, assetAddress)
      : _setChainlinkPrice(oracleData, assetAddress);

    // We fetch the quoteToken price (i.e USDC/USD price)
    oracleData = _setQuoteTokenChainlinkPrice(oracleData, assetInfo);

    // If uniswap pool exist we get price from uniswap
    assetInfo.uniswapPool != address(0)
      ? _setUniswapPrice(oracleData, assetAddress, assetInfo)
      : oracleData;

    // We convert uniswap price in USD (ASSET/WETH => WETH/USD or ASSET/DAI ==> DAI/USD)
    oracleData = _convertToUSD(oracleData);

    // We check if price is stale
    oracleData = _checkForStaleness(oracleData);

    // If both oracle are available we check if they are congruent
    if (_isChainlinkValid(oracleData) && _isUniswapValid(oracleData)) {
      // Price deviation we return 0
      if (!_isInRange(oracleData.clPrice, oracleData.uniPrice)) {
        return 0;
      } else {
        // Return mean price
        return _mean(oracleData.clPrice, oracleData.uniPrice);
      }
      // If only chainlink we use chainlink
    } else if (_isChainlinkValid(oracleData) && !_isUniswapValid(oracleData)) {
      return oracleData.clPrice;

      // If only uniswap we use uniswap
    } else if (!_isChainlinkValid(oracleData) && _isUniswapValid(oracleData)) {
      return oracleData.uniPrice;
    } else {
      // If no correct oracle we return 0
      return 0;
    }
  }

  ///@notice Get gwei price
  function getGweiPrice() external view returns (uint256) {
    uint256 gweiPrice = _getGweiPrice();
    uint256 correctedPrice = gweiPrice != 0 ? gweiPrice : manualGweiPrice;
    return correctedPrice;
  }

  /*//////////////////////////////////////////////////////////////
                                 INTERNAL
    //////////////////////////////////////////////////////////////*/

  ///@notice Write chainlink asset price and timestamp in OracleData
  ///@param oracleData OracleData struct
  ///@param asset Address of the asset to fetch price
  ///@return OracleData struct
  function _setChainlinkPrice(OracleData memory oracleData, address asset)
    internal
    view
    returns (OracleData memory)
  {
    address clQuoteToken = useChainlinkEthPair[asset] == false ? USD : ETH;
    (uint256 price, uint256 timestamp) =
      asset == WETH ? _getChainlinkPrice(ETH, USD) : _getChainlinkPrice(asset, clQuoteToken);

    if (clQuoteToken == ETH) {
      (uint256 ethPrice,) = _getChainlinkPrice(ETH, USD);
      price = price * ethPrice / 1e18;
    }

    oracleData.clPrice = price;
    oracleData.clTimestamp = timestamp;
    return oracleData;
  }

  ///@notice Write chainlink WBTC/USD (via WBTC/BTC => BTC/USD) pair price and timestamp in
  /// OracleData
  ///@param oracleData OracleData struct
  ///@param wbtcAddress wbtc address
  ///@return OracleData object
  function _setWbtcPrice(OracleData memory oracleData, address wbtcAddress)
    internal
    view
    returns (OracleData memory)
  {
    (uint256 wtbcPair, uint256 wTimestamp) = _getChainlink_wBtcPairPrice(wbtcAddress);
    (uint256 btcusd, uint256 bTimestamp) = _getChainlinkPrice(BTC, USD);
    oracleData.clPrice = wtbcPair * btcusd / 1e18;
    oracleData.clTimestamp = wTimestamp;
    if (_isStale(wTimestamp) || _isStale(bTimestamp)) {
      oracleData.clPrice = 0;
      oracleData.clTimestamp = 0;
    }
    return oracleData;
  }

  ///@notice Write quoteTokenPrice from chainlink (get USDC/USD; DAI/USD; USDT/USD)
  ///@return OracleData object
  function _setQuoteTokenChainlinkPrice(OracleData memory oracleData, AssetInfo calldata assetInfo)
    internal
    view
    returns (OracleData memory)
  {
    (uint256 price, uint256 quoteTimestamp) = assetInfo.uniswapQuoteToken == WETH
      ? _getChainlinkPrice(ETH, USD)
      : _getChainlinkPrice(assetInfo.uniswapQuoteToken, USD);
    oracleData.quoteTokenUsdPrice = _isStale(quoteTimestamp) ? 0 : price;
    return oracleData;
  }

  ///@notice Write uniswap price and timestamp in OracleData
  function _setUniswapPrice(
    OracleData memory oracleData,
    address asset,
    AssetInfo calldata assetInfo
  ) internal view returns (OracleData memory) {
    // compare long and short TWAP, return 0 if deviationThreshold exceeded
    uint256 priceShortTwap = _getUniswapPrice(asset, assetInfo, twapPeriodShort);
    uint256 priceLongTwap = _getUniswapPrice(asset, assetInfo, twapPeriodLong);

    if (_isInRange(priceShortTwap, priceLongTwap)) oracleData.uniPrice = priceLongTwap;
    else oracleData.uniPrice = 0;
    return oracleData;
  }

  ///@notice Convert ASSET/WETH pair price in ASSET/USD
  ///@param oracleData OracleData struct
  ///@return OracleData object
  function _convertToUSD(OracleData memory oracleData) internal pure returns (OracleData memory) {
    oracleData.uniPrice = oracleData.uniPrice * oracleData.quoteTokenUsdPrice / 1e18;
    return oracleData;
  }

  ///@notice If Chainlink data is stale set data to 0
  ///@param oracleData OracleData struct
  ///@return OracleData object
  function _checkForStaleness(OracleData memory oracleData)
    internal
    view
    returns (OracleData memory)
  {
    if (_isStale(oracleData.clTimestamp)) {
      oracleData.clPrice = 0;
      oracleData.clTimestamp = 0;
    }
    return oracleData;
  }

  ///@notice Check if chainlink data is stale
  ///@return Bool
  function _isStale(uint256 timestamp) internal view returns (bool) {
    return block.timestamp - timestamp <= stalePeriod ? false : true;
  }

  ///@notice Check if chainlink is valid
  ///@param oracleData OracleData struct
  ///@return Bool
  function _isChainlinkValid(OracleData memory oracleData) internal view returns (bool) {
    if (
      oracleData.clPrice == 0 || oracleData.clTimestamp == 0
        || oracleData.clTimestamp > block.timestamp
    ) return false;
    else return true;
  }

  ///@notice Check if Uniswap is valid
  ///@param oracleData OracleData struct
  ///@return Bool
  function _isUniswapValid(OracleData memory oracleData) internal pure returns (bool) {
    return oracleData.uniPrice == 0 ? false : true;
  }

  ///@notice Check if value are within the range
  function _isInRange(uint256 priceA, uint256 priceB) internal view returns (bool) {
    uint256 lowerBound = PercentageMath.percentSub(priceA, deviationThreshold);
    uint256 upperBound = PercentageMath.percentAdd(priceA, deviationThreshold);

    if (priceB < lowerBound || priceB > upperBound) return false;
    else return true;
  }

  function _mean(uint256 priceA, uint256 priceB) internal pure returns (uint256) {
    return (priceA + priceB) / 2;
  }
}
