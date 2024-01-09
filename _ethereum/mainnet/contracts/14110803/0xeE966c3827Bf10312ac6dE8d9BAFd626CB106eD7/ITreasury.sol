// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface ITreasury {
    function mintRewards(address _recipient, uint256 _amount) external;
}
