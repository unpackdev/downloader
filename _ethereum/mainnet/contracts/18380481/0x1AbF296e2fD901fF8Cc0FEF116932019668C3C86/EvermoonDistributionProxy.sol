// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./TransparentUpgradeableProxy.sol";

contract EvermoonDistributionProxy is TransparentUpgradeableProxy {
    constructor(address logic_, address admin_, bytes memory data_)
        TransparentUpgradeableProxy(logic_, admin_, data_)
    {}
}
