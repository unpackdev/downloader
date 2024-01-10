// SPDX-License-Identifier: MIT
pragma solidity  ^0.6.12;

interface IMarketWrapper {
    
    function auctionExists(uint256 auctionId) external view returns (bool);

    function auctionIdMatchesToken(
        uint256 auctionId,
        address nftContract,
        uint256 tokenId
    ) external view returns (bool);

    function getMinimumBid(uint256 auctionId) external view returns (uint256);

    function getCurrentHighestBidder(uint256 auctionId)
        external
        view
        returns (address);

    function bid(uint256 auctionId, uint256 bidAmount) external;

    function isFinalized(uint256 auctionId) external view returns (bool);

    function finalize(uint256 auctionId) external;

}
