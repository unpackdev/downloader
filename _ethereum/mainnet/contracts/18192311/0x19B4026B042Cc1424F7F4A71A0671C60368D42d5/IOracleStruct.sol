// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorV3Interface.sol";

interface IOracleStruct {
    enum PoolType {
        STABLE,
        UNI_V2,
        UNI_V3,
        CURVE_DUO,
        CURVE_TRI
    }

    struct OracleParams {
        PoolType poolType;
        bool isReversed;
        bool isEthPriceRelated;
        uint32 twapOrK;
        address poolAddress;
        uint40 deltaLimitOracle; // 5 % => 500 & 100 % => 10 000
        uint96 maxLastUpdate; // Buffer time before a not updated price is considered as stale
        AggregatorV3Interface aggregatorOracle;
        uint128 minPrice;
        uint128 maxPrice;
        address[] stablesToCheck;
    }
}
