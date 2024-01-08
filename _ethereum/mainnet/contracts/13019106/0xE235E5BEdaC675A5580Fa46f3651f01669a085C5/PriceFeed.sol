// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./AggregatorV3Interface.sol";
import "./AccessControl.sol";

contract PriceFeed is AccessControl {
    event NewFeedAdd(address token, address priceFeed);
    mapping(address => address) public priceFeed;

    constructor() {
        //ERN price feed
        priceFeed[
            0xBBc2AE13b23d715c30720F079fcd9B4a74093505
        ] = 0x0a87e12689374A4EF49729582B474a1013cceBf8;
        //WETH price feed
        priceFeed[
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        ] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * Returns the latest price
     */
    function getThePrice(address tokenFeed) external view returns (int256) {
        AggregatorV3Interface pf = AggregatorV3Interface(tokenFeed);
        (, int256 price, , , ) = pf.latestRoundData();

        return price;
    }

    function setPriceFeed(address token, address feed)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        priceFeed[token] = feed;

        emit NewFeedAdd(token, feed);
    }

    function getFeed(address token) external view returns (address) {
        return priceFeed[token];
    }
}
