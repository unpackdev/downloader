pragma solidity ^0.8.9;

import "./UpgradeableBeacon.sol";

contract DepositWalletBeacon is UpgradeableBeacon {
    constructor(address implementation_) UpgradeableBeacon(implementation_) { }
}