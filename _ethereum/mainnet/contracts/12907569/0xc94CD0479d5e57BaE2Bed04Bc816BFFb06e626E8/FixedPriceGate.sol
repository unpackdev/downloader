// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;

import "./IGate.sol";
import "./IIncinerator.sol";

contract FixedPriceGate is IGate {

    uint public ethCost;
    address public management;
    address public burnToken;

    IIncinerator public incinerator;

    event ManagementUpdated(address oldManagement, address newManagement);
    event PriceUpdated(uint oldPrice, uint newPrice);

    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    constructor (uint _ethCost, address _management, address _incinerator, address _burnToken) {
        ethCost = _ethCost;
        management = _management;
        incinerator = IIncinerator(_incinerator);
        burnToken = _burnToken;
    }

    // change the management key
    function setManagement(address newMgmt) external managementOnly {
        address oldMgmt =  management;
        management = newMgmt;
        emit ManagementUpdated(oldMgmt, newMgmt);
    }

    function setPrice(uint newPrice) external managementOnly {
        uint oldPrice = ethCost;
        ethCost = newPrice;
        emit PriceUpdated(oldPrice, newPrice);
    }

    function getCost() override external view returns (uint _ethCost) {
        return ethCost;
    }

    function passThruGate() override external payable {
        require(msg.value >= ethCost, 'Please send more ETH');

        // burn token cost
        if (msg.value > 0) {
            incinerator.incinerate{value: msg.value}(burnToken);
        }
    }
}
