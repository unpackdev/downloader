// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./IPriceOracle.sol";

struct Index {
    uint96 borrow;
    uint96 supply;
    uint32 lastUpdate;
}

struct MarketInfo {
    Price price;
    Index index;
}
struct Par {
    bool sign;
    uint128 value;
}

struct Wei {
    bool sign;
    uint256 value;
}

interface ISoloMargin {
    function getMarginRatio() external view returns (uint256);

    function getMarketPriceOracle(uint256 _marketId)
        external
        view
        returns (IPriceOracle);

    function getMarketTokenAddress(uint256 _marketId)
        external
        view
        returns (address);

    function getNumMarkets() external view returns (uint256);

    function getMarketPrice(uint256 _marketId)
        external
        view
        returns (Price memory);

    function getMarketCurrentIndex(uint256 _marketId)
        external
        view
        returns (Index memory);

    function getAccountPar(address _account, uint256 _m)
        external
        view
        returns (Par memory);
}
