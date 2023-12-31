// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AggregatorV3Interface.sol";

contract MockLinkNFTOracle {
    uint80 internal id;
    int256 internal nftFloorPrice;


    constructor(int80 _nftFloorPrice) {
        nftFloorPrice = _nftFloorPrice;
    }

    function setLatestPrice(uint80 _id, int256 _nftPrice) public {
        id = _id;
        nftFloorPrice = _nftPrice;
    }
    /**
     * Returns the latest price
     */
    function latestRoundData() public view returns (      
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (id, nftFloorPrice, 0, 0, 0);
    }

    // function latestRoundData() public view returns (uint80, int, uint, uint, uint80) {
    //     return nftFloorPriceFeed.latestRoundData();
    // }

}
