pragma solidity 0.8.6;

import "./FeedRegistryInterface.sol";

contract PriceConsumer {

    FeedRegistryInterface internal registry;

    /**
     * Network: Mainnet Alpha Preview
     * Feed Registry: 0xd441F0B98BcF34749391A3879A94caA95ffDB74D
     */
    constructor() {
        registry = FeedRegistryInterface(0xd441F0B98BcF34749391A3879A94caA95ffDB74D);
    }

    /**
     * Returns the latest price
     */
    function getThePrice(address asset, address denomination) public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = registry.latestRoundData(asset, denomination);
        return price;
    }
}
