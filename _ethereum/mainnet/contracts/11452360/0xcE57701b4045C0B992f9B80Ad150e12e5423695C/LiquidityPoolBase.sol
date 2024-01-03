// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./PoolBase.sol";

contract LiquidityPoolBase is PoolBase {
    struct UserInfo {
        uint256 shares; // How many pool shares user owns, equal to staked tokens with bonuses applied
        uint256 staked; // How many PWDR-ETH LP tokens the user has staked
        uint256 rewardDebt; // Reward debt. Works the same as in the Slopes contract
        uint256 claimed; // Tracks the amount of PWDR claimed by the user
    }

    mapping (address => UserInfo) public userInfo; // Info of each user that stakes PWDR-ETH LP tokens

    modifier HasStakedBalance(address _address) {
        require(userInfo[_address].staked > 0, "Must have staked balance greater than zero");
        _;
    }

    modifier HasWithdrawableBalance(address _address, uint256 _amount) {
        require(userInfo[_address].staked >= _amount, "Cannot withdraw more tokens than staked balance");
        _;
    }
}