pragma solidity ^0.8.14;
//SPDX-License-Identifier: MIT

import "./UpgradeableBeacon.sol";
import "./Ownable.sol";

contract MerchantContractBeacon is Ownable {
    UpgradeableBeacon immutable beacon;

    address public implementation;

    constructor(address _initImplementation) {
        beacon = new UpgradeableBeacon(_initImplementation);
        implementation = _initImplementation;
        transferOwnership(tx.origin);
    }

    function upgradeImplementation(address _newImplementation)
        external
        onlyOwner
    {
        beacon.upgradeTo(_newImplementation);
        implementation = _newImplementation;
    }
}
