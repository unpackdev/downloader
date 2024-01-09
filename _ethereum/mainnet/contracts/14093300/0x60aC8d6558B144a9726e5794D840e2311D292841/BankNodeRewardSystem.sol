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

    /* ========== STATE VARIABLES ========== */

    mapping(uint32 => uint256) public periodFinish;
    mapping(uint32 => uint256) public rewardRate;
    mapping(uint32 => uint256) public rewardsDuration;
    mapping(uint32 => uint256) public lastUpdateTime;
    mapping(uint32 => uint256) public rewardPerTokenStored;

    mapping(uint256 => uint256) public userRewardPerTokenPaid;
    mapping(uint256 => uint256) public rewards;
    mapping(uint32 => uint256) public _totalSupply;
    mapping(uint256 => uint256) private _balances;

    IBankNodeManager public bankNodeManager;
    IERC20 public rewardsToken;
    uint256 public defaultRewardsDuration;

    function encodeUserBankNodeKey(address user, uint32 bankNodeId) public pure returns (uint256) {
        return (uint256(uint160(user)) << 32) | uint256(bankNodeId);
    }

    function decodeUserBankNodeKey(uint256 stakingVaultKey) external pure returns (address user, uint32 bankNodeId) {
        bankNodeId = uint32(stakingVaultKey & 0xffffffff);
        user = address(uint160(stakingVaultKey >> 32));
    }

    function encodeVaultValue(uint256 amount, uint40 depositTime) external pure returns (uint256) {
        require(
            amount <= 0xffffffffffffffffffffffffffffffffffffffffffffffffffffff,
            "cannot encode amount larger than 2^216-1"
        );
        return (amount << 40) | uint256(depositTime);
    }

    function decodeVaultValue(uint256 vaultValue) external pure returns (uint256 amount, uint40 depositTime) {
        depositTime = uint40(vaultValue & 0xffffffffff);
        amount = vaultValue >> 40;
    }

    function _ensureAddressIERC20Not0(address tokenAddress) internal pure returns (IERC20) {
        require(tokenAddress != address(0), "invalid token address!");
        return IERC20(tokenAddress);
    }

    function _ensureContractAddressNot0(address contractAddress) internal pure returns (address) {
        require(contractAddress != address(0), "invalid token address!");
        return contractAddress;
    }

    function getStakingTokenForBankNode(uint32 bankNodeId) internal view returns (IERC20) {
        return _ensureAddressIERC20Not0(bankNodeManager.getBankNodeToken(bankNodeId));
    }

    function getPoolLiquidityTokensStakedInRewards(uint32 bankNodeId) public view returns (uint256) {
        return getStakingTokenForBankNode(bankNodeId).balanceOf(address(this));
    }

    function getInternalValueForStakedTokenAmount(uint256 amount) internal pure returns (uint256) {
        return amount;
    }

    function getStakedTokenAmountForInternalValue(uint256 amount) internal pure returns (uint256) {
        return amount;
    }

    /* ========== VIEWS ========== */

    function totalSupply(uint32 bankNodeId) external view returns (uint256) {
        return getStakedTokenAmountForInternalValue(_totalSupply[bankNodeId]);
    }

    function balanceOf(address account, uint32 bankNodeId) external view returns (uint256) {
        return getStakedTokenAmountForInternalValue(_balances[encodeUserBankNodeKey(account, bankNodeId)]);
    }

    function lastTimeRewardApplicable(uint32 bankNodeId) public view returns (uint256) {
        return block.timestamp < periodFinish[bankNodeId] ? block.timestamp : periodFinish[bankNodeId];
    }

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

        /*
        return
            rewardPerTokenStored[bankNodeId] +
            (lastTimeRewardApplicable(bankNodeId) -
                ((lastUpdateTime[bankNodeId] * rewardRate[bankNodeId] * 1e18) / (_totalSupply[bankNodeId])));*/
    }

    function earned(address account, uint32 bankNodeId) public view returns (uint256) {
        uint256 key = encodeUserBankNodeKey(account, bankNodeId);
        return
            ((_balances[key] * (rewardPerToken(bankNodeId) - (userRewardPerTokenPaid[key]))) / 1e18) + (rewards[key]);
    }

    function getRewardForDuration(uint32 bankNodeId) external view returns (uint256) {
        return rewardRate[bankNodeId] * rewardsDuration[bankNodeId];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

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

    function getReward(uint32 bankNodeId) public nonReentrant updateReward(msg.sender, bankNodeId) {
        uint256 reward = rewards[encodeUserBankNodeKey(msg.sender, bankNodeId)];

        if (reward > 0) {
            rewards[encodeUserBankNodeKey(msg.sender, bankNodeId)] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, bankNodeId, reward);
        }
    }

    function exit(uint32 bankNodeId) external {
        withdraw(
            bankNodeId,
            getStakedTokenAmountForInternalValue(_balances[encodeUserBankNodeKey(msg.sender, bankNodeId)])
        );
        getReward(bankNodeId);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

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

    function notifyRewardAmount(uint32 bankNodeId, uint256 reward) external onlyRole(REWARDS_DISTRIBUTOR_ROLE) {
        _notifyRewardAmount(bankNodeId, reward);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    /* function recoverERC20(address tokenAddress, uint256 tokenAmount) external {
        require(tokenAddress != address(stakingToken[]), "Cannot withdraw the staking token");
        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }*/

    function setRewardsDuration(uint32 bankNodeId, uint256 _rewardsDuration) external onlyRole(REWARDS_MANAGER) {
        require(
            block.timestamp > periodFinish[bankNodeId],
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration[bankNodeId] = _rewardsDuration;
        emit RewardsDurationUpdated(bankNodeId, rewardsDuration[bankNodeId]);
    }

    /* ========== MODIFIERS ========== */

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

    /* ========== EVENTS ========== */

    event RewardAdded(uint32 indexed bankNodeId, uint256 reward);
    event Staked(address indexed user, uint32 indexed bankNodeId, uint256 amount);
    event Withdrawn(address indexed user, uint32 indexed bankNodeId, uint256 amount);
    event RewardPaid(address indexed user, uint32 indexed bankNodeId, uint256 reward);
    event RewardsDurationUpdated(uint32 indexed bankNodeId, uint256 newDuration);
}
