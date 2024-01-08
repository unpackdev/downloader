pragma solidity >=0.6.2 <0.8.0;

import "./TransparentUpgradeableProxy.sol";

contract AuctionMarketProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) public TransparentUpgradeableProxy(_logic, _admin, _data) {}
}
