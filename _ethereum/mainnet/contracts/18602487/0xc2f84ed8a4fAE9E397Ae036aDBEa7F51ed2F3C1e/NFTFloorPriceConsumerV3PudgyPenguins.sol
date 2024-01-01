// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./AggregatorV3Interface.sol";

contract NFTFloorPriceConsumerV3PudgyPenguins {
    AggregatorV3Interface internal nftFloorPriceFeed;

    /**
     * Network: Mainnet 
     * Aggregator: PudgyPenguins
     * Address: 0x9f2ba149c2A0Ee76043d83558C4E79E9F3E5731B
     */
    constructor() {
        nftFloorPriceFeed = AggregatorV3Interface(
            0x9f2ba149c2A0Ee76043d83558C4E79E9F3E5731B
        );
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        // prettier-ignore
        (
            /*uint80 roundID*/,
            int nftFloorPrice,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = nftFloorPriceFeed.latestRoundData();
        return nftFloorPrice;
    }
}