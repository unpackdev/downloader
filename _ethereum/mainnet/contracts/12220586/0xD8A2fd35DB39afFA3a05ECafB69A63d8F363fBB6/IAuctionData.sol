// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IAuctionData {
    function auctionsOf_(address) external view returns (uint256[] memory);

    function auctionBidOf(uint256, address)
        external
        view
        returns (uint256, address);

    function lastAuctionEventIdV1() external view returns (uint256);
}
