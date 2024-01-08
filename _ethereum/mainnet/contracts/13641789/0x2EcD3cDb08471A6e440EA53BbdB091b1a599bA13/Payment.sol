/// @author Hapi Finance Team
/// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;

import "./Ownable.sol";
import "./AggregatorV3Interface.sol";
import "./console.sol";

/** @title Payment */
contract Payment is Ownable {
    mapping(address => uint256) subscriptionExpirationTime;

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Mainnet
     * Aggregator: ETH/USD
     * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
    }

    function pay() public payable {
        // Get current price from chainlink
        (, int256 price, , , ) = priceFeed.latestRoundData();

        // calculate seconds to add before expiration
        uint256 secondsToAdd = (uint256(price) * 31536000 * msg.value) /
            (300 * (10**8) * (10**18));

        require(
            secondsToAdd > 31526000,
            "You can add a minimum of one year to your subscription."
        );

        require(
            secondsToAdd < 157690000,
            "You can only add a maximum of 5 years to your subscription at once."
        );

        // If subscription already expired, set to seconds from now, else from existing expiration
        if (subscriptionExpirationTime[msg.sender] < block.timestamp) {
            subscriptionExpirationTime[msg.sender] =
                block.timestamp +
                secondsToAdd;
        } else {
            // if previous subscription hasn't expired yet, add to it.
            subscriptionExpirationTime[msg.sender] += secondsToAdd;
        }
    }

    function hasPaid() public view returns (bool) {
        return subscriptionExpirationTime[msg.sender] > block.timestamp;
    }

    function getExpirationTime() public view returns (uint256) {
        return subscriptionExpirationTime[msg.sender];
    }

    function getYearlyPriceWei() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();

        uint256 yearlyWeiPrice = ((300 * (10**8) * (10**18)) / uint256(price));
        return yearlyWeiPrice;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
