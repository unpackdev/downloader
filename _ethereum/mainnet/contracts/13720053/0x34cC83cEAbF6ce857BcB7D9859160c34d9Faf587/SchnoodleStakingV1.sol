// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ABDKMath64x64.sol";

/// @author Jason Payne (https://twitter.com/Neo42)
/// Delivers Lambo posthaste
contract SchnoodleStakingV1 is Initializable, OwnableUpgradeable {
    address private _schnoodle;
    uint256 _stakeId;
    mapping(address => Stake[]) private _accountStakes;
    mapping(address => Unbond[]) private _accountUnbonds;
    mapping(address => uint256) private _balances;
    uint256 private _totalTokens;
    uint256 private _cumulativeTotal;
    uint256 private _checkpointBlock;
    uint256 private _totalStakeWeight;

    // Adjust to change the sigmoid curve of the multiplier
    SigmoidParams private _sigmoidParams;

    struct Stake {
        uint256 id;
        uint256 amount;
        uint256 blockNumber;
        uint256 vestingBlocks;
        uint256 unbondingBlocks;
        uint256 multiplier;
    }

    struct StakeReward {
        Stake stake;
        uint256 reward;
    }

    struct Unbond {
        uint256 amount;
        uint256 expiryBlock;
    }

    struct SigmoidParams {
        uint256 k; // Higher value increases slope severity
        uint256 a; // Higher value increases slope severity and shifts right
    }

    function initialize(address schnoodle) public initializer {
        __Ownable_init();
        _schnoodle = schnoodle;
        _sigmoidParams = SigmoidParams(5, 1);
    }

    /// Stakes the specified amount of tokens for the sender, and adds the details to a stored stake object
    function addStake(uint256 amount, uint256 vestingBlocks, uint256 unbondingBlocks) external {
        address msgSender = _msgSender();

        require(amount <= balanceOf(msgSender) - lockedBalanceOf(msgSender), "SchnoodleStaking: stake amount exceeds unstaked balance");

        Stake memory stake;
        uint256 cumulativeTotal;

        // Build the new stake, and update all tracking states to include the new stake
        (stake, cumulativeTotal, _totalTokens, _totalStakeWeight) = _buildStake(amount, vestingBlocks, unbondingBlocks);
        _stakeId++;
        _accountStakes[msgSender].push(stake);
        _cumulativeTotal = cumulativeTotal;
        _checkpointBlock = stake.blockNumber;
        _balances[msgSender] += amount;

        emit Staked(msgSender, amount, stake.blockNumber);
    }

    /// Withdraws the specified amount of tokens from the sender's stake with the specified ID
    function withdraw(uint256 id, uint256 amount) external {
        address msgSender = _msgSender();
        uint256 blockNumber = block.number;
        Unbond[] storage unbonds = _accountUnbonds[msgSender];

        // Take this opportunity to clean up any expired unbonds
        for (uint256 i = unbonds.length; i > 0; i--) {
            if (unbonds[i - 1].expiryBlock <= blockNumber) {
                unbonds[i - 1] = unbonds[unbonds.length - 1];
                unbonds.pop();
            }
        }

        Stake[] storage stakes = _accountStakes[msgSender];

        for (uint256 i = 0; i < stakes.length; i++) {
            Stake storage stake = stakes[i];
            if (stake.id == id) {
                require(stake.amount >= amount, "SchnoodleStaking: cannot withdraw more than staked");
                require(stake.blockNumber + stake.vestingBlocks < blockNumber, "SchnoodleStaking: cannot withdraw during vesting blocks");

                (uint256 netReward, uint256 grossReward, uint256 newCumulativeTotal) = _rewardInfo(stake, amount, blockNumber);

                // Update all tracking states to remove the withdrawn stake
                (_totalTokens, _totalStakeWeight) = _updateTracking(-int256(amount), stake.vestingBlocks, stake.unbondingBlocks);
                _cumulativeTotal = newCumulativeTotal;
                _checkpointBlock = blockNumber;
                _balances[msgSender] -= amount;
                stake.amount -= amount;

                // Start the unbonding procedure for the withdrawn amount
                unbonds.push(Unbond(amount, blockNumber + stake.unbondingBlocks));

                // Remove the stake if it is fully withdrawn by replacing it with the last stake in the array
                if (stake.amount == 0) {
                    stakes[i] = stakes[stakes.length - 1];
                    stakes.pop();
                }

                stakingReward(msgSender, netReward, grossReward);

                emit Withdrawn(msgSender, id, amount, netReward, grossReward);
                return;
            }
        }

        revert("SchnoodleStaking: stake not found");
    }

    function changeSigmoidParams(uint256 k, uint256 a) external onlyOwner {
        _sigmoidParams = SigmoidParams(k, a);
    }

    function sigmoidParams() external view returns(SigmoidParams memory) {
        return _sigmoidParams;
    }

    function reward(uint256 amount, uint256 vestingBlocks, uint256 unbondingBlocks, uint256 rewardBlock) external view returns(uint256) {
        (Stake memory stake, uint256 cumulativeTotal, uint256 totalTokens, uint256 totalStakeWeight) = _buildStake(amount, vestingBlocks, unbondingBlocks);
        return _reward(stake, stake.blockNumber, rewardBlock, cumulativeTotal, totalStakeWeight, totalTokens);
    }

    function reward(address account, uint256 index, uint256 rewardBlock) external view returns(uint256) {
        return _reward(_accountStakes[account][index], rewardBlock);
    }

    function _reward(Stake memory stake, uint256 rewardBlock) private view returns(uint256) {
        return _reward(stake, _checkpointBlock, rewardBlock, _cumulativeTotal, _totalStakeWeight, _totalTokens);
    }

    function _reward(Stake memory stake, uint256 checkpointBlock, uint256 rewardBlock, uint256 cumulativeTotal, uint256 totalStakeWeight, uint256 totalTokens) private view returns(uint256) {
        (uint256 netReward,,) = _rewardInfo(stake, stake.amount, checkpointBlock, rewardBlock, cumulativeTotal, totalStakeWeight, totalTokens);
        return netReward;
    }

    function _rewardInfo(Stake memory stake, uint256 amount, uint256 rewardBlock) private view returns(uint256, uint256, uint256) {
        return _rewardInfo(stake, amount, _checkpointBlock, rewardBlock, _cumulativeTotal, _totalStakeWeight, _totalTokens);
    }

    function _rewardInfo(Stake memory stake, uint256 amount, uint256 checkpointBlock, uint256 rewardBlock, uint256 cumulativeTotal, uint256 totalStakeWeight, uint256 totalTokens) private view returns(uint256, uint256, uint256) {
        // Calculate the stake amount multiplied across the number of blocks since the start of the stake
        uint256 cumulativeAmount = amount * (rewardBlock - stake.blockNumber);

        // Get the new cumulative total of all stakes as the current stored value is from the previous staking activity
        uint256 newCumulativeTotal = _newCumulativeTotal(checkpointBlock, rewardBlock, cumulativeTotal, totalTokens);

        if (cumulativeAmount > 0 && totalStakeWeight > 0) {
            // Calculate the reward as a relative proportion of the cumulative total of all holders' stakes, adjusted by the multiplier
            uint256 grossReward = balanceOf(stakingFund()) * cumulativeAmount / newCumulativeTotal;
            uint256 netReward = stake.multiplier * grossReward / 1000;

            // The returned new cumulative total should not include the rewarded amount
            return (netReward, grossReward, newCumulativeTotal - cumulativeAmount);
        }

        return (0, 0, newCumulativeTotal);
    }

    function _buildStake(uint256 amount, uint256 vestingBlocks, uint256 unbondingBlocks) private view returns (Stake memory, uint256, uint256, uint256) {
        require(amount > 0, "SchnoodleStaking: Stake amount must be greater than zero");
        require(vestingBlocks > 0, "SchnoodleStaking: Vesting blocks must be greater than zero");
        require(unbondingBlocks > 0, "SchnoodleStaking: Unbonding blocks must be greater than zero");

        (uint256 totalTokens, uint256 totalStakeWeight) = _updateTracking(int256(amount), vestingBlocks, unbondingBlocks);
        uint256 lockProductWeightedAverage = totalStakeWeight / totalTokens;

        // Calculate a reward multiplier based on a sigmoid curve defined by logistic function 1 ÷ (1 + e⁻ˣ) where x is the stake's lock product delta from the weighted average
        int128 x = ABDKMath64x64.mul(
            ABDKMath64x64.div(
                ABDKMath64x64.fromInt(-int256(_sigmoidParams.k)),
                ABDKMath64x64.fromUInt(lockProductWeightedAverage)
            ),
            ABDKMath64x64.fromInt(int256(vestingBlocks * unbondingBlocks) - int256(lockProductWeightedAverage))
        );

        int128 one = ABDKMath64x64.fromUInt(1);
        uint256 multiplier = ABDKMath64x64.toUInt(
            ABDKMath64x64.mul(
                ABDKMath64x64.fromUInt(1000),
                ABDKMath64x64.div(
                    one,
                    ABDKMath64x64.add(
                        one,
                        ABDKMath64x64.pow(
                            ABDKMath64x64.exp(x),
                            _sigmoidParams.a
                        )
                    )
                )
            )
        );

        uint256 blockNumber = block.number;
        return (Stake(_stakeId, amount, blockNumber, vestingBlocks, unbondingBlocks, multiplier), _newCumulativeTotal(blockNumber), totalTokens, totalStakeWeight);
    }

    function _newCumulativeTotal(uint256 rewardBlock) private view returns(uint256) {
        return _newCumulativeTotal(_checkpointBlock, rewardBlock, _cumulativeTotal, _totalTokens);
    }

    function _newCumulativeTotal(uint256 checkpointBlock, uint256 rewardBlock, uint256 cumulativeTotal, uint256 totalTokens) private pure returns(uint256) {
        // Add the total of all stakes multiplied across all blocks since the previous checkpoint calculation to the cumulative total
        return cumulativeTotal + totalTokens * (rewardBlock - checkpointBlock);
    }

    function _updateTracking(int256 amountDelta, uint256 vestingBlocks, uint256 unbondingBlocks) private view returns(uint256, uint256) {
        return (
            uint256(int256(_totalTokens) + amountDelta), // Update total tokens
            uint256(int256(_totalStakeWeight) + amountDelta * int256(vestingBlocks) * int256(unbondingBlocks)) // Update total stake weight
        );
    }

    function stakedBalanceOf(address account) public view returns(uint256) {
        return _balances[account];
    }

    function unbondingBalanceOf(address account) public view returns(uint256) {
        uint256 blockNumber = block.number;
        uint256 total;
        Unbond[] storage unbonds = _accountUnbonds[account];

        for (uint256 i = 0; i < unbonds.length; i++) {
            Unbond memory unbond = unbonds[i];
            if (unbond.expiryBlock > blockNumber) {
                total += unbond.amount;
            }
        }

        return total;
    }

    function lockedBalanceOf(address account) public view returns (uint256) {
        return unbondingBalanceOf(account) + stakedBalanceOf(account);
    }

    function stakingSummary(address account) public view returns(StakeReward[] memory) {
        Stake[] storage stakes = _accountStakes[account];
        StakeReward[] memory stakeRewards = new StakeReward[](stakes.length);
        uint256 rewardBlock = block.number;

        for (uint256 i = 0; i < stakes.length; i++) {
            stakeRewards[i] = StakeReward(stakes[i], _reward(stakes[i], rewardBlock));
        }

        return stakeRewards;
    }

    function unbondingSummary(address account) public view returns(Unbond[] memory) {
        return _accountUnbonds[account];
    }

    // Calls to the Schnoodle proxy contract

    function stakingFund() private view returns (address) {
        (bool success, bytes memory result) = _schnoodle.staticcall(abi.encodeWithSignature("stakingFund()"));
        assert(success);
        return abi.decode(result, (address));
    }

    function balanceOf(address account) private view returns(uint256) {
        (bool success, bytes memory result) = _schnoodle.staticcall(abi.encodeWithSignature("balanceOf(address)", account));
        assert(success);
        return abi.decode(result, (uint256));
    }

    function stakingReward(address account, uint256 netReward, uint256 grossReward) private {
        (bool success,) = _schnoodle.call(abi.encodeWithSignature("stakingReward(address,uint256,uint256)", account, netReward, grossReward));
        assert(success);
    }

    // Events

    event Staked(address indexed account, uint256 amount, uint256 blockNumber);

    event Withdrawn(address indexed account, uint256 id, uint256 amount, uint256 netReward, uint256 grossReward);
}
