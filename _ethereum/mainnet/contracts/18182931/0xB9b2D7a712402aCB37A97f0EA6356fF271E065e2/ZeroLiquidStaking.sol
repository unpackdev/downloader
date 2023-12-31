//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./SafeERC20.sol";
import "./IERC20Metadata.sol";

// Custom Errors
error AmountLessThanStakedAmountOrZero();
error CallerNotGovernance();
error EtherNotAccepted();
error InsufficientFunds();
error InsufficientZeroFunds();
error InputLengthMismatch();
error NoPendingRewardsToClaim();
error NoStakeFound();
error ZeroAddressInput();
error RewardDistributionPeriodHasExpired();
error RewardPerBlockIsNotSet();
error SameRewardToken();
error ZeroAddress();
error ZeroInput();

/// @title ZeroLiquid Staking
/// @author ZeroLiquid
/// @notice Contract for staking ZeroLiquid to earn rewards
contract ZeroLiquidStaking {
    using SafeERC20 for IERC20Metadata;

    // Info of each user
    struct UserInfo {
        uint256 lastUpdateRewardToken; // Timestamp of last reward token update - used to reset user reward debt
        uint256 amount; // Amount of zero tokens staked by the user
        uint256 rewardDebt; // Reward debt
    }

    // To determine transaction type
    enum TxType {
        STAKE,
        UNSTAKE,
        CLAIM,
        EMERGENCY
    }

    // Address of the zero token
    IERC20Metadata public immutable zeroToken;

    // Address of the reward token
    IERC20Metadata public rewardToken;

    // Address of the governance
    address public governance;

    // Precision factor for multiple calculations
    uint256 public constant ONE = 1e18;

    // Accumulated reward per zero token
    uint256 public accRewardPerZero;

    // Last update block for rewards
    uint256 public lastUpdateBlock;

    // Total zero tokens staked
    uint256 public totalZeroStaked;

    // Reward to distribute per block
    uint256 public currentRewardPerBlock;

    // Current end block for the current reward period
    uint256 public periodEndBlock;

    // Last time reward token was updated
    uint256 public lastUpdateRewardToken;

    // Info of each user staking Zero tokens
    mapping(address => UserInfo) public userInfo;

    event StakeOrUnstakeOrClaim(address indexed user, uint256 amount, uint256 pendingReward, TxType txType);
    event NewRewardPeriod(
        uint256 numberBlocksToDistributeRewards,
        uint256 newRewardPerBlock,
        uint256 rewardToDistribute,
        uint256 rewardExpirationBlock
    );
    event GovernanceChanged(address indexed oldGovernance, address indexed newGovernance);
    event RewardTokenChanged(address indexed oldRewardToken, address indexed newRewardToken);
    event FundsMigrated(address indexed _newVersion, IERC20Metadata[] _tokens, uint256[] _amounts);
    event PeriodEndBlockUpdate(uint256 numberBlocksToDistributeRewards, uint256 rewardExpirationBlock);

    /**
     * @notice Constructor
     * @param _governance governance address of zeroliquid staking
     * @param _rewardToken address of the reward token
     * @param _zeroToken address of the zero token
     */
    constructor(address _governance, address _rewardToken, address _zeroToken) {
        if (_governance == address(0) || _rewardToken == address(0) || _zeroToken == address(0)) revert ZeroAddress();

        governance = _governance;
        rewardToken = IERC20Metadata(_rewardToken);
        zeroToken = IERC20Metadata(_zeroToken);
        emit GovernanceChanged(address(0), _governance);
        emit RewardTokenChanged(address(0), _rewardToken);
    }

    /**
     * @dev Throws if ether is received
     */
    receive() external payable {
        revert EtherNotAccepted();
    }

    /**
     * @dev Throws if called by any account other than the governance
     */
    modifier onlyGovernance() {
        if (msg.sender != governance) revert CallerNotGovernance();
        _;
    }

    /**
     * @notice Updates the governance of this contract
     * @param _newGovernance address of the new governance of this contract
     * @dev Only callable by Governance
     */
    function setGovernance(address _newGovernance) external onlyGovernance {
        if (_newGovernance == address(0)) revert ZeroAddress();

        governance = _newGovernance;
        emit GovernanceChanged(governance, _newGovernance);
    }

    /**
     * @notice Updates the reward token.
     * @param _newRewardToken address of the new reward token
     * @dev Only callable by Governance. It also resets reward distribution accounting
     */
    function updateRewardToken(address _newRewardToken) external onlyGovernance {
        if (_newRewardToken == address(rewardToken)) revert SameRewardToken();
        if (_newRewardToken == address(0)) revert ZeroAddress();

        // Resetting reward distribution accounting
        accRewardPerZero = 0;
        lastUpdateBlock = _lastRewardBlock();

        // Setting reward token update time
        lastUpdateRewardToken = block.timestamp;

        // Updating reward token address
        rewardToken = IERC20Metadata(_newRewardToken);

        emit RewardTokenChanged(address(rewardToken), _newRewardToken);
    }

    /**
     * @notice Updates the reward per block
     * @param _reward total reward to distribute.
     * @param _rewardDurationInBlocks total number of blocks in which the '_reward' should be distributed
     * @dev Only callable by Governance.
     */
    function updateRewards(uint256 _reward, uint256 _rewardDurationInBlocks) external onlyGovernance {
        if (_rewardDurationInBlocks == 0) revert ZeroInput();

        // Update reward distribution accounting
        _updateRewardPerZeroAndLastBlock();

        // Adjust the current reward per block
        // If reward distribution duration is expired
        if (block.number >= periodEndBlock) {
            if (_reward == 0) revert ZeroInput();

            currentRewardPerBlock = _reward / _rewardDurationInBlocks;
        }
        // Otherwise, reward distribution duration isn't expired
        else {
            currentRewardPerBlock =
                (_reward + ((periodEndBlock - block.number) * currentRewardPerBlock)) / _rewardDurationInBlocks;
        }

        lastUpdateBlock = block.number;

        // Setting rewards expiration block
        periodEndBlock = block.number + _rewardDurationInBlocks;

        emit NewRewardPeriod(_rewardDurationInBlocks, currentRewardPerBlock, _reward, periodEndBlock);
    }

    /**
     * @notice Updates the reward distribution duration end block
     * @param _expireDurationInBlocks number of blocks after which reward distribution should be halted
     * @dev Only callable by Governance
     */
    function updateRewardEndBlock(uint256 _expireDurationInBlocks) external onlyGovernance {
        // Update reward distribution accounting
        _updateRewardPerZeroAndLastBlock();
        lastUpdateBlock = block.number;

        // Setting rewards expiration block
        periodEndBlock = block.number + _expireDurationInBlocks;
        emit PeriodEndBlockUpdate(_expireDurationInBlocks, periodEndBlock);
    }

    /**
     * @notice Migrates the funds to another address.
     * @param _newVersion receiver address of the funds
     * @param _tokens list of token addresses
     * @param _amounts list of funds amount
     * @param _isZeroMigrate whether to transfer zero tokens
     * @dev Only callable by Governance.
     */
    function migrateFunds(
        address _newVersion,
        IERC20Metadata[] calldata _tokens,
        uint256[] calldata _amounts,
        bool _isZeroMigrate
    )
        external
        onlyGovernance
    {
        if (_newVersion == address(0)) revert ZeroAddress();

        if (_tokens.length != _amounts.length) revert InputLengthMismatch();

        // Declaring outside the loop to save gas
        IERC20Metadata tokenAddress;
        uint256 amount;

        for (uint256 i; i < _tokens.length;) {
            // Local copy to save gas
            tokenAddress = _tokens[i];
            amount = _amounts[i];

            if (tokenAddress == zeroToken) revert ZeroAddressInput();

            if (address(tokenAddress) == address(0)) revert ZeroAddress();

            if (amount == 0) revert ZeroInput();

            if (amount > tokenAddress.balanceOf(address(this))) {
                revert InsufficientFunds();
            }

            tokenAddress.safeTransfer(_newVersion, amount);
            unchecked {
                ++i;
            }
        }

        // Migrate zero tokens
        if (_isZeroMigrate) {
            // Zero token balance of this contract minus staked zero
            uint256 protocolZeroBalance = zeroToken.balanceOf(address(this)) - totalZeroStaked;

            // If protocol owns any zero tokens in this contract then transfer
            if (protocolZeroBalance > 0) {
                zeroToken.safeTransfer(_newVersion, protocolZeroBalance);
            } else {
                revert InsufficientZeroFunds();
            }
        }
        emit FundsMigrated(_newVersion, _tokens, _amounts);
    }

    /**
     * @notice Stake zero tokens. Also triggers a claim.
     * @param _to staking reward receiver address
     * @param _amount amount of zero tokens to stake
     */
    function stake(address _to, uint256 _amount) external {
        if (_amount == 0) revert ZeroInput();

        if (_to == address(0)) revert ZeroAddress();

        if (currentRewardPerBlock == 0) revert RewardPerBlockIsNotSet();

        if (block.number >= periodEndBlock) {
            revert RewardDistributionPeriodHasExpired();
        }

        if (rewardToken.balanceOf(address(this)) == 0) {
            revert InsufficientFunds();
        }

        _stakeOrUnstakeOrClaim(_to, _amount, TxType.STAKE);
    }

    /**
     * @notice Unstake zero tokens. Also triggers a reward claim.
     * @param _amount amount of zero tokens to unstake
     */
    function unstake(uint256 _amount) external {
        if ((_amount > userInfo[msg.sender].amount) || _amount == 0) {
            revert AmountLessThanStakedAmountOrZero();
        }

        _stakeOrUnstakeOrClaim(msg.sender, _amount, TxType.UNSTAKE);
    }

    /**
     * @notice Unstake all staked zero tokens without caring about rewards, EMERGENCY ONLY
     */
    function emergencyUnstake() external {
        if (userInfo[msg.sender].amount > 0) {
            _stakeOrUnstakeOrClaim(msg.sender, userInfo[msg.sender].amount, TxType.EMERGENCY);
        } else {
            revert NoStakeFound();
        }
    }

    /**
     * @notice Claim pending rewards.
     */
    function claim() external {
        _stakeOrUnstakeOrClaim(msg.sender, userInfo[msg.sender].amount, TxType.CLAIM);
    }

    /**
     * @notice Calculate pending rewards for a user
     * @param _user address of the user
     * @return pending rewards of the user
     */
    function calculatePendingRewards(address _user) external view returns (uint256) {
        uint256 newAccRewardPerZero;

        if (totalZeroStaked != 0) {
            newAccRewardPerZero = accRewardPerZero
                + (((_lastRewardBlock() - lastUpdateBlock) * (currentRewardPerBlock * ONE)) / totalZeroStaked);
            // If checking user pending rewards in the block in which reward token is updated
            if (newAccRewardPerZero == 0) return 0;
        } else {
            return 0;
        }

        uint256 rewardDebt = userInfo[_user].rewardDebt;

        // Reset debt if user is checking rewards after reward token has changed
        if (userInfo[_user].lastUpdateRewardToken < lastUpdateRewardToken) {
            rewardDebt = 0;
        }

        uint256 pendingRewards = ((userInfo[_user].amount * newAccRewardPerZero) / ONE) - rewardDebt;

        // Downscale if reward token has less than 18 decimals
        if (_computeScalingFactor(rewardToken) != 1) {
            // Downscaling pending rewards before transferring to the user
            pendingRewards = _downscale(pendingRewards);
        }
        return pendingRewards;
    }

    /**
     * @notice Return last block where trading rewards were distributed
     */
    function lastRewardBlock() external view returns (uint256) {
        return _lastRewardBlock();
    }

    /**
     * @notice Stake/ Unstake zero tokens and also distributes reward
     * @param _to staking reward receiver address
     * @param _amount amount of zero tokens to stake or unstake. 0 if claim tx.
     * @param _txType type of the transaction
     */
    function _stakeOrUnstakeOrClaim(address _to, uint256 _amount, TxType _txType) private {
        // Update reward distribution accounting
        _updateRewardPerZeroAndLastBlock();

        // Reset debt if reward token has changed
        _resetDebtIfNewRewardToken(_to);

        UserInfo storage user = userInfo[_to];

        uint256 pendingRewards;

        // Distribute rewards if not emergency unstake
        if (TxType.EMERGENCY != _txType) {
            // Distribute rewards if not new stake
            if (user.amount > 0) {
                // Calculate pending rewards
                pendingRewards = _calculatePendingRewards(_to);

                // Downscale if reward token has less than 18 decimals
                if (_computeScalingFactor(rewardToken) != 1) {
                    // Downscaling pending rewards before transferring to the user
                    pendingRewards = _downscale(pendingRewards);
                }

                // If there are rewards to distribute
                if (pendingRewards > 0) {
                    if (pendingRewards > rewardToken.balanceOf(address(this))) {
                        revert InsufficientFunds();
                    }

                    // Transferring rewards to the user
                    rewardToken.safeTransfer(_to, pendingRewards);
                }
                // If there are no pending rewards and tx is of claim then revert
                else if (TxType.CLAIM == _txType) {
                    revert NoPendingRewardsToClaim();
                }
            }
            // Claiming rewards without any stake
            else if (TxType.CLAIM == _txType) {
                revert NoPendingRewardsToClaim();
            }
        }

        if (TxType.STAKE == _txType) {
            // Transfer Zero tokens from the caller to this contract
            zeroToken.safeTransferFrom(msg.sender, address(this), _amount);

            // Increase user zero staked amount
            user.amount += _amount;

            // Increase total zero staked amount
            totalZeroStaked += _amount;
        } else if (TxType.UNSTAKE == _txType || TxType.EMERGENCY == _txType) {
            // Decrease user zero staked amount
            user.amount -= _amount;

            // Decrease total zero staked amount
            totalZeroStaked -= _amount;

            // Transfer Zero tokens back to the sender
            zeroToken.safeTransfer(_to, _amount);
        }

        // Adjust user debt
        user.rewardDebt = (user.amount * accRewardPerZero) / ONE;

        emit StakeOrUnstakeOrClaim(_to, _amount, pendingRewards, _txType);
    }

    /**
     * @notice Resets user reward debt if reward token has changed
     * @param _to reward debt reset address
     */
    function _resetDebtIfNewRewardToken(address _to) private {
        // Reset debt if user last update reward token time is less than the time of last reward token update
        if (userInfo[_to].lastUpdateRewardToken < lastUpdateRewardToken) {
            userInfo[_to].rewardDebt = 0;
            userInfo[_to].lastUpdateRewardToken = lastUpdateRewardToken;
        }
    }

    /**
     * @notice Updates accumulated reward to distribute per zero token. Also updates the last block in which rewards
     * are distributed
     */
    function _updateRewardPerZeroAndLastBlock() private {
        if (totalZeroStaked == 0) {
            lastUpdateBlock = block.number;
            return;
        }

        accRewardPerZero += ((_lastRewardBlock() - lastUpdateBlock) * (currentRewardPerBlock * ONE)) / totalZeroStaked;

        if (block.number != lastUpdateBlock) {
            lastUpdateBlock = _lastRewardBlock();
        }
    }

    /**
     * @notice Calculate pending rewards for a user
     * @param _user address of the user
     */
    function _calculatePendingRewards(address _user) private view returns (uint256) {
        return ((userInfo[_user].amount * accRewardPerZero) / ONE) - userInfo[_user].rewardDebt;
    }

    /**
     * @notice Return last block where rewards must be distributed
     */
    function _lastRewardBlock() private view returns (uint256) {
        return block.number < periodEndBlock ? block.number : periodEndBlock;
    }

    /**
     * @notice Returns a scaling factor that, when multiplied to a token amount for `token`, normalizes its balance as
     * if
     * it had 18 decimals.
     */
    function _computeScalingFactor(IERC20Metadata _token) private view returns (uint256) {
        // Tokens that don't implement the `decimals` method are not supported.
        uint256 tokenDecimals = _token.decimals();

        // Tokens with more than 18 decimals are not supported.
        uint256 decimalsDifference = 18 - tokenDecimals;
        return 10 ** decimalsDifference;
    }

    /**
     * @notice Reverses the upscaling applied to `amount`, resulting in a smaller or equal value depending on
     * whether it needed scaling or not
     */
    function _downscale(uint256 _amount) private view returns (uint256) {
        return _amount / _computeScalingFactor(rewardToken);
    }
}
