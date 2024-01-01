// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./AggregatorV2V3Interface.sol";
import "./ICustomOracle.sol";

enum OracleType {
    DIRECT,
    CHAINLINK,
    CURVE_FINANCE,
    UNISWAP_V2,
    UNISWAP_V3,
    CUSTOM_ORACLE
}
struct OracleItem {
    uint256 price;
    /// 10 ** decimals, it is not worked for direct off-chain price
    uint256 multiplier;
    /// feed for chainlink, pool for uniswap
    address oracle;
    /// base token address, default 0x is usd
    address base;
    OracleType oType;
}

library PriceOracleStorage {
    struct Layout {
        mapping(address => OracleItem) oracleItems;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("irrigation.contracts.storage.PriceOracle");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
