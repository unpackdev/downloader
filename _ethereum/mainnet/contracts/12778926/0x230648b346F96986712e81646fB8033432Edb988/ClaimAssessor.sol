/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./ISecurityMatrix.sol";
import "./IClaimConfig.sol";
import "./IClaimReward.sol";
import "./IClaimAssessor.sol";

contract ClaimAssessor is IClaimAssessor, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    // the security matrix address
    address public smx;
    // the claim config address
    address public cfg;
    // the claim reward address
    address public claimReward;

    // assessor -> the number of check points
    mapping(address => uint256) public numOfCheckPointsMap;
    // assessor -> check point id -> from block id
    mapping(address => mapping(uint256 => uint256)) public checkPointFromBlockMap;
    // assessor -> check point id -> number of votes
    mapping(address => mapping(uint256 => uint256)) public checkPointNumOfVotesMap;

    // assessor -> the latest vote timestamp
    mapping(address => uint256) public latestVoteTimeMap;
    // assessor -> the latest number of votes
    mapping(address => uint256) public numOfVotesMap;

    // the total number of votes of all assessors
    uint256 public totalNumOfVotes;
    // the total number of all assessors
    uint256 public totalNumOfAssessors;

    // the number of overview check points
    uint256 public ovvwNumOfChkPts;
    // the overview check point id -> the from block id
    mapping(uint256 => uint256) public ovvwChkPtFromBlockIdMap;
    // the overview check point id -> the total number of all assessors
    mapping(uint256 => uint256) public ovvwChkPtTotNumOfAssessorsMap;
    // the overview check point id -> the total number of votes of all assessors
    mapping(uint256 => uint256) public ovvwChkPtTotNumOfVotesMap;

    // the insur token address
    address public insur;

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        totalNumOfVotes = 0;
        totalNumOfAssessors = 0;

        ovvwNumOfChkPts = 0;
    }

    function setup(
        address securityMatrixAddress,
        address insurTokenAddress,
        address claimCfgAddress,
        address claimRewardAddress
    ) external onlyOwner {
        require(securityMatrixAddress != address(0), "S:1");
        require(insurTokenAddress != address(0), "S:2");
        require(claimCfgAddress != address(0), "S:3");
        require(claimRewardAddress != address(0), "S:4");
        smx = securityMatrixAddress;
        insur = insurTokenAddress;
        cfg = claimCfgAddress;
        claimReward = claimRewardAddress;
    }

    modifier allowedCaller() {
        require((ISecurityMatrix(smx).isAllowdCaller(address(this), _msgSender())) || (_msgSender() == owner()), "allowedCaller");
        _;
    }

    event AssessorStakeEvent(address indexed assessor, uint256 insurAmount);

    function stake(address insurTokenAddress, uint256 insurAmount) external payable nonReentrant {
        require(insurTokenAddress == insur, "STK: 1");
        require(insurAmount > 0, "STK: 2");

        address payable assessor = _msgSender();
        IClaimReward(claimReward).recalculateAssessor(assessor);

        IERC20Upgradeable(insurTokenAddress).safeTransferFrom(assessor, address(this), insurAmount);
        increaseVotes(assessor, insurAmount);

        emit AssessorStakeEvent(assessor, insurAmount);
    }

    event AssessorUnstakeEvent(address indexed assessor, uint256 insurAmount);

    function unstake(address insurTokenAddress, uint256 insurAmount) external payable nonReentrant {
        require(insurTokenAddress == insur, "USTK: 1");

        address payable assessor = _msgSender();
        IClaimReward(claimReward).recalculateAssessor(assessor);

        bool canUnstake = false;
        uint256 latestVoteTimestamp = latestVoteTimeMap[assessor];
        if (latestVoteTimestamp == 0) {
            canUnstake = true;
        } else {
            if (
                block.timestamp > latestVoteTimestamp.add(IClaimConfig(cfg).getClaimAssessorMinUnstakeTime()) // solhint-disable-line not-rely-on-time
            ) {
                canUnstake = true;
            }
        }

        require(canUnstake, "USTK: 2");
        require(insurAmount <= numOfVotesMap[assessor], "USTK: 3");
        require(IERC20Upgradeable(insurTokenAddress).balanceOf(address(this)) >= insurAmount, "USTK: 4");

        decreaseVotes(assessor, insurAmount);
        IERC20Upgradeable(insurTokenAddress).safeTransfer(assessor, insurAmount);

        emit AssessorUnstakeEvent(assessor, insurAmount);
    }

    function setLatestVoteTimestamp(address assessor, uint256 timestamp) external override allowedCaller {
        latestVoteTimeMap[assessor] = timestamp;
    }

    function getAssessorPriorNumOfVotes(address assessor, uint256 blockNumber) external view override returns (uint256) {
        // 1. check if there is any check point
        uint256 numOfCheckPoints = numOfCheckPointsMap[assessor];
        if (numOfCheckPoints == 0) {
            return 0;
        }

        // 2. check if the target block number is later than the latest check point
        if (checkPointFromBlockMap[assessor][numOfCheckPoints - 1] <= blockNumber) {
            return checkPointNumOfVotesMap[assessor][numOfCheckPoints - 1];
        }

        // 3. check if the targer block number is earlier than the earliest check point
        if (checkPointFromBlockMap[assessor][0] > blockNumber) {
            return 0;
        }

        // 4. otherwise, find the number of votes with binary search algorithm
        uint256 lower = 0;
        uint256 upper = numOfCheckPoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2;
            uint256 fromBlockId = checkPointFromBlockMap[assessor][center];
            if (fromBlockId == blockNumber) {
                return checkPointNumOfVotesMap[assessor][center];
            } else if (fromBlockId < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }

        // 5. finally, return the zero number of votes
        return checkPointNumOfVotesMap[assessor][lower];
    }

    function getOverviewPriorNumOfAssessorAndVotes(uint256 blockNumber) external view override returns (uint256, uint256) {
        // 1. check if there is any check point
        if (ovvwNumOfChkPts == 0) {
            return (totalNumOfAssessors, totalNumOfVotes);
        }

        // 2. check if the target block number is later than the latest check point
        if (ovvwChkPtFromBlockIdMap[ovvwNumOfChkPts - 1] <= blockNumber) {
            return (ovvwChkPtTotNumOfAssessorsMap[ovvwNumOfChkPts - 1], ovvwChkPtTotNumOfVotesMap[ovvwNumOfChkPts - 1]);
        }

        // 3. check if the targer block number is earlier than the earliest check point
        if (ovvwChkPtFromBlockIdMap[0] > blockNumber) {
            return (0, 0);
        }

        // 4. otherwise, find the number of votes with binary search algorithm
        uint256 lower = 0;
        uint256 upper = ovvwNumOfChkPts - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2;
            uint256 fromBlockId = ovvwChkPtFromBlockIdMap[center];
            if (fromBlockId == blockNumber) {
                return (ovvwChkPtTotNumOfAssessorsMap[center], ovvwChkPtTotNumOfVotesMap[center]);
            } else if (fromBlockId < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }

        // 5. finally, return the zero number of votes
        return (ovvwChkPtTotNumOfAssessorsMap[lower], ovvwChkPtTotNumOfVotesMap[lower]);
    }

    function increaseVotes(address assessor, uint256 amount) internal {
        require(assessor != address(0), "IV: 1");
        require(amount > 0, "IV: 2");

        // it is a new assessor if the existing number of votes is zero
        uint256 existingNumOfVotes = numOfVotesMap[assessor];
        if (existingNumOfVotes == 0) {
            totalNumOfAssessors = totalNumOfAssessors.add(1);
        }

        // add the amount to the total number of votes
        totalNumOfVotes = totalNumOfVotes.add(amount);
        // add the amount to the assessor votes
        numOfVotesMap[assessor] = existingNumOfVotes.add(amount);

        // update vote check points
        moveDelegate(address(0), assessor, amount);

        // update overview check point
        updateOvvwCheckPoint();
    }

    function decreaseVotes(address assessor, uint256 amount) internal {
        require(assessor != address(0), "DV: 1");
        require(amount > 0 && amount <= numOfVotesMap[assessor], "DV: 2");

        // substract the amount to the total number of votes
        totalNumOfVotes = totalNumOfVotes.sub(amount);
        // substract the amount to the assessor votes
        numOfVotesMap[assessor] = numOfVotesMap[assessor].sub(amount);

        // it is not an assessor anymore if the latest number of votes is zero
        if (numOfVotesMap[assessor] == 0) {
            totalNumOfAssessors = totalNumOfAssessors.sub(1);
            delete numOfVotesMap[assessor];
        }

        // update vote check points
        moveDelegate(assessor, address(0), amount);

        // update overview check point
        updateOvvwCheckPoint();
    }

    function moveDelegate(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint256 srcRepNum = numOfCheckPointsMap[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkPointNumOfVotesMap[srcRep][srcRepNum - 1] : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                writeCheckpoint(srcRep, srcRepNum, srcRepNew);
            }
            if (dstRep != address(0)) {
                uint256 dstRepNum = numOfCheckPointsMap[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkPointNumOfVotesMap[dstRep][dstRepNum - 1] : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                writeCheckpoint(dstRep, dstRepNum, dstRepNew);
            }
        }
    }

    function writeCheckpoint(
        address delegatee,
        uint256 checkPointCount,
        uint256 newVotes
    ) internal {
        if (checkPointCount > 0 && checkPointFromBlockMap[delegatee][checkPointCount - 1] == block.number) {
            checkPointNumOfVotesMap[delegatee][checkPointCount - 1] = newVotes;
        } else {
            checkPointFromBlockMap[delegatee][checkPointCount] = block.number;
            checkPointNumOfVotesMap[delegatee][checkPointCount] = newVotes;
            numOfCheckPointsMap[delegatee] = checkPointCount.add(1);
        }
    }

    function updateOvvwCheckPoint() internal {
        if (ovvwNumOfChkPts > 0 && ovvwChkPtFromBlockIdMap[ovvwNumOfChkPts - 1] == block.number) {
            ovvwChkPtTotNumOfAssessorsMap[ovvwNumOfChkPts - 1] = totalNumOfAssessors;
            ovvwChkPtTotNumOfVotesMap[ovvwNumOfChkPts - 1] = totalNumOfVotes;
        } else {
            ovvwChkPtFromBlockIdMap[ovvwNumOfChkPts] = block.number;
            ovvwChkPtTotNumOfAssessorsMap[ovvwNumOfChkPts] = totalNumOfAssessors;
            ovvwChkPtTotNumOfVotesMap[ovvwNumOfChkPts] = totalNumOfVotes;
            ovvwNumOfChkPts = ovvwNumOfChkPts.add(1);
        }
    }
}
