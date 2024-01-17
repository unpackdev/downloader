// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./UpgradeableProxyOwnable.sol";
import "./OwnableStorage.sol";

contract DeadLinkzProxy is UpgradeableProxyOwnable {
    constructor(address implementation) {
        _setImplementation(implementation);
        OwnableStorage.layout().owner = msg.sender;
    }

    /**
     * @dev suppress compiler warning
     */
    receive() external payable {}
}
