// SPDX-License-Identifier: MIT

/* Borrowed heavily from Synthetix

* MIT License
* ===========
*
* Copyright (c) 2021 Synthetix
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
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./IERC20.sol";

import "./IBankNodeManager.sol";

import "./SafeERC20.sol";
import "./SafeMath.sol";

/// @title BNPL bank node lending reward system contract
///
/// @dev This contract is inherited by the `BankNodeLendingRewards` contract
/// @notice
/// - Users:
///   **Stake**
///   **Withdraw**
///   **GetReward**
/// - Manager:
///   **SetRewardsDuration**
/// - Distributor:
///   **distribute BNPL tokens to BankNodes**
///
/// @author BNPL
contract BankNodeRewardSystem is
    Initializable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 public constant REWARDS_DISTRIBUTOR_ROLE = keccak256("REWARDS_DISTRIBUTOR_ROLE");
    bytes32 public constant REWARDS_DISTRIBUTOR_ADMIN_ROLE = keccak256("REWARDS_DISTRIBUTOR_ADMIN_ROLE");

    bytes32 public constant REWARDS_MANAGER = keccak256("REWARDS_MANAGER_ROLE");
    bytes32 public constant REWARDS_MANAGER_ROLE_ADMIN = keccak256("REWARDS_MANAGER_ROLE_ADMIN");

    /// @notice [Bank node id] => [Previous rewards period]
    mapping(uint32 => uint256) public periodFinish;

    /// @notice [Bank node id] => [Reward rate]
    mapping(uint32 => uint256) public rewardRate;

    /// @notice [Bank node id] => [Rewards duration]
    mapping(uint32 => uint256) public rewardsDuration;

    /// @notice [Bank node id] => [Rewards last update time]
    mapping(uint32 => uint256) public lastUpdateTime;

    /// @notice [Bank node id] => [Reward per token stored]
    mapping(uint32 => uint256) public rewardPerTokenStored;

    /// @notice [Encoded user bank node key (user, bankNodeId)] => [Reward per token paid]
    mapping(uint256 => uint256) public userRewardPerTokenPaid;

    /// @notice [Encoded user bank node key (user, bankNodeId)] => [Rewards amount]
    mapping(uint256 => uint256) public rewards;

    /// @notice [Bank node id] => [Stake amount]
    mapping(uint32 => uint256) public _totalSupply;

    /// @notice [Encoded user bank node key (user, bankNodeId)] => [Staked balance]
    mapping(uint256 => uint256) private _balances;

    /// @notice BNPL bank node manager contract
    IBankNodeManager public bankNodeManager;

    /// @notice Rewards token contract
    IERC20 public rewardsToken;

    /// @notice Default rewards duration (secs)
    uint256 public defaultRewardsDuration;

    /// @dev Encode user address and bank node id into a uint256.
    ///
    /// @param user The address of user
    /// @param bankNodeId The id of the bank node
    /// @return encodedUserBankNodeKey The encoded user bank node key.
    function encodeUserBankNodeKey(address user, uint32 bankNodeId) public pure returns (uint256) {
        return (uint256(uint160(user)) << 32) | uint256(bankNodeId);
    }

    /// @dev Decode user bank node key to user address and bank node id.
    ///
    /// @param stakingVaultKey The user bank node key
    /// @return user The address of user
    /// @return bankNodeId The id of the bank node
    function decodeUserBankNodeKey(uint256 stakingVaultKey) external pure returns (address user, uint32 bankNodeId) {
        bankNodeId = uint32(stakingVaultKey & 0xffffffff);
        user = address(uint160(stakingVaultKey >> 32));
    }

    /// @dev Encode amount and depositTime into a uint256.
    ///
    /// @param amount An uint256 amount
    /// @param depositTime An uint40 deposit time
    /// @return encodedVaultValue The encoded vault value
    function encodeVaultValue(uint256 amount, uint40 depositTime) external pure returns (uint256) {
        require(
            amount <= 0xffffffffffffffffffffffffffffffffffffffffffffffffffffff,
            "cannot encode amount larger than 2^216-1"
        );
        return (amount << 40) | uint256(depositTime);
    }

    /// @notice Decode vault value to amount and depositTime
    ///
    /// @param vaultValue The encoded vault value
    /// @return amount An `uint256` amount
    /// @return depositTime An `uint40` deposit time
    function decodeVaultValue(uint256 vaultValue) external pure returns (uint256 amount, uint40 depositTime) {
        depositTime = uint40(vaultValue & 0xffffffffff);
        amount = vaultValue >> 40;
    }

    /// @dev Ensure the given address not zero and return it as IERC20
    /// @return ERC20Token
    function _ensureAddressIERC20Not0(address tokenAddress) internal pure returns (IERC20) {
        require(tokenAddress != address(0), "invalid token address!");
        return IERC20(tokenAddress);
    }

    /// @dev Ensure the given address not zero
    /// @return Address
    function _ensureContractAddressNot0(address contractAddress) internal pure returns (address) {
        require(contractAddress != address(0), "invalid token address!");
        return contractAddress;
    }

    /// @dev Get the lending pool token contract (ERC20) address of the specified bank node
    ///
    /// @param bankNodeId The id of the bank node
    /// @return BankNodeTokenContract The lending pool token contract (ERC20)
    function getStakingTokenForBankNode(uint32 bankNodeId) internal view returns (IERC20) {
        return _ensureAddressIERC20Not0(bankNodeManager.getBankNodeToken(bankNodeId));
    }

    /// @notice Get the lending pool token amount in rewards of the specified bank node
    ///
    /// @param bankNodeId The id of the bank node
    /// @return BankNodeTokenBalanceInRewards The lending pool token balance in rewards
    function getPoolLiquidityTokensStakedInRewards(uint32 bankNodeId) public view returns (uint256) {
        return getStakingTokenForBankNode(bankNodeId).balanceOf(address(this));
    }

    /// @dev Returns the input `amount`
    function getInternalValueForStakedTokenAmount(uint256 amount) internal pure returns (uint256) {
        return amount;
    }

    /// @dev Returns the input `amount`
    function getStakedTokenAmountForInternalValue(uint256 amount) internal pure returns (uint256) {
        return amount;
    }

    /// @notice Get the stake amount of the specified bank node
    ///
    /// @param bankNodeId The id of the bank node
    /// @return TotalSupply The stake amount
    function totalSupply(uint32 bankNodeId) external view returns (uint256) {
        return getStakedTokenAmountForInternalValue(_totalSupply[bankNodeId]);
    }

    /// @notice Get the user's staked balance under the specified bank node
    ///
    /// @param account User address
    /// @param bankNodeId The id of the bank node
    /// @return StakedBalance User's staked balance
    function balanceOf(address account, uint32 bankNodeId) external view returns (uint256) {
        return getStakedTokenAmountForInternalValue(_balances[encodeUserBankNodeKey(account, bankNodeId)]);
    }

    /// @notice Get the last time reward applicable of the specified bank node
    ///
    /// @param bankNodeId The id of the bank node
    /// @return lastTimeRewardApplicable The last time reward applicable
    function lastTimeRewardApplicable(uint32 bankNodeId) public view returns (uint256) {
        return block.timestamp < periodFinish[bankNodeId] ? block.timestamp : periodFinish[bankNodeId];
    }

    /// @notice Get reward amount with bank node id
    ///
    /// @param bankNodeId The id of the bank node
    /// @return rewardPerToken Reward per token amount
    function rewardPerToken(uint32 bankNodeId) public view returns (uint256) {
        if (_totalSupply[bankNodeId] == 0) {
            return rewardPerTokenStored[bankNodeId];
        }
        return
            rewardPerTokenStored[bankNodeId].add(
                lastTimeRewardApplicable(bankNodeId)
                    .sub(lastUpdateTime[bankNodeId])
                    .mul(rewardRate[bankNodeId])
                    .mul(1e18)
                    .div(_totalSupply[bankNodeId])
            );
    }

    /// @notice Get the benefits earned by users in the bank node
    ///
    /// @param account The user address
    /// @param bankNodeId The id of the bank node
    /// @return Earnd Benefits earned by users in the bank node
    function earned(address account, uint32 bankNodeId) public view returns (uint256) {
        uint256 key = encodeUserBankNodeKey(account, bankNodeId);
        return
            ((_balances[key] * (rewardPerToken(bankNodeId) - (userRewardPerTokenPaid[key]))) / 1e18) + (rewards[key]);
    }

    /// @notice Get bank node reward for duration
    ///
    /// @param bankNodeId The id of the bank node
    /// @return RewardForDuration Bank node reward for duration
    function getRewardForDuration(uint32 bankNodeId) external view returns (uint256) {
        return rewardRate[bankNodeId] * rewardsDuration[bankNodeId];
    }

    /// @notice Stake `tokenAmount` tokens to specified bank node
    ///
    /// @param bankNodeId The id of the bank node to stake
    /// @param tokenAmount The amount to be staked
    function stake(uint32 bankNodeId, uint256 tokenAmount)
        external
        nonReentrant
        whenNotPaused
        updateReward(msg.sender, bankNodeId)
    {
        require(tokenAmount > 0, "Cannot stake 0");
        uint256 amount = getInternalValueForStakedTokenAmount(tokenAmount);
        require(amount > 0, "Cannot stake 0");
        require(getStakedTokenAmountForInternalValue(amount) == tokenAmount, "token amount too high!");
        _totalSupply[bankNodeId] += amount;
        _balances[encodeUserBankNodeKey(msg.sender, bankNodeId)] += amount;
        getStakingTokenForBankNode(bankNodeId).safeTransferFrom(msg.sender, address(this), tokenAmount);
        emit Staked(msg.sender, bankNodeId, tokenAmount);
    }

    /// @notice Withdraw `tokenAmount` tokens from specified bank node
    ///
    /// @param bankNodeId The id of the bank node to withdraw
    /// @param tokenAmount The amount to be withdrawn
    function withdraw(uint32 bankNodeId, uint256 tokenAmount) public nonReentrant updateReward(msg.sender, bankNodeId) {
        require(tokenAmount > 0, "Cannot withdraw 0");
        uint256 amount = getInternalValueForStakedTokenAmount(tokenAmount);
        require(amount > 0, "Cannot withdraw 0");
        require(getStakedTokenAmountForInternalValue(amount) == tokenAmount, "token amount too high!");

        _totalSupply[bankNodeId] -= amount;
        _balances[encodeUserBankNodeKey(msg.sender, bankNodeId)] -= amount;
        getStakingTokenForBankNode(bankNodeId).safeTransfer(msg.sender, tokenAmount);
        emit Withdrawn(msg.sender, bankNodeId, tokenAmount);
    }

    /// @notice Get reward from specified bank node.
    /// @param bankNodeId The id of the bank node
    function getReward(uint32 bankNodeId) public nonReentrant updateReward(msg.sender, bankNodeId) {
        uint256 reward = rewards[encodeUserBankNodeKey(msg.sender, bankNodeId)];

        if (reward > 0) {
            rewards[encodeUserBankNodeKey(msg.sender, bankNodeId)] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, bankNodeId, reward);
        }
    }

    /// @notice Withdraw tokens and get reward from specified bank node.
    /// @param bankNodeId The id of the bank node
    function exit(uint32 bankNodeId) external {
        withdraw(
            bankNodeId,
            getStakedTokenAmountForInternalValue(_balances[encodeUserBankNodeKey(msg.sender, bankNodeId)])
        );
        getReward(bankNodeId);
    }

    /// @dev Update the reward and emit the `RewardAdded` event
    function _notifyRewardAmount(uint32 bankNodeId, uint256 reward) internal updateReward(address(0), bankNodeId) {
        if (rewardsDuration[bankNodeId] == 0) {
            rewardsDuration[bankNodeId] = defaultRewardsDuration;
        }
        if (block.timestamp >= periodFinish[bankNodeId]) {
            rewardRate[bankNodeId] = reward / (rewardsDuration[bankNodeId]);
        } else {
            uint256 remaining = periodFinish[bankNodeId] - (block.timestamp);
            uint256 leftover = remaining * (rewardRate[bankNodeId]);
            rewardRate[bankNodeId] = (reward + leftover) / (rewardsDuration[bankNodeId]);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(rewardRate[bankNodeId] <= (balance / rewardsDuration[bankNodeId]), "Provided reward too high");

        lastUpdateTime[bankNodeId] = block.timestamp;
        periodFinish[bankNodeId] = block.timestamp + (rewardsDuration[bankNodeId]);
        emit RewardAdded(bankNodeId, reward);
    }

    /// @notice Update the reward and emit the `RewardAdded` event
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "REWARDS_DISTRIBUTOR_ROLE"
    ///
    /// @param bankNodeId The id of the bank node
    /// @param reward The reward amount
    function notifyRewardAmount(uint32 bankNodeId, uint256 reward) external onlyRole(REWARDS_DISTRIBUTOR_ROLE) {
        _notifyRewardAmount(bankNodeId, reward);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    /* function recoverERC20(address tokenAddress, uint256 tokenAmount) external {
        require(tokenAddress != address(stakingToken[]), "Cannot withdraw the staking token");
        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }*/

    /// @notice Set reward duration for a bank node
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "REWARDS_MANAGER"
    ///
    /// @param bankNodeId The id of the bank node
    /// @param _rewardsDuration New reward duration (secs)
    function setRewardsDuration(uint32 bankNodeId, uint256 _rewardsDuration) external onlyRole(REWARDS_MANAGER) {
        require(
            block.timestamp > periodFinish[bankNodeId],
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration[bankNodeId] = _rewardsDuration;
        emit RewardsDurationUpdated(bankNodeId, rewardsDuration[bankNodeId]);
    }

    /// @dev Update user bank node reward
    modifier updateReward(address account, uint32 bankNodeId) {
        if (rewardsDuration[bankNodeId] == 0) {
            rewardsDuration[bankNodeId] = defaultRewardsDuration;
        }
        rewardPerTokenStored[bankNodeId] = rewardPerToken(bankNodeId);
        lastUpdateTime[bankNodeId] = lastTimeRewardApplicable(bankNodeId);
        if (account != address(0)) {
            uint256 key = encodeUserBankNodeKey(msg.sender, bankNodeId);
            rewards[key] = earned(msg.sender, bankNodeId);
            userRewardPerTokenPaid[key] = rewardPerTokenStored[bankNodeId];
        }
        _;
    }

    /// @dev Emitted when `_notifyRewardAmount` is called.
    ///
    /// @param bankNodeId The id of the bank node
    /// @param reward The reward amount
    event RewardAdded(uint32 indexed bankNodeId, uint256 reward);

    /// @dev Emitted when user `user` stake `tokenAmount` to specified `bankNodeId` bank node.
    ///
    /// @param user The user address
    /// @param bankNodeId The id of the bank node
    /// @param amount The staked amount
    event Staked(address indexed user, uint32 indexed bankNodeId, uint256 amount);

    /// @dev Emitted when user `user` withdraw `amount` of BNPL tokens from `bankNodeId` bank node.
    ///
    /// @param user The user address
    /// @param bankNodeId The id of the bank node
    /// @param amount The withdrawn amount
    event Withdrawn(address indexed user, uint32 indexed bankNodeId, uint256 amount);

    /// @dev Emitted when user `user` calls `getReward`.
    ///
    /// @param user The user address
    /// @param bankNodeId The id of the bank node
    /// @param reward The reward amount
    event RewardPaid(address indexed user, uint32 indexed bankNodeId, uint256 reward);

    /// @dev Emitted when `setRewardsDuration` is called.
    ///
    /// @param bankNodeId The id of the bank node
    /// @param newDuration The new reward duration
    event RewardsDurationUpdated(uint32 indexed bankNodeId, uint256 newDuration);
}
