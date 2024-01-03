// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Block Selector

pragma solidity ^0.7.0;

import "./SafeMath.sol";

import "./CartesiMath.sol";
import "./InstantiatorImpl.sol";
import "./Decorated.sol";

contract BlockSelector is InstantiatorImpl, Decorated, CartesiMath {
    using SafeMath for uint256;

    uint256 constant C_256 = 256; // 256 blocks
    uint256 constant DIFFICULTY_BASE_MULTIPLIER = 256000000; //256 M
    uint256 constant ADJUSTMENT_BASE = 1000000; // 1M
    uint256 constant ONE_MILLION = 1000000;

    struct BlockSelectorCtx {
        mapping(uint256 => address) blockProducer; // block index to block producer
        uint256 blockCount; // how many blocks have been created
        uint256 lastBlockTimestamp; // timestamp of when current selection started
        uint256 difficulty; // difficulty parameter defines how big the interval will be
        uint256 minDifficulty; // lower bound for difficulty
        uint256 difficultyAdjustmentParameter; // how fast the difficulty gets adjusted to reach the desired interval, number * 1000000
        uint256 targetInterval; // desired block selection interval, used to tune difficulty
        uint256 currentGoalBlockNumber; // main chain block number which will decide current random target

        address posManagerAddress;

    }

    mapping(uint256 => BlockSelectorCtx) internal instance;

    event BlockProduced(
        uint256 indexed index,
        address indexed producer,
        uint256 blockNumber,
        uint256 roundDuration,
        uint256 difficulty,
        uint256 targetInterval
    );

    /// @notice Instantiates a BlockSelector structure
    /// @param _minDifficulty lower bound for difficulty parameter
    /// @param _initialDifficulty starting difficulty
    /// @param _difficultyAdjustmentParameter how quickly the difficulty gets updated
    /// according to the difference between time passed and target interval.
    /// @param _targetInterval how often we want produce blocks
    /// @param _posManagerAddress address of ProofOfStake that will use this instance
    function instantiate(
        uint256 _minDifficulty,
        uint256 _initialDifficulty,
        uint256 _difficultyAdjustmentParameter,
        uint256 _targetInterval,
        address _posManagerAddress
    ) public returns (uint256)
    {
        instance[currentIndex].minDifficulty = _minDifficulty;
        instance[currentIndex].difficulty = _initialDifficulty;
        instance[currentIndex].difficultyAdjustmentParameter = _difficultyAdjustmentParameter;
        instance[currentIndex].targetInterval = _targetInterval;
        instance[currentIndex].posManagerAddress = _posManagerAddress;

        instance[currentIndex].currentGoalBlockNumber = block.number + 1; // goal has to be in the future, so miner cant manipulate (easily)
        instance[currentIndex].lastBlockTimestamp = block.timestamp; // first selection starts when the instance is created

        active[currentIndex] = true;
        return currentIndex++;
    }

    /// @notice Calculates the log of the random number between the goal and callers address
    /// @param _index the index of the instance of block selector you want to interact with
    /// @param _user address to calculate log of random
    /// @return log of random number between goal and callers address * 1M
    function getLogOfRandom(uint256 _index, address _user) internal view returns (uint256) {
        bytes32 currentGoal = blockhash(
            getSeed(instance[_index].currentGoalBlockNumber, block.number)
        );
        bytes32 hashedAddress = keccak256(abi.encodePacked(_user));
        uint256 distance = uint256(keccak256(abi.encodePacked(hashedAddress, currentGoal)));

        return CartesiMath.log2ApproxTimes1M(distance);
    }

    /// @notice Produces a block
    /// @param _index the index of the instance of block selector you want to interact with
    /// @param _user address that has the right to produce block
    /// @param _weight number that will weight the random number, will be the number of staked tokens
    function produceBlock(uint256 _index, address _user, uint256 _weight) public returns (bool) {
        BlockSelectorCtx storage bsc = instance[_index];

        require(_weight > 0, "Caller can't have zero staked tokens");
        require(msg.sender == bsc.posManagerAddress, "Function can only be called by pos address");

        if (canProduceBlock(_index, _user, _weight)) {
            emit BlockProduced(
                _index,
                _user,
                bsc.blockCount,
                getMicrosecondsSinceLastBlock(_index),
                bsc.difficulty,
                bsc.targetInterval
            );

            return _blockProduced(_index, _user);
        }

        return false;
    }

    /// @notice Check if address is allowed to produce block
    /// @param _index the index of the instance of block selector you want to interact with
    /// @param _user the address that is gonna get checked
    /// @param _weight number that will weight the random number, most likely will be the number of staked tokens
    function canProduceBlock(uint256 _index, address _user, uint256 _weight) public view returns (bool) {
        BlockSelectorCtx storage bsc = instance[_index];

        // cannot produce if block selector goal hasnt been decided yet
        if (block.number <= bsc.currentGoalBlockNumber) {
            return false;
        }

        uint256 time = getMicrosecondsSinceLastBlock(_index);

        return (
            (_weight.mul(time)) > bsc.difficulty.mul((DIFFICULTY_BASE_MULTIPLIER - getLogOfRandom(_index, _user)))
        );
    }

    /// @notice Block produced, declare producer and adjust difficulty
    /// @param _index the index of the instance of block selector you want to interact with
    /// @param _user address of user that won the round
    function _blockProduced(uint256 _index, address _user) private returns (bool) {
        BlockSelectorCtx storage bsc = instance[_index];
        // declare producer
        bsc.blockProducer[bsc.blockCount] = _user;

        // adjust difficulty
        bsc.difficulty = getNewDifficulty(
            bsc.minDifficulty,
            bsc.difficulty,
            (block.timestamp).sub(bsc.lastBlockTimestamp),
            bsc.targetInterval,
            bsc.difficultyAdjustmentParameter
        );

        _reset(_index);
        return true;
    }

    /// @notice Reset instance, advancing round and choosing new goal
    /// @param _index the index of the instance of block selector you want to interact with
    function _reset(uint256 _index) private {
        BlockSelectorCtx storage bsc = instance[_index];

        bsc.blockCount++;
        bsc.currentGoalBlockNumber = block.number + 1;
        bsc.lastBlockTimestamp = block.timestamp;
    }

    function getSeed(
        uint256 _previousTarget,
        uint256 _currentBlock
    )
    internal
    pure
    returns (uint256)
    {
        uint256 diff = _currentBlock.sub(_previousTarget);
        uint256 res = diff.div(C_256);

        return _previousTarget.add(res.mul(C_256));
    }

    /// @notice Calculates new difficulty parameter
    /// @param _minDiff minimum difficulty of instance
    /// @param _oldDiff is the difficulty of previous round
    /// @param _timePassed is how long the previous round took
    /// @param _targetInterval is how long a round is supposed to take
    /// @param _adjustmentParam is how fast the difficulty gets adjusted,
    ///         should be number * 1000000
    function getNewDifficulty(
        uint256 _minDiff,
        uint256 _oldDiff,
        uint256 _timePassed,
        uint256 _targetInterval,
        uint256 _adjustmentParam
    )
    internal
    pure
    returns (uint256)
    {
        if (_timePassed < _targetInterval) {
            return _oldDiff.add(_oldDiff.mul(_adjustmentParam).div(ADJUSTMENT_BASE) + 1);
        } else if (_timePassed > _targetInterval) {
            uint256 newDiff = _oldDiff.sub(_oldDiff.mul(_adjustmentParam).div(ADJUSTMENT_BASE) + 1);

            return newDiff > _minDiff ? newDiff : _minDiff;
        }

        return _oldDiff;
    }

    /// @notice Returns the number of blocks
    /// @param _index the index of the instance of block selector to be interact with
    /// @return number of blocks
    function getBlockCount(uint256 _index) public view returns (uint256) {
        return instance[_index].blockCount;
    }

    /// @notice Returns last block timestamp
    /// @param _index the index of the instance of block selector to be interact with
    /// @return timestamp of when last block was created
    function getLastBlockTimestamp(uint256 _index) public view returns (uint256) {
        return instance[_index].lastBlockTimestamp;
    }

    /// @notice Returns current difficulty
    /// @param _index the index of the instance of block selector to be interact with
    /// @return difficulty of current selection
    function getDifficulty(uint256 _index) public view returns (uint256) {
        return instance[_index].difficulty;
    }

    /// @notice Returns min difficulty
    /// @param _index the index of the instance of block selector to be interact with
    /// @return min difficulty of instance
    function getMinDifficulty(uint256 _index) public view returns (uint256) {
        return instance[_index].minDifficulty;
    }

    /// @notice Returns difficulty adjustment parameter
    /// @param _index the index of the instance of block selector to be interact with
    /// @return difficulty adjustment parameter
    function getDifficultyAdjustmentParameter(
        uint256 _index
    )
    public
    view
    returns (uint256)
    {
        return instance[_index].difficultyAdjustmentParameter;
    }

    /// @notice Returns target interval
    /// @param _index the index of the instance of block selector to be interact with
    /// @return target interval
    function getTargetInterval(uint256 _index) public view returns (uint256) {
        return instance[_index].targetInterval;
    }

    /// @notice Returns time since last selection started, in microseconds
    /// @param _index the index of the instance of block selector to be interact with
    /// @return microseconds passed since last selection started
    function getMicrosecondsSinceLastBlock(uint256 _index) public view returns (uint256) {
        BlockSelectorCtx storage bsc = instance[_index];

        // time since selection started times 1e6 (microseconds)
        return ((block.timestamp).sub(bsc.lastBlockTimestamp)).mul(ONE_MILLION);
    }

    function getState(uint256 _index, address _user)
    public view returns (uint256[5] memory _uintValues) {
        BlockSelectorCtx storage i = instance[_index];

        uint256[5] memory uintValues = [
            block.number,
            i.currentGoalBlockNumber,
            i.difficulty,
            ((block.timestamp).sub(i.lastBlockTimestamp)).mul(ONE_MILLION), // time passed
            getLogOfRandom(_index, _user)
        ];

        return uintValues;
    }

    function isConcerned(uint256, address) public override pure returns (bool) {
        return false; // isConcerned is only for the main concern (PoS)
    }

    function getSubInstances(uint256, address)
        public override pure returns (address[] memory _addresses,
            uint256[] memory _indices)
    {
        address[] memory a;
        uint256[] memory i;

        a = new address[](0);
        i = new uint256[](0);

        return (a, i);
    }
}
