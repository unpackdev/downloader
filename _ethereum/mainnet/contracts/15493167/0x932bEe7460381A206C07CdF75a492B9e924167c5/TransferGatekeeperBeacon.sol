// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

import "./UpgradeableBeacon.sol";

contract TransferGatekeeperBeacon is UpgradeableBeacon {
    // solhint-disable-next-line
    constructor(address implementation) public UpgradeableBeacon(implementation) {}
}
