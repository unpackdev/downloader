// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./ReentrancyGuardUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./PausableUpgradeable.sol";

import "./ITreasuryStorage.sol";
import "./ITreasuryStorage.sol";

abstract contract TreasuryStorage is
    ITreasuryStorage,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC165Upgradeable
{
    // user=> token => SpendingInfo
    mapping(address => mapping(address => SpendingInfo)) public override spenders;
    uint256 public override initialTimestamp;
    IAccessControl public override registry;
}
