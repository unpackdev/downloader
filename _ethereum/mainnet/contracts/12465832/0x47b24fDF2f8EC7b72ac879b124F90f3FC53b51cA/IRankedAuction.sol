pragma solidity 0.7.6;

interface IRankedAuction {
    function bid(uint256 auctionId, address onBehalfOf, uint256 amount) external;
}