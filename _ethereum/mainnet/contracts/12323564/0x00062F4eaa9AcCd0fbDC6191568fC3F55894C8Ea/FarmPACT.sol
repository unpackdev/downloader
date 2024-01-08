// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./AbstractFarm.sol";
import "./SafeMath.sol";
import "./GovernanceOwnable.sol";

// Cloned and modified from https://github.com/ltonetwork/uniswap-farming/blob/master/contracts/Farm.sol
contract FarmPACT is GovernanceOwnable, AbstractFarm {
    using SafeMath for uint256;

    uint256 _blockGenerationFrequency;
    function blockGenerationFrequency() public view returns (uint256) {
        return _blockGenerationFrequency;
    }

    // etherium - block_generation_frequency_ ~ 15s
    // binance smart chain - block_generation_frequency_ ~ 4s
    constructor(
        address governance_,
        IERC20 pact_,
        uint256 blockGenerationFrequency_,
        uint256 totalRewardAmount_
    ) GovernanceOwnable(governance_) AbstractFarm(pact_, totalRewardAmount_) public {
        require(blockGenerationFrequency_ > 0, "constructor: blockGenerationFrequency is empty");
        _blockGenerationFrequency = blockGenerationFrequency_;
    }

    function startFarming(uint256 startBlock) public onlyGovernance {
        require(_lastStageEndBlock == 0, "startFarming: already started");
        uint currentBalance = _pact.balanceOf(address(this));
        require(currentBalance >= _totalRewardAmount, "startFarming: currentBalance is not enough");

        _addFirstStage(startBlock, 10 days / _blockGenerationFrequency, _totalRewardAmount / 8);
        _addStage(20 days / _blockGenerationFrequency, _totalRewardAmount / 8);
        _addStage(150 days / _blockGenerationFrequency, _totalRewardAmount / 8);
        _addStage(180 days / _blockGenerationFrequency, _totalRewardAmount / 8);
        _addStage(1080 days / _blockGenerationFrequency, _totalRewardAmount / 2);
    }

    function addLpToken(uint256 _allocPoint, address _lpToken, bool _withUpdate) public onlyGovernance {
        _addLpToken(_allocPoint, IUniswapV2Pair(_lpToken), _withUpdate);
    }

    function updateLpToken(uint256 poolId, uint256 allocPoint, bool withUpdate) public onlyGovernance {
        _updateLpToken(poolId, allocPoint, withUpdate);
    }
}