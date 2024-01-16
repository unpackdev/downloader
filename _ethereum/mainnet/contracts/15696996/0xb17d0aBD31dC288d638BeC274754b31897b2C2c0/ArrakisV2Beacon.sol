// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./UpgradeableBeacon.sol";

contract ArrakisV2Beacon is UpgradeableBeacon {
    // solhint-disable-next-line no-empty-blocks
    constructor(address implementation_, address owner_)
        UpgradeableBeacon(implementation_)
    {
        _transferOwnership(owner_);
    }
}
