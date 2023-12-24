// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IMultiRewarder.sol";
import "./MultiRewarderPerSec.sol";
import "./MultiRewarderPerSecV2.sol";
import "./IERC20.sol";

/**
 * This contract simulates MasterWombat for MultiRewarderPerSec.
 */
contract RewarderCaller {
    using SafeERC20 for IERC20;

    // Proxy onReward calls to rewarder.
    function onReward(address rewarder, address user, uint256 lpAmount) public returns (uint256[] memory rewards) {
        IERC20 lpToken = IMultiRewarder(rewarder).lpToken();
        // Rewarder use master's lpToken balance as totalShare. Make sure we have enough.
        require(lpToken.balanceOf(address(this)) >= lpAmount, 'RewarderCaller must have sufficient lpToken balance');

        return IMultiRewarder(rewarder).onReward(user, lpAmount);
    }

    // Simulate a deposit to MasterWombatV3
    // Note: MasterWombatV3 calls onRewarder before transfer
    function depositFor(address rewarder, address user, uint256 amount) public {
        (uint128 userAmount, , ) = MultiRewarderPerSec(payable(rewarder)).userInfo(0, user);
        IMultiRewarder(rewarder).onReward(user, userAmount + amount);

        IERC20 lpToken = IMultiRewarder(rewarder).lpToken();
        lpToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    // Simulate a withdrawal from MasterWombatV3
    // Note: MasterWombatV3 calls onRewarder before transfer
    function withdrawFor(address rewarder, address user, uint256 amount) public {
        (uint128 userAmount, , ) = MultiRewarderPerSec(payable(rewarder)).userInfo(0, user);
        IMultiRewarder(rewarder).onReward(user, userAmount - amount);

        IERC20 lpToken = IMultiRewarder(rewarder).lpToken();
        lpToken.safeTransfer(msg.sender, amount);
    }
}

/**
 * This contract simulates MasterWombat for MultiRewarderPerSecV2.
 */
contract RewarderCallerV2 {
    using SafeERC20 for IERC20;

    // Proxy onReward calls to rewarder.
    function onReward(address rewarder, address user, uint256 lpAmount) public returns (uint256[] memory rewards) {
        IERC20 lpToken = IMultiRewarder(rewarder).lpToken();
        // Rewarder use master's lpToken balance as totalShare. Make sure we have enough.
        require(lpToken.balanceOf(address(this)) >= lpAmount, 'RewarderCaller must have sufficient lpToken balance');

        return IMultiRewarder(rewarder).onReward(user, lpAmount);
    }

    // Simulate a deposit to MasterWombatV3
    // Note: MasterWombatV3 calls onRewarder before transfer
    function depositFor(address rewarder, address user, uint256 amount) public {
        uint256 userAmount = MultiRewarderPerSecV2(payable(rewarder)).userBalanceInfo(user);
        IMultiRewarder(rewarder).onReward(user, userAmount + amount);

        IERC20 lpToken = IMultiRewarder(rewarder).lpToken();
        lpToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    // Simulate a withdrawal from MasterWombatV3
    // Note: MasterWombatV3 calls onRewarder before transfer
    function withdrawFor(address rewarder, address user, uint256 amount) public {
        uint256 userAmount = MultiRewarderPerSecV2(payable(rewarder)).userBalanceInfo(user);
        IMultiRewarder(rewarder).onReward(user, userAmount - amount);

        IERC20 lpToken = IMultiRewarder(rewarder).lpToken();
        lpToken.safeTransfer(msg.sender, amount);
    }
}
