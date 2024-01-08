pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Registry.sol";
import "./IPriceFeeds.sol";

contract UniswapPriceOracleProxyStorage {
    address public implementation;
    address public registry;
    uint public Q112 = 2**112;
    uint public period = 10 minutes;
}

contract UniswapPriceOracleStorageV1 is UniswapPriceOracleProxyStorage {
    uint public minReserveLiquidity;

    address public WETHToken;
    address public ETHUSDPriceFeed;

    struct PoolCumulativePrice {
        FixedPoint.uq112x112 priceAverage;
        uint priceCumulativePrevious;
        uint32 blockTimeStampPrevious;
    }

    // asset => assetPair => data from pool
    mapping(address => mapping (address => PoolCumulativePrice)) public cumulativePrices;
    mapping(address => uint) public averagePrices;

    // asset => pair with reserves
    mapping(address => address) public assetPair;

    address[] public poolFactories;
    address[] public stableCoins;
}