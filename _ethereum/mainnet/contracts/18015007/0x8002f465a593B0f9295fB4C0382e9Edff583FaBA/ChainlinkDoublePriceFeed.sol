pragma solidity 0.8.20;

import "./ChainlinkPriceFeedAggregator.sol";

contract ChainlinkDoublePriceFeed is IChainlinkOracle {
    IChainlinkOracle public assetToXFeed;
    IChainlinkOracle public XToUSDFeed;

    constructor(IChainlinkOracle _assetToXFeed, IChainlinkOracle _XToUSDFeed) {
        assetToXFeed = _assetToXFeed;
        XToUSDFeed = _XToUSDFeed;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function latestAnswer() external view returns (int256) {
        return (assetToXFeed.latestAnswer() * XToUSDFeed.latestAnswer() * int256(10 ** decimals()))
            / (int256(10 ** assetToXFeed.decimals()) * int256(10 ** XToUSDFeed.decimals()));
    }
}
