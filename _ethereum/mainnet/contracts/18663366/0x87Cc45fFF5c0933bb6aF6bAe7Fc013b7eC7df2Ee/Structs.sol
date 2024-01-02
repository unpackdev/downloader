// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

struct AssetInfo {
  uint72 targetConcentration;
  address uniswapPool;
  int72 incentiveFactor;
  uint8 assetDecimals;
  uint8 quoteTokenDecimals;
  address uniswapQuoteToken;
  bool isSupported;
}

struct ProtocolData {
  ///@notice Protocol AUM in USD
  uint256 aum;
  ///@notice multiplicator for the tax equation, 100% = 100e18
  uint72 taxFactor;
  ///@notice Max deviation allowed between AUM from keeper and registry
  uint16 maxAumDeviationAllowed; // Default val 200 == 2 %
  ///@notice block number where AUM was last updated
  uint48 lastAUMUpdateBlock;
  ///@notice annual fee on AUM, in % per year 100% = 100e18
  uint72 managementFee;
  ///@notice last block.timestamp when fee was collected
  uint48 lastFeeCollectionTime;
}

struct UserRequest {
  address asset;
  uint256 amount;
}

struct RequestData {
  uint32 id;
  address requestor;
  address[] assetIn;
  uint256[] amountIn;
  address[] assetOut;
  uint256[] amountOut;
  bool keepGovRights;
  uint256 slippageChecker;
}

struct RequestQ {
  uint64 start;
  uint64 end;
  mapping(uint64 => RequestData) requestData;
}

struct ProcessParam {
  uint256 targetConc;
  uint256 currentConc;
  uint256 usdValue;
  uint256 taxableAmount;
  uint256 taxInUSD;
  uint256 sharesBeforeTax;
  uint256 sharesAfterTax;
}

struct RebalanceParam {
  address asset;
  uint256 assetTotalAmount;
  uint256 assetProxyAmount;
  uint256 assetPrice;
  uint256 sTrsyTotalSupply;
  uint256 trsyPrice;
}
