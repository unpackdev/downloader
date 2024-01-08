// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IAuctionV1 {
    function auctionsOf_(address) external view returns (uint256[] memory);

    function auctionBetOf(uint256, address)
        external
        view
        returns (uint256, address);
}
