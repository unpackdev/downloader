// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./TransparentUpgradeableProxy.sol";

/// @title A proxy contract for did
contract PooledStakingWalletProxy is TransparentUpgradeableProxy {
    constructor(address _logic, address admin_, bytes memory _data)
        payable
        TransparentUpgradeableProxy(_logic, admin_, _data)
    {}
}
