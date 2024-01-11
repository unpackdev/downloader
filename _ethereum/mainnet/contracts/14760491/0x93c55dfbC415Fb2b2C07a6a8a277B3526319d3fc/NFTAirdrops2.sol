// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.3;

import "./NFTAirdrops.sol";

contract NFTAirdrops2 is NFTAirdrops {
    constructor(address _nftContract, uint256 fromTokenId) NFTAirdrops(_nftContract, fromTokenId) {
        // Empty
    }
}
