// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./AggregatorV3Interface.sol";
import "./IPriceConsumer.sol";
import "./IUniswapV3Router.sol";
import "./IUniswapOracleV3.sol";
import "./IPriceConsumer.sol";
import "./IDexPair.sol";
import "./IProtocolRegistry.sol";

library LibPriceConsumerStorage {
    event PriceFeedAdded(
        address indexed token,
        address indexed usdPriceAggrigator,
        bool enabled,
        uint256 decimals
    );
    event PriceFeedAddedBulk(
        address[] indexed tokens,
        address[] indexed chainlinkFeedAddress,
        bool[] enabled,
        uint256[] decimals
    );
    event PriceFeedStatusUpdated(address indexed token, bool indexed status);
    event PriceFeedAddressUpdated(
        address indexed token,
        address indexed feedAddress
    );

    event PathAdded(address _tokenAddress, address[] indexed _pathRoute);

    event PriceConsumerInitialized(address indexed swapRouterv3);
    event SwapRouterUpdated(address indexed swapRouterv3);
    bytes32 constant PRICECONSUMER_STORAGE_POSITION =
        keccak256("diamond.standard.PRICECONSUMER.storage");

    struct PairReservesDecimals {
        IDexPair pair;
        uint256 reserve0;
        uint256 reserve1;
        uint256 decimal0;
        uint256 decimal1;
    }

    struct ChainlinkDataFeed {
        AggregatorV3Interface usdPriceAggrigator;
        bool enabled;
        uint256 decimals;
    }

    struct PriceConsumerStorage {
        mapping(address => ChainlinkDataFeed) usdPriceAggrigators;
        IUniswapV3Router swapRouterv3;
        IUniswapOracleV3 oracle;
        bool isInitializedPriceConsumer;
    }

    function priceConsumerStorage()
        internal
        pure
        returns (PriceConsumerStorage storage es)
    {
        bytes32 position = PRICECONSUMER_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}
