// contracts/SchnoodleTimelock.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./TokenTimelock.sol";
import "./TokenTimelockUpgradeable.sol";

contract SchnoodleTimelock is TokenTimelockUpgradeable {
    function initialize(IERC20Upgradeable token, address beneficiary, uint256 releaseTime) public initializer {
        __TokenTimelock_init(token, beneficiary, releaseTime);
    }
}
