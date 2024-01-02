// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
//import "./console.sol";

/**
 * @title TGT Staking
 * @author ZK Finance
 * @notice TGTStaking is a contract that allows TGT deposits and receives stablecoins sent by MoneyMaker's daily
 * harvests. Users deposit TGT and receive a share of what has been sent by MoneyMaker based on their participation of
 * the total deposited TGT. It is similar to a MasterChef, but we allow for claiming of different reward tokens
 * (in case at some point we wish to change the stablecoin rewarded).
 * Every time `updateReward(token)` is called, We distribute the balance of that tokens as rewards to users that are
 * currently staking inside this contract, and they can claim it using `withdraw(0)`
 */
contract TGTStaking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Info of each user
    /// @param amount The amount of TGT the user has provided
    /// @param depositTimestamp The timestamp of the block when the user deposited, used to calculate the staking multiplier
    /// @param lastRewardStakingMultiplier The last staking multiplier the user had when he claimed rewards
    /// @param rewardDebt The amount of reward tokens claimed by the user if used without the staking multiplier
    /// @param rewardPayoutAmount The amount of reward tokens that should be paid out to the user in total
    /// @param extraRewardsDebt The amount of extra rewards claimed by the user when he has 2x staking multiplier and over 350k TGT staked
    struct UserInfo {
        uint256 amount;
        uint256 depositTimestamp;
        uint256 lastRewardStakingMultiplier;
        mapping(IERC20 => uint256) rewardDebt;
        mapping(IERC20 => uint256) rewardPayoutAmount;
        mapping(IERC20 => uint256) extraRewardsDebt;
        /**
         * @notice We do some fancy math here. Basically, any point in time, the amount of TGTs
         * entitled to a user but is pending to be distributed is:
         *
         *   pending reward = (user.amount * accRewardPerShare) - user.rewardDebt[token]
         *
         * Whenever a user deposits or withdraws TGT. Here's what happens:
         *   1. accRewardPerShare (and `lastRewardBalance`) gets updated
         *   2. User receives the pending reward sent to his/her address
         *   3. User's `amount` gets updated
         *   4. User's `rewardDebt[token]` gets updated
         */
    }

    IERC20 public immutable tgt;

    /// @dev Internal balance of TGT, this gets updated on user deposits / withdrawals
    /// this allows to reward users with TGT
    uint256 public internalTgtBalance;

    /// @notice Array of tokens that users can claim
    IERC20[] public rewardTokens;

    mapping(IERC20 => bool) public isRewardToken;

    /// @notice Last reward balance of `token`
    mapping(IERC20 => uint256) public lastRewardBalance;

    /// @notice Forgone rewards pool for redistributing rewards to high stakers and community plus users
    mapping(IERC20 => uint256) public forgoneRewardsPool;

    /// @notice Accumulated `token` rewards per share, scaled to `ACC_REWARD_PER_SHARE_PRECISION`
    mapping(IERC20 => uint256) public accRewardPerShare;
    mapping(IERC20 => uint256) public redistributionAccRewardPerShare;

    /// @notice The precision of `accRewardPerShare`
    uint256 public constant ACC_REWARD_PER_SHARE_PRECISION = 1e24;

    uint256 public constant MULTIPLIER_PRECISION = 1e18;

    /// @dev Info of each user that stakes TGT
    mapping(address => UserInfo) private userInfo;

    /// @notice Emitted when a user deposits TGT
    event Deposit(address indexed user, uint256 amount);

    /// @notice Emitted when a user withdraws TGT
    event Withdraw(address indexed user, uint256 amount);

    /// @notice Emitted when a user claims reward
    event ClaimReward(address indexed user, address indexed rewardToken, uint256 amount);

    /// @notice Emitted when a user claims an extra reward with 2x staking multiplier
    event ClaimExtraReward(address indexed user, address indexed rewardToken, uint256 amount);

    /// @notice Emitted when a user emergency withdraws its TGT
    event EmergencyWithdraw(address indexed user, uint256 amount);

    /// @notice Emitted when owner adds a token to the reward tokens list
    event RewardTokenAdded(address token);

    /// @notice Emitted when owner removes a token from the reward tokens list
    event RewardTokenRemoved(address token);

    /**
     * @notice Initialize a new TGTStaking contract
     * @dev This contract needs to receive an ERC20 `_rewardToken` in order to distribute them
     * (with MoneyMaker in our case)
     * @param _rewardToken The address of the ERC20 reward token
     * @param _tgt The address of the TGT token
     */
    constructor(
        IERC20 _rewardToken,
        IERC20 _tgt
    ) {
        require(address(_rewardToken) != address(0), "TGTStaking: reward token can't be address(0)");
        require(address(_tgt) != address(0), "TGTStaking: tgt can't be address(0)");

        tgt = _tgt;

        isRewardToken[_rewardToken] = true;
        rewardTokens.push(_rewardToken);
    }

    /**
     * @notice Deposit TGT for reward token allocation
     * @param _amount The amount of TGT to deposit
     */
    function deposit(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[_msgSender()];

        uint256 _previousAmount = user.amount;

        if (_previousAmount == 0 && _amount > 0) {
            user.depositTimestamp = block.timestamp;
        }

        uint256 _newAmount = user.amount + _amount;
        user.amount = _newAmount;

        uint256 _len = rewardTokens.length;
        for (uint256 i; i < _len; i++) {
            IERC20 _token = rewardTokens[i];

            _updateReward(_token);

            uint256 _previousRewardDebt = user.rewardDebt[_token];
            user.rewardDebt[_token] = _newAmount * accRewardPerShare[_token] / ACC_REWARD_PER_SHARE_PRECISION;

            if (_previousAmount != 0 || user.rewardPayoutAmount[_token] != 0) {

                uint256 _pending = ((_previousAmount * accRewardPerShare[_token]) / ACC_REWARD_PER_SHARE_PRECISION) - _previousRewardDebt;

                if (_pending != 0) {
                    uint256 _stakingMultiplier = getStakingMultiplier(_msgSender());
                    uint256 _fullReward = _pending;

                    if (_stakingMultiplier < 1e18 && _stakingMultiplier >= 5e17) {
                        uint256 _currentReward = (_pending * _stakingMultiplier) / MULTIPLIER_PRECISION;

                        if (user.lastRewardStakingMultiplier == 0) {
                            _pending = _currentReward + (user.rewardPayoutAmount[_token] * _stakingMultiplier) / MULTIPLIER_PRECISION;
                            user.rewardPayoutAmount[_token] -= (user.rewardPayoutAmount[_token] * _stakingMultiplier) / MULTIPLIER_PRECISION;
                        } else {
                            if (user.lastRewardStakingMultiplier > _stakingMultiplier) {
                                user.lastRewardStakingMultiplier = 0;
                            }

                            uint256 _oldRewardPayoutAmount = ((2 * (_stakingMultiplier - user.lastRewardStakingMultiplier)) * user.rewardPayoutAmount[_token]) / MULTIPLIER_PRECISION;
                            _pending = _currentReward + _oldRewardPayoutAmount;
                            user.rewardPayoutAmount[_token] -= _oldRewardPayoutAmount;
                        }
                    } else if (_stakingMultiplier == 0) {
                        _pending = 0;
                    }
                    else {// stakingMultiplier >= 1e18 (100%) distributes all locked rewards if any
                        _pending += user.rewardPayoutAmount[_token];
                        user.rewardPayoutAmount[_token] = 0;
                    }
                    if (_pending > 0) {
                        safeTokenTransfer(_token, _msgSender(), _pending);
                        emit ClaimReward(_msgSender(), address(_token), _pending);
                    }
                    user.lastRewardStakingMultiplier = _stakingMultiplier;
                    user.rewardPayoutAmount[_token] += _fullReward - ((_fullReward * _stakingMultiplier) / MULTIPLIER_PRECISION);
                }
            }
        }

        internalTgtBalance = internalTgtBalance + _amount;
        tgt.safeTransferFrom(_msgSender(), address(this), _amount);
        emit Deposit(_msgSender(), _amount);
    }

    /**
     * @notice Get user info
     * @param _user The address of the user
     * @param _rewardToken The address of the reward token
     * @return The amount of TGT user has deposited
     * @return The reward debt for the chosen token
     */
    function getUserInfo(address _user, IERC20 _rewardToken) external view returns (uint256, uint256) {
        UserInfo storage user = userInfo[_user];
        return (user.amount, user.rewardDebt[_rewardToken]);
    }

    /**
     * @notice Get the number of reward tokens
     * @return The length of the array
     */
    function rewardTokensLength() external view returns (uint256) {
        return rewardTokens.length;
    }

    /**
     * @notice Add a reward token
     * @param _rewardToken The address of the reward token
     */
    function addRewardToken(IERC20 _rewardToken) external nonReentrant onlyOwner {
        require(
            !isRewardToken[_rewardToken] && address(_rewardToken) != address(0),
            "TGTStaking: token can't be added"
        );
        require(rewardTokens.length < 25, "TGTStaking: list of token too big");
        rewardTokens.push(_rewardToken);
        isRewardToken[_rewardToken] = true;
        _updateReward(_rewardToken);
        emit RewardTokenAdded(address(_rewardToken));
    }

    /**
     * @notice Remove a reward token
     * @param _rewardToken The address of the reward token
     */
    function removeRewardToken(IERC20 _rewardToken) external nonReentrant onlyOwner {
        require(isRewardToken[_rewardToken], "TGTStaking: token can't be removed");
        _updateReward(_rewardToken);
        isRewardToken[_rewardToken] = false;
        uint256 _len = rewardTokens.length;
        lastRewardBalance[_rewardToken] = 0;
        for (uint256 i; i < _len; i++) {
            if (rewardTokens[i] == _rewardToken) {
                rewardTokens[i] = rewardTokens[_len - 1];
                rewardTokens.pop();
                break;
            }
        }
        emit RewardTokenRemoved(address(_rewardToken));
    }

    /**
     * @notice View function to see pending reward token on frontend
     * @param _user The address of the user
     * @param _token The address of the token
     * @return `_user`'s pending reward token
     */
    function pendingReward(address _user, IERC20 _token) external view returns (uint256) {
        require(isRewardToken[_token], "TGTStaking: wrong reward token");

        UserInfo storage user = userInfo[_user];
        uint256 _totalTgt = internalTgtBalance;
        uint256 _accRewardTokenPerShare = accRewardPerShare[_token];

        uint256 _currRewardBalance = _token.balanceOf(address(this));
        uint256 _rewardBalance = _token == tgt ? _currRewardBalance - _totalTgt : _currRewardBalance;

        if (_rewardBalance != lastRewardBalance[_token] && _totalTgt != 0) {
            uint256 _accruedReward = _rewardBalance - lastRewardBalance[_token];
            _accRewardTokenPerShare = _accRewardTokenPerShare +
                (_accruedReward * ACC_REWARD_PER_SHARE_PRECISION / _totalTgt);
        }

        uint256 _pending = ((user.amount * _accRewardTokenPerShare) / ACC_REWARD_PER_SHARE_PRECISION) - user.rewardDebt[_token];

        if (_pending != 0 || user.rewardPayoutAmount[_token] != 0) {
            uint256 _stakingMultiplier = getStakingMultiplier(_user);

            if (_stakingMultiplier < 1e18 && _stakingMultiplier >= 5e17) {
                uint256 _currentReward = (_pending * _stakingMultiplier) / MULTIPLIER_PRECISION;

                if (user.lastRewardStakingMultiplier == 0) {
                    _pending = _currentReward + (user.rewardPayoutAmount[_token] * _stakingMultiplier) / MULTIPLIER_PRECISION;
                } else {
                    uint256 lastMultiplier = user.lastRewardStakingMultiplier;
                    if (user.lastRewardStakingMultiplier > _stakingMultiplier) {
                        lastMultiplier = 0;
                    }

                    uint256 _oldRewardPayoutAmount = ((2 * (_stakingMultiplier - lastMultiplier)) * user.rewardPayoutAmount[_token]) / MULTIPLIER_PRECISION;
                    _pending = _currentReward + _oldRewardPayoutAmount;
                }
            } else if (_stakingMultiplier == 0) {
                _pending = 0;
            }
            else { // stakingMultiplier >= 1e18 (100%) distributes all locked rewards if any
                _pending += user.rewardPayoutAmount[_token];
            }
        }
        return _pending;
    }

    /**
     * @notice To just harvest the rewards pass 0 as `_amount`, to harvest and withdraw pass the amount to withdraw
     * @param _amount The amount of TGT to withdraw if any
     */
    function withdraw(uint256 _amount) public nonReentrant {
        UserInfo storage user = userInfo[_msgSender()];
        uint256 _previousAmount = user.amount;
        require(_amount <= _previousAmount, "TGTStaking: withdraw amount exceeds balance");
        uint256 _newAmount = user.amount - _amount;
        user.amount = _newAmount;

        uint256 _len = rewardTokens.length;
        if (_previousAmount != 0) {
            for (uint256 i; i < _len; i++) {
                IERC20 _token = rewardTokens[i];
                _updateReward(_token);

                uint256 _pending = ((_previousAmount * accRewardPerShare[_token]) / ACC_REWARD_PER_SHARE_PRECISION) - user.rewardDebt[_token];
                user.rewardDebt[_token] = (_newAmount * accRewardPerShare[_token]) / ACC_REWARD_PER_SHARE_PRECISION;

                if (_pending != 0 || user.rewardPayoutAmount[_token] != 0) {
                    uint256 _stakingMultiplier = getStakingMultiplier(_msgSender());
                    uint256 _fullReward = _pending;

                    if (_stakingMultiplier < 1e18 && _stakingMultiplier >= 5e17) {

                        uint256 _currentReward = (_pending * _stakingMultiplier) / MULTIPLIER_PRECISION;

                        if (_previousAmount >= _amount && _amount != 0) {
                            //find the difference between max potential reward and given reward
                            uint256 unclaimedPotentialReward = _pending - _currentReward;
                            forgoneRewardsPool[_token] += unclaimedPotentialReward;
                        }

                        if (user.lastRewardStakingMultiplier == 0) {
                            _pending = _currentReward + (user.rewardPayoutAmount[_token] * _stakingMultiplier) / MULTIPLIER_PRECISION;
                            user.rewardPayoutAmount[_token] -= (user.rewardPayoutAmount[_token] * _stakingMultiplier) / MULTIPLIER_PRECISION;
                        } else {
                            if (user.lastRewardStakingMultiplier > _stakingMultiplier) {
                                user.lastRewardStakingMultiplier = 0;
                            }

                            uint256 _oldRewardPayoutAmount = ((2 * (_stakingMultiplier - user.lastRewardStakingMultiplier)) * user.rewardPayoutAmount[_token]) / MULTIPLIER_PRECISION;
                            _pending = _currentReward + _oldRewardPayoutAmount;
                            user.rewardPayoutAmount[_token] -= _oldRewardPayoutAmount;
                        }
                    } else if (_stakingMultiplier == 0) {
                        _pending = 0;
                    }
                    else { // stakingMultiplier >= 1e18 (100%) distributes all locked rewards if any
                        _pending += user.rewardPayoutAmount[_token];
                        user.rewardPayoutAmount[_token] = 0;
                    }
                    if (_pending > 0) {
                        safeTokenTransfer(_token, _msgSender(), _pending);
                        emit ClaimReward(_msgSender(), address(_token), _pending);
                    }

                    user.lastRewardStakingMultiplier = _stakingMultiplier;
                    user.rewardPayoutAmount[_token] += _fullReward - ((_fullReward * _stakingMultiplier) / MULTIPLIER_PRECISION);
                }
            }
        }

        if (_amount > 0) {
            user.depositTimestamp = block.timestamp;

            if (internalTgtBalance >= _amount) {
                internalTgtBalance = internalTgtBalance - _amount;
            }

            tgt.safeTransfer(_msgSender(), _amount);
            emit Withdraw(_msgSender(), _amount);
        }
    }

    /**
     * @notice Withdraws rewards from the forgoneRewardsPool for the stakers with 2x multiplier and over 350k TGT staked
     */
    function claimExtraRewards() public nonReentrant {
        UserInfo storage user = userInfo[_msgSender()];
        uint256 _stakingMultiplier = getStakingMultiplier(_msgSender());
        require(_stakingMultiplier == 1e18 && user.amount > 350_000, "TGTStaking: not eligible for extra rewards");

        uint256 _len = rewardTokens.length;
        for (uint256 i; i < _len; i++) {
            IERC20 _token = rewardTokens[i];

            uint256 _pendingExtraReward = (user.amount * forgoneRewardsPool[_token]) / internalTgtBalance - user.extraRewardsDebt[_token];
            user.extraRewardsDebt[_token] = _pendingExtraReward;
            forgoneRewardsPool[_token] -= _pendingExtraReward;

            if (_pendingExtraReward != 0) {
                safeTokenTransfer(_token, _msgSender(), _pendingExtraReward);
                emit ClaimExtraReward(_msgSender(), address(_token), _pendingExtraReward);
            }
        }
    }

    /**
     * @notice Withdraws and claims extra rewards at the same time
     */

    function withdrawAndClaimExtraRewards(uint256 _amount) external {
        withdraw(_amount);
        claimExtraRewards();
    }

    /**
     * @notice Withdraw without caring about rewards. EMERGENCY ONLY
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[_msgSender()];

        uint256 _amount = user.amount;
        user.amount = 0;
        user.depositTimestamp = 0;

        uint256 _len = rewardTokens.length;
        for (uint256 i; i < _len; i++) {
            IERC20 _token = rewardTokens[i];
            user.rewardDebt[_token] = 0;
        }
        if (internalTgtBalance >= _amount) {
            internalTgtBalance = internalTgtBalance - _amount;
        }
        tgt.safeTransfer(_msgSender(), _amount);
        emit EmergencyWithdraw(_msgSender(), _amount);
    }

    /**
     * @notice Update reward variables
     * @param _token The address of the reward token
     * @dev Needs to be called before any deposit or withdrawal
     */
    function _updateReward(IERC20 _token) internal {
        require(isRewardToken[_token], "TGTStaking: wrong reward token");

        uint256 _totalTgt = internalTgtBalance;

        uint256 _currRewardBalance = _token.balanceOf(address(this));
        uint256 _rewardBalance = _token == tgt ? _currRewardBalance - _totalTgt : _currRewardBalance;

        // Did TGTStaking receive any token
        if (_rewardBalance == lastRewardBalance[_token] || _totalTgt == 0) {
            return;
        }

        uint256 _accruedReward = _rewardBalance - lastRewardBalance[_token];


        accRewardPerShare[_token] = accRewardPerShare[_token] +
            (_accruedReward * ACC_REWARD_PER_SHARE_PRECISION / _totalTgt);
        lastRewardBalance[_token] = _rewardBalance;
//        console.log("accRewardPerShare after update: %s", accRewardPerShare[_token]);
    }

    /**
     * @notice Safe token transfer function, just in case if rounding error
     * causes pool to not have enough reward tokens
     * @param _token The address of then token to transfer
     * @param _to The address that will receive `_amount` `rewardToken`
     * @param _amount The amount to send to `_to`
     */
    function safeTokenTransfer(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) internal {
        uint256 _currRewardBalance = _token.balanceOf(address(this));
        uint256 _rewardBalance = _token == tgt ? _currRewardBalance - internalTgtBalance : _currRewardBalance;

        if (_amount > _rewardBalance) {
            lastRewardBalance[_token] = lastRewardBalance[_token] - _rewardBalance;
            _token.safeTransfer(_to, _rewardBalance);
        } else {
            if (lastRewardBalance[_token] < _amount) {
                lastRewardBalance[_token] = 0;
            } else {
                lastRewardBalance[_token] = lastRewardBalance[_token] - _amount;
            }
            _token.safeTransfer(_to, _amount);
        }
    }

    /// @notice This function returns the staking multiplier based on the time passed since the user deposited
    /// @param _user The address of the user
    function getStakingMultiplier(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        if (user.depositTimestamp == 0) {
            return 0;
        }
        uint256 timeDiff = block.timestamp - user.depositTimestamp;
//        console.log("timeDiff: %s", timeDiff);
        if (timeDiff >= 365 days) {
            return 1e18;
        } else if (timeDiff >= 180 days) {
            if (timeDiff > (180 days)) {
                return (75e16 + calculatePart(25e16, calculatePercentage(timeDiff - 180 days, 185 days)));
            }
            else return 75e16;
        }
        else if (timeDiff >= 7 days) {
            if (timeDiff > 7 days) {
                return (5e17 + calculatePart(25e16, calculatePercentage(timeDiff - 7 days, 173 days)));
            }
            else return 5e17;
        }
        return 0;
    }

    /// @notice This function returns the part of a number based on the percentage(bps) given
    function calculatePart(uint256 amount, uint256 bps) public pure returns (uint256) {
        return amount * bps / 10_000;
    }

    /// @notice  This function returns how much percent 'part' is of 'whole'
    /// @dev For example, if the real percentage is 12.34%, the function will return 1234.
    function calculatePercentage(uint256 part, uint256 whole) public pure returns (uint256) {
        require(whole > 0, "Whole must be greater than zero");

        // Multiply by 10**4 to increase precision
        uint256 tempPart = part * 10 ** 4;

        // Divide by 'whole' and then multiply by 100 to get the percentage
        uint256 percentage = (tempPart / whole);
        return percentage;
    }
}
