// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

// import "./ERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

import "./ERC20Upgradeable.sol";

contract Storage is PausableUpgradeable, ERC20Upgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    // What assets do the basket contain?
    address[] public assets;

    // What modules have been approved?
    mapping(address => bool) public approvedModules;
}
