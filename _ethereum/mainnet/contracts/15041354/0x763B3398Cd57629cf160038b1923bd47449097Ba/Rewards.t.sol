// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable
pragma solidity 0.8.10;

import "./test.sol";

import "./Console.sol";
import "./LockedStaking.sol";
import "./MockERC20.sol";
import "./DSTestPlus.sol";

contract RewardsTest is DSTestPlus {
    LockedStaking lockedStaking;
    MockERC20 token;
    uint32 MAX_TIMESTAMP = 2**32 - 1;

    function setUp() public {
        token = new MockERC20("SWAP", "SWAP", 18);
        token.mint(address(this), 2**256 - 1);
        lockedStaking = new LockedStaking();
        lockedStaking.initialize(address(token), 1e18);
        token.approve(address(lockedStaking), 2**256 - 1);
    }

    event RewardAdded(uint256 start, uint256 end, uint256 amountPerSecond);

    function test_addReward(uint32 start, uint32 end, uint192 amountPerSecond) public {
        start = uint32(bound(start, block.timestamp, MAX_TIMESTAMP - 1));
        end = uint32(bound(end, start + 1, MAX_TIMESTAMP));
        amountPerSecond = uint192(bound(amountPerSecond, 1, 1e18));

        hevm.expectEmit(false, false, false, true);
        emit RewardAdded(start, end, amountPerSecond);
        lockedStaking.addReward(start, end, amountPerSecond);

        LockedStaking.Reward[] memory rewards = lockedStaking.getRewards();

        assertEq(rewards[0].start, start);
        assertEq(rewards[0].end, end);
        assertEq(rewards[0].amountPerSecond, amountPerSecond);
    }

    function testFail_addRewardAmount() public {
        lockedStaking.addReward(1, 2, 0);
    }

    function testFail_addRewardPastStart() public {
        lockedStaking.addReward(uint32(block.timestamp - 1), uint32(block.timestamp), 0);
    }

    function testFail_addRewardPastEnd() public {
        lockedStaking.addReward(uint32(block.timestamp), uint32(block.timestamp - 1), 1);
    }

    function testFail_addRewardStartGtEnd() public {
        lockedStaking.addReward(uint32(block.timestamp + 1), uint32(block.timestamp), 1);
    }

    

}
