// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

abstract contract StagesStorage {
    using SafeMath for uint256;

    uint256 _totalRewardAmount;
    function totalRewardAmount() public view returns (uint256) {
        return _totalRewardAmount;
    }

    constructor(
        uint256 totalRewardAmount_
    ) public {
        require(totalRewardAmount_ > 0, "constructor: totalRewardAmount is empty");
        _totalRewardAmount = totalRewardAmount_;
    }

    struct StageInfo {
        uint256 id;
        uint256 startBlock;
        uint256 endBlock;
        uint256 rewardPerBlock;
    }
    // stageId => StageInfo
    StageInfo[] _stageInfo;
    uint256 _stageInfoCount = 0;
    uint256 _totalRewardInStages;
    uint256 _lastStageEndBlock;

    function stageInfo(uint256 stageId) public view returns (StageInfo memory) {
        return _stageInfo[stageId];
    }
    function stageInfoCount() public view returns (uint256) {
        return _stageInfoCount;
    }
    function totalRewardInStages() public view returns (uint256) {
        return _totalRewardInStages;
    }

    function _addFirstStage(
        uint256 startBlock,
        uint256 periodInBlocks,
        uint256 rewardAmount
    ) internal {
        require(_lastStageEndBlock == 0, "_addFirstStage: first stage is already installed");
        startBlock = block.number > startBlock ? block.number : startBlock;
        __addStage(
            startBlock,
            periodInBlocks,
            rewardAmount
        );
    }

    function _addStage(
        uint256 periodInBlocks,
        uint256 rewardAmount
    ) internal {
        require(_lastStageEndBlock > 0, "_addStage: first stage is not installed yet");
        __addStage(
            _lastStageEndBlock,
            periodInBlocks,
            rewardAmount
        );
    }

    function __addStage(
        uint256 startBlock,
        uint256 periodInBlocks,
        uint256 rewardAmount
    ) private {
        StageInfo memory newStage = StageInfo({
            id: _stageInfoCount,
            startBlock: startBlock,
            endBlock: startBlock.add(periodInBlocks),
            rewardPerBlock: rewardAmount.div(periodInBlocks)
        });
        ++_stageInfoCount;
        _stageInfo.push(newStage);

        _lastStageEndBlock = newStage.endBlock.add(1);
        _totalRewardInStages = _totalRewardInStages.add(rewardAmount);
        require(_totalRewardInStages <= _totalRewardAmount, "__addStage: _totalRewardInStages > _totalRewardAmount");
    }

    function stagesLength() external view returns (uint256) {
        return _stageInfo.length;
    }
}