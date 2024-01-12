// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct Auction {
    uint256 startBlock;
    uint256 endBlock;
    uint256 startPrice;
    uint256 supply;
    address artist;
    bool distributed;
}

interface IGenArtDutchAuctionHouse {
    function addAuction(
        address collection,
        address artist,
        uint256 supply,
        uint256 startPrice,
        uint256 startBlock
    ) external;

    function getAuction(address collection)
        external
        view
        returns (Auction memory);

    function getAuctionStatus(address collection) external view returns (uint8);

    function getAuctionPrice(address collection)
        external
        view
        returns (uint256);

    function getAvailableMintsByMembership(
        address collection,
        uint256 membershipId
    ) external view returns (uint256);
}
