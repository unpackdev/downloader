// contracts/SchnoodleFarmingV2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./ABDKMath64x64.sol";

/// @author Jason Payne (https://twitter.com/Neo42)
contract SchnoodleFarmingV2 is Initializable, OwnableUpgradeable {
    address private _schnoodle;
    uint256 _depositId;
    mapping(address => Deposit[]) private _accountDeposits;
    mapping(address => Unbond[]) private _accountUnbonds;
    mapping(address => uint256) private _balances;
    uint256 private _totalTokens;
    uint256 private _cumulativeTotal;
    uint256 private _checkpointBlock;
    uint256 private _totalDepositWeight;

    // Adjust to change the sigmoid curve of the multiplier
    SigmoidParams private _sigmoidParams;

    uint256 private _vestingBlocksFactor;
    uint256 private _unbondingBlocksFactor;
    uint256 private _maxUnbondingBlocks;

    struct Deposit {
        uint256 id;
        uint256 amount;
        uint256 blockNumber;
        uint256 vestingBlocks;
        uint256 unbondingBlocks;
        uint256 multiplier;
    }

    struct DepositReward {
        Deposit deposit;
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

    function configure() external onlyOwner {
        _vestingBlocksFactor = 1000;
        _unbondingBlocksFactor = 20;
        _maxUnbondingBlocks = 3000000;
    }

    // Deposit functions

    /// Deposits the specified amount of tokens for the sender, and adds the details to a stored deposit object
    function addDeposit(uint256 amount, uint256 vestingBlocks, uint256 unbondingBlocks) external {
        address msgSender = _msgSender();

        require(amount <= balanceOf(msgSender) - lockedBalanceOf(msgSender), "SchnoodleFarming: deposit amount exceeds unlocked balance");

        Deposit memory deposit;
        uint256 cumulativeTotal;

        // Build the new deposit, and update all tracking states to include the new deposit
        (deposit, cumulativeTotal, _totalTokens, _totalDepositWeight) = _buildDeposit(amount, vestingBlocks, unbondingBlocks);
        _depositId++;
        _accountDeposits[msgSender].push(deposit);
        _cumulativeTotal = cumulativeTotal;
        _checkpointBlock = deposit.blockNumber;
        _balances[msgSender] += amount;

        emit Deposited(msgSender, deposit.id, deposit.amount, deposit.vestingBlocks, deposit.unbondingBlocks, deposit.multiplier, _totalTokens, _totalDepositWeight, _cumulativeTotal);
    }

    /// Updates the vesting blocks and unbonding blocks of the sender's deposit with the specified ID
    function updateDeposit(uint256 id, uint256 vestingBlocks, uint256 unbondingBlocks) external {
        address msgSender = _msgSender();
        (Deposit storage deposit,,) = _getDeposit(msgSender, id);
        deposit.vestingBlocks = vestingBlocks;
        deposit.unbondingBlocks = unbondingBlocks;
        (uint256 multiplier,,) = _getMultiplier(deposit.amount, vestingBlocks, unbondingBlocks);
        require(multiplier > deposit.multiplier, "SchnoodleFarming: no benefit to update deposit with supplied changes");
        deposit.multiplier = multiplier;

        emit UpdatedDeposit(msgSender, id, deposit.vestingBlocks, deposit.unbondingBlocks, deposit.multiplier);
    }

    /// Withdraws the specified amount of tokens from the sender's deposit with the specified ID
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

        (Deposit storage deposit, Deposit[] storage deposits, uint256 index) = _getDeposit(msgSender, id);
        require(deposit.amount >= amount, "SchnoodleFarming: cannot withdraw more than deposited");
        require(deposit.blockNumber + _vestingBlocksFactor * deposit.vestingBlocks / 1000 < blockNumber, "SchnoodleFarming: cannot withdraw during vesting blocks");

        (uint256 netReward, uint256 grossReward, uint256 newCumulativeTotal) = _getRewardInfo(deposit, amount, blockNumber);

        // Update all tracking states to remove the withdrawn deposit
        (_totalTokens, _totalDepositWeight) = _getAggregatedTotals(-int256(amount), deposit.vestingBlocks, deposit.unbondingBlocks);
        _cumulativeTotal = newCumulativeTotal;
        _checkpointBlock = blockNumber;
        _balances[msgSender] -= amount;
        deposit.amount -= amount;

        // Start the unbonding procedure for the withdrawn amount
        unbonds.push(Unbond(amount, blockNumber + _unbondingBlocksFactor * deposit.unbondingBlocks / 1000));

        // Remove the deposit if it is fully withdrawn by replacing it with the last deposit in the array
        if (deposit.amount == 0) {
            deposits[index] = deposits[deposits.length - 1];
            deposits.pop();
        }

        farmingReward(msgSender, netReward, grossReward);

        emit Withdrawn(msgSender, id, amount, netReward, grossReward, _totalTokens, _totalDepositWeight, _cumulativeTotal);
    }

    function _buildDeposit(uint256 amount, uint256 vestingBlocks, uint256 unbondingBlocks) private view returns (Deposit memory, uint256, uint256, uint256) {
        (uint256 multiplier, uint256 totalTokens, uint256 totalDepositWeight) = _getMultiplier(amount, vestingBlocks, unbondingBlocks);
        uint256 blockNumber = block.number;
        return (Deposit(_depositId, amount, blockNumber, vestingBlocks, unbondingBlocks, multiplier), _getCumulativeTotal(blockNumber), totalTokens, totalDepositWeight);
    }

    function _getDeposit(address account, uint256 id) private view returns(Deposit storage, Deposit[] storage, uint256) {
        Deposit[] storage deposits = _accountDeposits[account];

        for (uint256 i = 0; i < deposits.length; i++) {
            Deposit storage deposit = deposits[i];
            if (deposit.id == id) {
                return (deposit, deposits, i);
            }
        }

        revert("SchnoodleFarming: deposit not found");
    }

    function changeVestingBlocksFactor(uint256 rate) external onlyOwner {
        _vestingBlocksFactor = rate;
        emit VestingBlocksFactorChanged(rate);
    }

    function getVestingBlocksFactor() external view returns(uint256) {
        return _vestingBlocksFactor;
    }

    function changeUnbondingBlocksFactor(uint256 rate) external onlyOwner {
        _unbondingBlocksFactor = rate;
        emit UnbondingBlocksFactorChanged(rate);
    }

    function getUnbondingBlocksFactor() external view returns(uint256) {
        return _unbondingBlocksFactor;
    }

    function changeMaxUnbondingBlocks(uint256 max) external onlyOwner {
        _maxUnbondingBlocks = max;
        emit MaxUnbondingBlocksChanged(max);
    }

    function getMaxUnbondingBlocks() external view returns(uint256) {
        return _maxUnbondingBlocks;
    }

    // Reward calculation functions

    function getReward(uint256 amount, uint256 vestingBlocks, uint256 unbondingBlocks, uint256 rewardBlock) external view returns(uint256) {
        (Deposit memory deposit, uint256 cumulativeTotal, uint256 totalTokens, uint256 totalDepositWeight) = _buildDeposit(amount, vestingBlocks, unbondingBlocks);
        return _getReward(deposit, rewardBlock, deposit.blockNumber, cumulativeTotal, totalDepositWeight, totalTokens);
    }

    function getReward(address account, uint256 id, uint256 rewardBlock) external view returns(uint256) {
        (Deposit memory deposit,,) = _getDeposit(account, id);
        return _getReward(deposit, rewardBlock);
    }

    function _getReward(Deposit memory deposit, uint256 rewardBlock) private view returns(uint256) {
        return _getReward(deposit, rewardBlock, _checkpointBlock, _cumulativeTotal, _totalDepositWeight, _totalTokens);
    }

    function _getReward(Deposit memory deposit, uint256 rewardBlock, uint256 checkpointBlock, uint256 cumulativeTotal, uint256 totalDepositWeight, uint256 totalTokens) private view returns(uint256) {
        (uint256 netReward,,) = _getRewardInfo(deposit, deposit.amount, rewardBlock, checkpointBlock, cumulativeTotal, totalDepositWeight, totalTokens);
        return netReward;
    }

    function _getRewardInfo(Deposit memory deposit, uint256 amount, uint256 rewardBlock) private view returns(uint256, uint256, uint256) {
        return _getRewardInfo(deposit, amount, rewardBlock, _checkpointBlock, _cumulativeTotal, _totalDepositWeight, _totalTokens);
    }

    function _getRewardInfo(Deposit memory deposit, uint256 amount, uint256 rewardBlock, uint256 checkpointBlock, uint256 cumulativeTotal, uint256 totalDepositWeight, uint256 totalTokens) private view returns(uint256, uint256, uint256) {
        // Calculate the deposit amount multiplied across the number of blocks since the start of the deposit
        uint256 cumulativeAmount = amount * (MathUpgradeable.max(rewardBlock, deposit.blockNumber) - deposit.blockNumber);

        // Get the new cumulative total of all deposits as the current stored value is from the previous farming activity
        uint256 newCumulativeTotal = _getCumulativeTotal(rewardBlock, checkpointBlock, cumulativeTotal, totalTokens);

        if (cumulativeAmount > 0 && totalDepositWeight > 0) {
            // Calculate the reward as a relative proportion of the cumulative total of all holders' deposits, adjusted by the multiplier
            uint256 grossReward = balanceOf(getFarmingFund()) * cumulativeAmount / newCumulativeTotal;
            uint256 netReward = deposit.multiplier * grossReward / 1000;

            // The returned new cumulative total should not include the rewarded amount
            return (netReward, grossReward, newCumulativeTotal - cumulativeAmount);
        }

        return (0, 0, newCumulativeTotal);
    }

    // Vestiplier functions

    function _getMultiplier(uint256 amount, uint256 vestingBlocks, uint256 unbondingBlocks) private view returns(uint256, uint256, uint256) {
        require(amount > 0, "SchnoodleFarming: deposit amount must be greater than zero");
        require(vestingBlocks > 0, "SchnoodleFarming: vesting blocks must be greater than zero");
        require(unbondingBlocks > 0, "SchnoodleFarming: unbonding blocks must be greater than zero");
        require(unbondingBlocks <= _maxUnbondingBlocks, "SchnoodleFarming: unbonding blocks is greater than the defined maximum");

        (uint256 totalTokens, uint256 totalDepositWeight) = _getAggregatedTotals(int256(amount), vestingBlocks, unbondingBlocks);
        uint256 lockProductWeightedAverage = totalDepositWeight / totalTokens;

        // Calculate a reward multiplier based on a sigmoid curve defined by logistic function 1 ÷ (1 + eᶻ)ᵃ where z = -k₀(x - x₀)
        int128 z = ABDKMath64x64.mul(
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
                    ABDKMath64x64.pow(
                        ABDKMath64x64.add(
                            one,
                            ABDKMath64x64.exp(z)
                        ),
                        _sigmoidParams.a
                    )
                )
            )
        );

        return (multiplier, totalTokens, totalDepositWeight);
    }

    function changeSigmoidParams(uint256 k, uint256 a) external onlyOwner {
        _sigmoidParams = SigmoidParams(k, a);
    }

    function sigmoidParams() external view returns(SigmoidParams memory) {
        return _sigmoidParams;
    }

    // Autoregulator functions
    
    function _getCumulativeTotal(uint256 rewardBlock) private view returns(uint256) {
        return _getCumulativeTotal(rewardBlock, _checkpointBlock, _cumulativeTotal, _totalTokens);
    }

    function _getCumulativeTotal(uint256 rewardBlock, uint256 checkpointBlock, uint256 cumulativeTotal, uint256 totalTokens) private pure returns(uint256) {
        // Add the total of all deposits multiplied across all blocks since the previous checkpoint calculation to the cumulative total
        return cumulativeTotal + totalTokens * (rewardBlock - checkpointBlock);
    }

    function _getAggregatedTotals(int256 amountDelta, uint256 vestingBlocks, uint256 unbondingBlocks) private view returns(uint256, uint256) {
        return (
            uint256(int256(_totalTokens) + amountDelta), // Aggregate total tokens
            uint256(int256(_totalDepositWeight) + amountDelta * int256(vestingBlocks) * int256(unbondingBlocks)) // Aggregate total deposit weight
        );
    }

    // Balance functions

    function depositedBalanceOf(address account) public view returns(uint256) {
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
        return unbondingBalanceOf(account) + depositedBalanceOf(account);
    }

    // Summary functions

    function getFarmingSummary(address account) public view returns(DepositReward[] memory) {
        Deposit[] storage deposits = _accountDeposits[account];
        DepositReward[] memory depositRewards = new DepositReward[](deposits.length);
        uint256 rewardBlock = block.number;

        for (uint256 i = 0; i < deposits.length; i++) {
            depositRewards[i] = DepositReward(deposits[i], _getReward(deposits[i], rewardBlock));
        }

        return depositRewards;
    }

    function getUnbondingSummary(address account) public view returns(Unbond[] memory) {
        return _accountUnbonds[account];
    }

    // Calls to the Schnoodle proxy contract

    function getFarmingFund() private view returns (address) {
        (bool success, bytes memory result) = _schnoodle.staticcall(abi.encodeWithSignature("getFarmingFund()"));
        assert(success);
        return abi.decode(result, (address));
    }

    function balanceOf(address account) private view returns(uint256) {
        (bool success, bytes memory result) = _schnoodle.staticcall(abi.encodeWithSignature("balanceOf(address)", account));
        assert(success);
        return abi.decode(result, (uint256));
    }

    function farmingReward(address account, uint256 netReward, uint256 grossReward) private {
        (bool success,) = _schnoodle.call(abi.encodeWithSignature("farmingReward(address,uint256,uint256)", account, netReward, grossReward));
        assert(success);
    }

    // Events

    event Deposited(address indexed account, uint256 depositId, uint256 amount, uint256 vestingBlocks, uint256 unbondingBlocks, uint256 multiplier, uint256 totalTokens, uint256 totalDepositWeight, uint256 cumulativeTotal);

    event UpdatedDeposit(address indexed account, uint256 depositId, uint256 vestingBlocks, uint256 unbondingBlocks, uint256 multiplier);

    event Withdrawn(address indexed account, uint256 depositId, uint256 amount, uint256 netReward, uint256 grossReward, uint256 totalTokens, uint256 totalDepositWeight, uint256 cumulativeTotal);

    event VestingBlocksFactorChanged(uint256 rate);

    event UnbondingBlocksFactorChanged(uint256 rate);

    event MaxUnbondingBlocksChanged(uint256 max);
}
