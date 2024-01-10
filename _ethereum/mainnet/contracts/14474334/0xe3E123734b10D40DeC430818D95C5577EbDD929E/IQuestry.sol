// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

interface IQuestry {

    struct Content {
        uint256 id;
        uint256 price;
        uint256 remain;
        uint256 maxSupply;
        string contentCID;
        uint32 startAuctionTime;
        uint32 endAuctionTime;
        uint96 royaltyBasisPoint;
    }

    struct TokenIds {
        uint256 contentId;
        uint256 tokenIdForContent;
    }

    /* ------------- Content Manager ------------- */

    function addContent(
        uint256 price,
        uint256 maxSupply,
        string memory contentCID,
        uint32 startAuctionTime,
        uint32 endAuctionTime,
        uint96 royaltyBasisPoint
    ) external;

    function updateStartAuctionTime(
        uint256 contentId,
        uint32 startAuctionTime
    ) external;

    function updateEndAuctionTime(
        uint256 contentId,
        uint32 endAuctionTime
    ) external;

    function updateRoyaltyBasisPoint(
        uint256 contentId,
        uint96 royaltyBasisPoint
    ) external;

    function updateContentCID(
        uint256 contentId,
        string memory contentCID
    ) external;

    /* ------------- Owner ------------- */

    function withdraw() external;

    /* ------------- Buyer ------------- */

    function buyContent(
        uint256 contentId
    ) external payable;

    /* ------------- Utility ------------- */

    function getContent(
        uint256 contentId
    ) external view returns (Content memory);
}
