// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;

import "./PendleLiquidityMiningBase.sol";
import "./PendleLiquidityMiningBaseV2.sol";

contract PendleStakingZerionProxy {
    struct Vars {
        uint256 startTime;
        uint256 epochDuration;
        uint256 currentEpoch;
        uint256 timeLeftInEpoch;
    }

    address public owner;
    address public pendingOwner;
    PendleLiquidityMiningBase[] public v1LMs;
    PendleLiquidityMiningBaseV2[] public v2LMs;
    uint256[] public expiries;
    uint256 private constant ALLOCATION_DENOMINATOR = 1_000_000_000;

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    constructor (
        address _owner,
        PendleLiquidityMiningBase[] memory _v1LMs,
        PendleLiquidityMiningBaseV2[] memory _v2LMs,
        uint256[] memory _expiries
    ) {
        require(_owner != address(0), "ZERO_ADDRESS");
        owner = _owner;
        v1LMs = _v1LMs;
        v2LMs = _v2LMs;
        expiries = _expiries;
    }

    function claimOwnership() external {
        require(pendingOwner == msg.sender, "WRONG_OWNER");
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    function transferOwnership(address _owner) external onlyOwner {
        require(_owner != address(0), "ZERO_ADDRESS");
        pendingOwner = _owner;
    }

    function addLMv1(PendleLiquidityMiningBase _lm) external onlyOwner {
        v1LMs.push(_lm);
    }

    function setLMv1(PendleLiquidityMiningBase[] calldata _lms) external onlyOwner {
        v1LMs = _lms;
    }

    function addLMv2(PendleLiquidityMiningBaseV2 _lm) external onlyOwner {
        v2LMs.push(_lm);
    }

    function setLMv2(PendleLiquidityMiningBaseV2[] calldata _lms) external onlyOwner {
        v2LMs = _lms;
    }

    function addExpiry(uint256 _expiry) external onlyOwner {
        expiries.push(_expiry);
    }

    function setExpiries(uint256[] calldata _expiries) external onlyOwner {   
        expiries = _expiries;
    }

    function earned(address user)
        external
        view
        returns (uint256)
    {
        uint256 totalEarned = 0;

        for (uint256 i = 0; i < v1LMs.length; i++) {
            for (uint256 j = 0; j < expiries.length; j++) {
                totalEarned += _calcLMAccruingV1(v1LMs[i], expiries[j], user);
            }            
        }
        for (uint256 i = 0; i < v1LMs.length; i++) {
            totalEarned += _calcLMAccruingV2(v2LMs[i], user);
        }

        return totalEarned;
    }

    function _calcLMAccruingV1(
        PendleLiquidityMiningBase liqMining,
        uint256 expiry,
        address user
    )
        internal
        view
        returns (uint256)
    {
        Vars memory vars;
        vars.startTime = liqMining.startTime();
        vars.epochDuration = liqMining.epochDuration();
        vars.currentEpoch = (block.timestamp - vars.startTime) / vars.epochDuration + 1;
        vars.timeLeftInEpoch =
            vars.epochDuration -
            ((block.timestamp - vars.startTime) % vars.epochDuration);

        (uint256 totalStakeUnits, ) = liqMining.readExpirySpecificEpochData(vars.currentEpoch, expiry);
        uint256 userStakeUnits = liqMining.readStakeUnitsForUser(vars.currentEpoch, user, expiry);
        (uint256 totalStake, , , ) = liqMining.readExpiryData(expiry);
        if (totalStake == 0) return 0;

        (, uint256 totalRewards) = liqMining.readEpochData(vars.currentEpoch);
        (uint256 latestSettingId, ) = liqMining.latestSetting();
        uint256 epochRewards = (totalRewards *
            liqMining.allocationSettings(latestSettingId, expiry)) / ALLOCATION_DENOMINATOR;

        return (epochRewards * userStakeUnits) / (totalStakeUnits + vars.timeLeftInEpoch * totalStake);
    }

    function _calcLMAccruingV2(
        PendleLiquidityMiningBaseV2 liqMiningV2,
        address user
    )
        internal
        view
        returns (uint256)
    {
        Vars memory vars;
        vars.startTime = liqMiningV2.startTime();
        vars.epochDuration = liqMiningV2.epochDuration();
        vars.currentEpoch = (block.timestamp - vars.startTime) / vars.epochDuration + 1;
        vars.timeLeftInEpoch =
            vars.epochDuration -
            ((block.timestamp - vars.startTime) % vars.epochDuration);
        (uint256 totalStakeUnits, uint256 epochRewards, , uint256 userStakeUnits, ) =
            liqMiningV2.readEpochData(vars.currentEpoch, user);
        uint256 totalStake = liqMiningV2.totalStake();

        return (epochRewards * userStakeUnits) / (totalStakeUnits + vars.timeLeftInEpoch * totalStake);
    }
}
