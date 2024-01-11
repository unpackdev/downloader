// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable
pragma solidity 0.8.10;

import "./test.sol";

import "./Console.sol";
import "./LockedStaking.sol";
import "./MockERC20.sol";
import "./DSTestPlus.sol";

contract LockedStakingTest is DSTestPlus {
    LockedStaking lockedStaking;
    MockERC20 token;
    address from = address(0xABCD);
    address from2 = address(0xDCBA);

    function setUp() public {
        token = new MockERC20("SWAP", "SWAP", 18);
        token.mint(address(this), 1e30);
        lockedStaking = new LockedStaking();
        lockedStaking.initialize(address(token), 1e18);
        token.approve(address(lockedStaking), 1e50);
        lockedStaking.addReward(uint32(block.timestamp), uint32(block.timestamp + 1825 days), 31709791983764586);
        
        token.mint(from, 1e30);
        
        token.mint(from2, 1e30);

        hevm.prank(from);
        token.approve(address(lockedStaking), 1e30);

        hevm.prank(from2);
        token.approve(address(lockedStaking), 1e30);
    }

    event LockAdded(address indexed from, uint208 amount, uint32 end, uint16 multiplier);

    function test_lock(uint208 amount, uint32 duration) public logs_gas {
        amount = uint208(bound(amount, 1, token.balanceOf(from)));
        duration = uint32(bound(duration, 30 days, 1825 days));

        hevm.expectEmit(true, false, false, true);
        emit LockAdded(from, amount, uint32(block.timestamp + duration), lockedStaking.getDurationMultiplier(duration));

        hevm.prank(from);
        lockedStaking.addLock(amount, duration);

        assertEq(lockedStaking.getLockLength(from), 1);

        LockedStaking.Lock memory lockInfo = lockedStaking.getLockInfo(from, 0);
        assertEq(lockInfo.amount, amount);
        assertEq(lockInfo.end, block.timestamp + duration);
        assertEq(lockInfo.multiplier, lockedStaking.getDurationMultiplier(duration));

        assertEq(lockedStaking.totalScore(), amount * lockedStaking.getDurationMultiplier(duration));
    }

    function testFail_lockTooShort(uint208 amount) public {
        hevm.prank(from);

        lockedStaking.addLock(amount, 0);
    }

    function testFail_lockTooLong(uint208 amount) public {
        hevm.prank(from);

        lockedStaking.addLock(amount, 1825 days + 1);
    }

    function test_compound() public {
        uint256 end = block.timestamp + 1000 days;
        hevm.startPrank(from);
        lockedStaking.addLock(1e19, 1000 days);

        hevm.warp(block.timestamp + 500 days);

        lockedStaking.compound(0);
        LockedStaking.Lock memory lockInfo = lockedStaking.getLockInfo(from, 0);

        assertTrue(lockInfo.amount > 1e19);
        assertEq(lockInfo.end, end);
    }

    function testFail_compound() public {
        hevm.startPrank(from);

        lockedStaking.addLock(1e19, 1000 days);
        lockedStaking.compound(0);
    }

    function test_updateLockAmount() public {
        hevm.startPrank(from);
        lockedStaking.addLock(1e19, 1000 days);
        hevm.warp(block.timestamp + 500 days);
        uint256 balanceBefore = token.balanceOf(from);

        lockedStaking.claim();
        uint256 balanceAfter = token.balanceOf(from);
        uint256 claimed = balanceAfter - balanceBefore;
        LockedStaking.Lock memory lockInfoBefore = lockedStaking.getLockInfo(from, 0);

        lockedStaking.updateLockAmount(0, uint192(claimed));

        LockedStaking.Lock memory lockInfoAfter = lockedStaking.getLockInfo(from, 0);
        assertEq(lockInfoAfter.amount, lockInfoBefore.amount + claimed);
        assertEq(lockInfoAfter.end, lockInfoBefore.end);
        assertEq(lockInfoAfter.multiplier, lockInfoBefore.multiplier);
    }

    function testFail_updateAmount() public {
        hevm.startPrank(from);
        lockedStaking.addLock(1e19, 1000 days);
        lockedStaking.updateLockAmount(0, 0);
    }

    function test_updateLockDuration() public {
        hevm.startPrank(from);
        lockedStaking.addLock(1e19, 1000 days);
        hevm.warp(block.timestamp + 500 days);

        lockedStaking.claim();

        LockedStaking.Lock memory lockInfoBefore = lockedStaking.getLockInfo(from, 0);

        lockedStaking.updateLockDuration(0, 1500 days);

        LockedStaking.Lock memory lockInfoAfter = lockedStaking.getLockInfo(from, 0);
        assertEq(lockInfoAfter.amount, lockInfoBefore.amount);
        assertEq(lockInfoAfter.end, block.timestamp + 1500 days);
        assertEq(lockInfoAfter.multiplier, lockedStaking.getDurationMultiplier(1500 days));
    }

    function test_compVsNoComp() public {
        hevm.prank(from);
        lockedStaking.addLock(1e24, 1030 days);
        hevm.prank(from2);
        lockedStaking.addLock(1e24, 1030 days);
        for (uint256 i = 0; i < 100; ++i) {
            hevm.warp(block.timestamp + 10 days);
            hevm.prank(from);
            lockedStaking.compound(0);
        }
        LockedStaking.Lock memory lockInfo1 = lockedStaking.getLockInfo(from, 0);
        uint256 user1Claimable = lockedStaking.getUserClaimable(from);
        LockedStaking.Lock memory lockInfo2 = lockedStaking.getLockInfo(from2, 0);
        uint256 user2Claimable = lockedStaking.getUserClaimable(from2);
        assertTrue(lockInfo1.amount + user1Claimable >= lockInfo2.amount + user2Claimable);
    }

    function testFail_smallerMultiplier() public {
        hevm.startPrank(from);
        lockedStaking.addLock(1e24, 1030 days);

        hevm.warp(block.timestamp + 1000 days);

        lockedStaking.updateLockDuration(0, 500 days);
    }

    event RewardRemoved(uint256 index);

    function test_removeReward(uint192 rewardPerSecond, uint32 startsIn, uint32 endsIn, uint32 removalIn) public {
        rewardPerSecond = uint192(bound(rewardPerSecond, 1, 1e20));
        startsIn = uint32(bound(startsIn, 1, 1825 days - 1));
        endsIn = uint32(bound(endsIn, startsIn + 2, 1825 days - 3));
        removalIn = uint32(bound(removalIn, startsIn + 1, endsIn - 1));

        uint256 rewardStart = block.timestamp;
        lockedStaking.addReward(uint32(block.timestamp + startsIn), uint32(block.timestamp + endsIn), rewardPerSecond);

        assertEq(lockedStaking.getRewardsLength(), 2);

        hevm.prank(from);
        lockedStaking.addLock(1e24, 1825 days);

        hevm.warp(block.timestamp + removalIn);

        uint256 balanceBefore = token.balanceOf(address(lockedStaking));

        hevm.expectEmit(false, false, false, true);
        emit RewardRemoved(1);
        lockedStaking.removeReward(1);

        assertEq(balanceBefore, token.balanceOf(address(lockedStaking)) + (endsIn - removalIn) * rewardPerSecond);

        uint256 userBefore = token.balanceOf(from);

        hevm.prank(from);
        lockedStaking.claim();

        assertApproxEq(token.balanceOf(from), userBefore + 31709791983764586 * (block.timestamp - rewardStart) + rewardPerSecond * (removalIn - startsIn), 1000000000);
    }

    function test_unlock(uint208 amount, uint256 duration) public {
        amount = uint208(bound(amount, 1, 1e28));
        duration = bound(duration, 30 days, 1825 days);

        hevm.startPrank(from);
        lockedStaking.addLock(amount, duration);

        hevm.warp(block.timestamp + duration);

        lockedStaking.unlock(0);

        LockedStaking.Lock[] memory locks = lockedStaking.getUserLocks(from);

        assertEq(locks.length, 0);
        assertEq(lockedStaking.totalScore(), 0);
    }

    function test_unlockWithMany() public {
        hevm.startPrank(from);

        uint256 start = block.timestamp;

        lockedStaking.addLock(1, 100 days);
        lockedStaking.addLock(2, 200 days);
        lockedStaking.addLock(3, 100 days);

        hevm.warp(block.timestamp + 200 days);

        lockedStaking.unlock(1);

        LockedStaking.Lock[] memory locks = lockedStaking.getUserLocks(from);
        assertEq(locks.length, 2);

        LockedStaking.Lock memory lockOne = lockedStaking.getLockInfo(from, 0);
        assertEq(lockOne.amount, 1);
        assertEq(lockOne.end, start + 100 days);
        
        LockedStaking.Lock memory lockTwo = lockedStaking.getLockInfo(from, 1);
        assertEq(lockTwo.amount, 3);
        assertEq(lockTwo.end, start + 100 days);
    }
}
