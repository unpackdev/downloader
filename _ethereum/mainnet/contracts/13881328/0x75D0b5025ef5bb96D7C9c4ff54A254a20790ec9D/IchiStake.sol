// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20Upgradeable.sol";

abstract contract IchiStake is IERC20Upgradeable {
    IERC20Upgradeable public Ichi;

    // Enter the bar. Pay some SUSHIs. Earn some shares.
    function enter(uint256 _amount) public virtual;

    // Leave the bar. Claim back your SUSHIs.
    function leave(uint256 _share) public virtual;
}