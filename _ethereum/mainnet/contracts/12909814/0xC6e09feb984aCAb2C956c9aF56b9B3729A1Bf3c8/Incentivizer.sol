/*
    Copyright 2021 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./RegistryAccessor.sol";
import "./Decimal.sol";
import "./Interfaces.sol";

/**
 * @title Incentivizer
 * @notice Generic incentivization contract that allows one ERC20 to be staked while earning
 *         either the same ERC20 or a different ERC20 as a reward
 * @dev Reward program can be adjusted or ended at any time through governance as long as there
 *      is sufficient balance. Architecture based off the Synthetix StakingRewards contract:
 *      https://github.com/Synthetixio/synthetix/blob/master/contracts/StakingRewards.sol
 */
contract Incentivizer is RegistryAccessor, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Decimal for Decimal.D256;

    /**
     * @notice Emitted when the reward program is updated with a rate `rate` completing `complete`
     */
    event RewardProgramUpdate(uint256 rate, uint256 complete);

    /**
     * @notice Emitted when the owner rescues `amount` of `token`
     */
    event Rescue(address token, uint256 amount);

    /**
     * @notice Emitted on reward accrual when `newReward` reward tokens are dispersed at
     *         timestamp `updated`, updating the rewards per unit to `rewardPerUnit`
     */
    event Settle(uint256 rewardPerUnit, uint256 newReward, uint256 updated);

    /**
     * @notice Emitted on when `account` stakes `amount` of the underlying token
     */
    event Stake(address account, uint256 amount);

    /**
     * @notice Emitted on when `account` withdraws `amount` of the underlying token
     */
    event Withdrawal(address account, uint256 amount);

    /**
     * @notice Emitted on when `account` claims `amount` of the reward token
     */
    event Claim(address account, uint256 amount);

    /**
     * @notice ERC20 token that will be used as underlying for staking
     */
    IERC20 public underlyingToken;

    /**
     * @notice ERC20 token that will be dispersed as rewards
     */
    IERC20 public rewardToken;

    /**
     * @notice Quantity of  rewardToken` dispersed to the entire staking pool per second
     */
    uint256 public rewardRate;

    /**
     * @notice Timestamp the current reward program ends
     */
    uint256 public rewardComplete;

    /**
     * @notice Timestamp that reward accrual was last settled
     */
    uint256 public rewardUpdated;

    /**
     * @notice Mapping of underlying token balance per account
     */
    mapping(address => uint256) public balanceOfUnderlying;

    /**
     * @notice Total underlying token balance staked in this contract
     */
    uint256 public totalUnderlying;

    /**
     * @notice Total outstanding unclaimed rewards that have accrued so far
     */
    uint256 public totalReward;

    /**
     * @notice Mapping of settled reward balance per account
     */
    mapping(address => uint256) internal _reward;

    /**
     * @notice Mapping of last settled rewardPerUnit per account
     */
    mapping(address => Decimal.D256) internal _settled;

    /**
     * @notice Monotonically increasing accumulator to track the reward amount per unit of staked underlying
     */
    Decimal.D256 internal _rewardPerUnit;


    /**
     * @notice Constructs the Incentivizer
     * @param underlying_ Underlying ERC20 token for staking
     * @param reward_ Reward ERC20 token for rewards
     * @notice registry_ Address of the Continuous ESDS contract registry
     */
    constructor(IERC20 underlying_, IERC20 reward_, address registry_) public {
        underlyingToken = underlying_;
        rewardToken = reward_;
        setRegistry(registry_);
    }

    // ADMIN

    /**
     * @notice Updates the rate and completion time for this contract's reward program
     * @dev Owner only - governance hook
     *      Insufficient funds will revert - excess funds will be refunded to the reserve
     * @param rate Reward token amount to disperse to enter staking pool per second
     * @param complete Timestamp the reward program ends
     */
    function updateRewardProgram(uint256 rate, uint256 complete) external onlyOwner {
        require(complete > block.timestamp, "Incentivizer: already ended");

        _settle();

        // Set new reward rate
        (rewardRate, rewardComplete, rewardUpdated) = (rate, complete, block.timestamp);

        // Return rewards in excess of the required amount
        (, uint256 excessRewards) = _verifyBalance();
        rewardToken.safeTransfer(registry.reserve(), excessRewards);

        emit RewardProgramUpdate(rate, complete);
    }

    /**
     * @notice Allows the owner to withdraw stuck ERC20 tokens to the reserve
     * @dev Owner only - governance hook
     *      Non-reentrant
     *      Cannot withdraw the underlying token
     *      Cannot withdraw more of the reward token than is needed for the current reward program
     * @param token ERC20 token to withdraw
     * @param amount Amount to withdraw
     */
    function rescue(address token, uint256 amount) external nonReentrant onlyOwner {
        IERC20(token).safeTransfer(registry.reserve(), amount);

        if (token == address(rewardToken) || token == address(underlyingToken)) {
            _verifyBalance();
        }

        emit Rescue(token, amount);
    }

    /**
     * @notice Verifies the underlying and reward balances of this contract cover all outstanding liabilities
     * @dev Internal only - helper
     *      Reverts if there are any insufficient funds
     * @return (excess underlying balance, excess reward balance), values are equal if underlyingToken == rewardToken
     */
    function _verifyBalance() private view returns (uint256, uint256) {
        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
        uint256 underlyingTokenBalance = underlyingToken.balanceOf(address(this));

        uint256 underlyingRequirement = totalUnderlying;
        uint256 rewardRequirement = totalReward.add(totalProvisionedReward());

        return (
            underlyingTokenBalance
                .sub(totalUnderlying, "Incentivizer: insufficient underlying")
                .sub(underlyingToken == rewardToken ? rewardRequirement : 0, "Incentivizer: insufficient rewards"),
            rewardTokenBalance
                .sub(rewardRequirement, "Incentivizer: insufficient rewards")
                .sub(underlyingToken == rewardToken ? underlyingRequirement : 0, "Incentivizer: insufficient underlying")
        );
    }

    // FLYWHEEL

    /**
     * @notice Total rewards that have been provisioned for the current reward program,
     *         but not yet settled or paid out
     * @return Total provisioned rewards
     */
    function totalProvisionedReward() public view returns (uint256) {
        uint256 complete = rewardComplete;
        uint256 updated = rewardUpdated;

        return complete > updated ? complete.sub(updated).mul(rewardRate) : 0;
    }

    /**
     * @notice Returns either the current timestamp or the last applicable timestamp of the reward program
     * @return Most recent reward-applicable timestamp
     */
    function nowOrComplete() public view returns (uint256) {
        uint256 complete = rewardComplete;
        uint256 latest = block.timestamp;

        return latest > complete ? complete : latest;
    }

    /**
     * @notice Monotonically increasing accumulator to track the reward amount per unit of staked underlying
     * @dev Computes the current effective rewardPerUnit value as if there was a settlement now
     * @return Effective rewards per unit
     */
    function rewardPerUnit() public view returns (Decimal.D256 memory) {
        if (totalUnderlying == 0) {
            return _rewardPerUnit;
        } else {
            return _rewardPerUnit
                .add(Decimal.from(nowOrComplete().sub(rewardUpdated).mul(rewardRate)).div(totalUnderlying));
        }
    }

    /**
     * @notice Accrues and updates rewards since last settlement
     * @dev Internal only
     */
    function _settle() internal {
        uint256 nowOrComplete = nowOrComplete();
        Decimal.D256 memory newRewardPerUnit = rewardPerUnit();
        uint256 newReward = newRewardPerUnit.sub(_rewardPerUnit).mul(totalUnderlying).asUint256();
        uint256 newTotalReward = totalReward.add(newReward);

        _rewardPerUnit = newRewardPerUnit;
        totalReward = newTotalReward;
        rewardUpdated = nowOrComplete;

        emit Settle(newRewardPerUnit.value, newReward, nowOrComplete);
    }

    /**
     * @notice Accrues and records rewards for `account` to simplify accounting math
     * @dev Internal only
     * @param account Account to settle rewards for
     */
    function _settleAccount(address account) internal {
        _settle();

        _reward[account] = balanceOfReward(account);
        _settled[account] = _rewardPerUnit;
    }

    // EXTERNAL

    /**
     * @notice Balance of all accrued rewards (including unsettled) for `account`
     * @param account Account to retrieve balance for
     */
    function balanceOfReward(address account) public view returns (uint256) {
        return _reward[account].add(
            rewardPerUnit().sub(_settled[account])   // Since last checkpoint
                .mul(balanceOfUnderlying[account])   // Multiply per unit
                .asUint256()                         // Convert and truncate
        );
    }

    /**
     * @notice Deposit `amount` underlying tokens to start accruing rewards
     * @dev Non-reentrant
     * @param amount Amount of underlying tokens for the caller to deposit
     */
    function stake(uint256 amount) external nonReentrant {
        require(amount != 0, "Incentivizer: zero amount");

        _settleAccount(msg.sender);

        // Increment account balance
        balanceOfUnderlying[msg.sender] = balanceOfUnderlying[msg.sender].add(amount);
        totalUnderlying = totalUnderlying.add(amount);

        // Transfer in token amount
        underlyingToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Stake(msg.sender, amount);
    }

    /**
     * @notice Withdraw `amount` underlying tokens
     * @dev Non-reentrant
     * @param amount Amount of underlying tokens for the caller to withdraw
     */
    function withdraw(uint256 amount) public nonReentrant {
        require(amount != 0, "Incentivizer: zero amount");

        _settleAccount(msg.sender);

        // Decrement account balance
        balanceOfUnderlying[msg.sender] = balanceOfUnderlying[msg.sender].sub(amount, "Incentivizer: insufficient balance");
        totalUnderlying = totalUnderlying.sub(amount, "Incentivizer: insufficient balance");

        // Transfer out token amount
        underlyingToken.safeTransfer(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @notice Claim all accrued reward tokens for caller
     * @dev Non-reentrant
     */
    function claim() public nonReentrant {
        _settleAccount(msg.sender);

        uint256 rewardBalance = _reward[msg.sender];
        rewardToken.safeTransfer(msg.sender, rewardBalance);

        _reward[msg.sender] = 0;
        totalReward = totalReward.sub(rewardBalance);

        emit Claim(msg.sender, rewardBalance);
    }

    /**
     * @notice Claim all accrued reward tokens withdraw all underlying tokens for caller
     */
    function exit() external {
        withdraw(balanceOfUnderlying[msg.sender]);
        claim();
    }
}
