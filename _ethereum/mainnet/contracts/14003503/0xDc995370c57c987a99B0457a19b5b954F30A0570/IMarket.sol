// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IMarket {
    struct MarketItem {
        uint256 itemId;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        uint256 commission;
        bool sold;
        bool isPremium;
        bool isResolved;
        bool isRejected;
        bool isDistributeAssets;
    }

    function lastItemId() external view returns (uint256);

    function idTokenToMarket(uint256 tokenId) external view returns (uint256 itemId);

    function itemIds() external view returns (uint256);

    function toMarket() external view returns (address);

    function fetchSpecificMarketItem(uint256 itemId) external view returns (MarketItem memory);

    function fetchAllMarketItems(uint256 skip, uint256 limit) external view returns (MarketItem[] memory marketItems);

    function fetchMarketItemsByTokenId(uint256 tokenId, uint256 skip, uint256 limit ) external view returns (MarketItem[] memory marketItems);

    function marketItemsByTokenIdLength(uint256 tokenId) external view returns (uint256);

    function resolveDeal( uint256 tokenId, address sender, address recipient) external returns (bool);

    function saveMarketItem(MarketItem memory item) external returns (bool);

    function setTokenIdToMarket(uint256 tokenId, uint256 itemId, bool remove) external returns (bool);
}
