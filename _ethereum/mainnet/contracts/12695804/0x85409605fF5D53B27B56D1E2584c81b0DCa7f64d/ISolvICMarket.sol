// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ISolvICMarket {
    event Publish(
        address indexed icToken,
        address indexed seller,
        uint24 indexed tokenId,
        uint24 saleId,
        uint8 priceType,
        uint128 units,
        uint128 startTime,
        address currency,
        uint128 min,
        uint128 max,
        bool useAllowList
    );

    event Remove(
        address indexed icToken,
        address indexed seller,
        uint24 indexed saleId,
        uint128 total,
        uint128 saled
    );

    event FixedPriceSet(
        address indexed icToken,
        uint24 indexed saleId,
        uint24 indexed tokenId,
        uint8 priceType,
        uint128 lastPrice
    );

    event DecliningPriceSet(
        address indexed icToken,
        uint24 indexed saleId,
        uint24 indexed tokenId,
        uint128 highest,
        uint128 lowest,
        uint32 duration,
        uint32 interval
    );

    event Traded(
        address indexed buyer,
        uint24 indexed saleId,
        address indexed icToken,
        uint24 tokenId,
        uint24 tradeId,
        uint32 tradeTime,
        address currency,
        uint8 priceType,
        uint128 price,
        uint128 tradedUnits,
        uint256 tradedAmount,
        uint8 feePayType,
        uint128 fee
    );

    function publishFixedPrice(
        address icToken_,
        uint24 tokenId_,
        address currency_,
        uint128 min_,
        uint128 max_,
        uint32 startTime_,
        bool useAllowList_,
        uint128 price_
    ) external returns (uint24 saleId);

    function publishDecliningPrice(
        address icToken_,
        uint24 tokenId_,
        address currency_,
        uint128 min_,
        uint128 max_,
        uint32 startTime_,
        bool useAllowList_,
        uint128 highest_,
        uint128 lowest_,
        uint32 duration_,
        uint32 interval_
    ) external returns (uint24 saleId);

    function buyByAmount(uint24 saleId_, uint256 amount_)
        external
        payable
        returns (uint128 units_);

    function buyByUnits(uint24 saleId_, uint128 units_)
        external
        payable
        returns (uint256 amount_, uint128 fee_);

    function remove(uint24 saleId_) external;

    function totalSalesOfICToken(address icToken_)
        external
        view
        returns (uint256);

    function saleIdOfICTokenByIndex(address icToken_, uint256 index_)
        external
        view
        returns (uint256);
    function getPrice(uint24 saleId_) external view returns (uint128);
}
