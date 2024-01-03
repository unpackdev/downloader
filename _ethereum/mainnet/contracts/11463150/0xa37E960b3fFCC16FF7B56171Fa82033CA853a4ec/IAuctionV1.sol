// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IAuctionV1 {
    function auctionBetOf(uint256, address) 
        external returns (uint256, address);
}
