// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./Address.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Ownable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./SafeERC20.sol";

import "./IBribeRewarderFactory.sol";
import "./IMultiRewarderV2.sol";

/**
 * This is a sample contract to be used in the Master contract for partners to reward
 * stakers with their native token alongside WOM.
 *
 * It assumes no minting rights, so requires a set amount of reward tokens to be transferred to this contract prior.
 * E.g. say you've allocated 100,000 XYZ to the WOM-XYZ farm over 30 days. Then you would need to transfer
 * 100,000 XYZ and set the block reward accordingly so it's fully distributed after 30 days.
 *
 * - This contract has no knowledge on the LP amount and Master is
 *   responsible to pass the amount into this contract
 * - Supports multiple reward tokens
 * - Supports bribe rewarder factory
 */
contract MultiRewarderPerSecV2 is
    IMultiRewarderV2,
    Initializable,
    OwnableUpgradeable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    bytes32 public constant ROLE_OPERATOR = keccak256('operator');
    uint256 public constant ACC_TOKEN_PRECISION = 1e18;
    uint256 public constant MAX_REWARD_TOKENS = 10;

    struct UserBalanceInfo {
        uint256 amount;
    }

    struct UserRewardInfo {
        // if the pool is activated, rewardDebt should be > 0
        uint128 rewardDebt; // 20.18 fixed point. distributed reward per weight
        uint128 unpaidRewards; // 20.18 fixed point.
    }

    /// @notice Info of each reward token.
    struct RewardInfo {
        /// slot
        IERC20 rewardToken; // if rewardToken is 0, native token is used as reward token
        uint96 tokenPerSec; // 10.18 fixed point. The emission rate in tokens per second.
        // This rate may not reflect the current rate in cases where emission has not started or has stopped due to surplus <= 0.

        /// slot
        uint128 accTokenPerShare; // 26.12 fixed point. Amount of reward token each LP token is worth.
        // This value increases when rewards are being distributed.
        uint128 distributedAmount; // 20.18 fixed point, depending on the decimals of the reward token. This value is used to
        // track the amount of distributed tokens. If `distributedAmount` is closed to the amount of total received
        // tokens, we should refill reward or prepare to stop distributing reward.

        /// slot
        uint128 claimedAmount; // 20.18 fixed point. Total amount claimed by all users.
        // We can derive the unclaimed amount: distributedAmount - claimedAmount
        uint40 lastRewardTimestamp; // The timestamp up to which rewards have already been distributed.
        // If set to a future value, it indicates that the emission has not started yet.
    }

    /**
     * Visualization of the relationship between distributedAmount, claimedAmount, rewardToDistribute, availableReward, surplus and balance:
     *
     * Case: emission is active. rewardToDistribute is growing at the rate of tokenPerSec.
     * |<--------------distributedAmount------------->|<--rewardToDistribute*-->|
     * |<-----claimedAmount----->|<-------------------------balance------------------------->|
     *                                                |<-----------availableReward*--------->|
     *                           |<-unclaimedAmount*->|                         |<-surplus*->|
     *
     * Case: reward running out. rewardToDistribute stopped growing. it is capped at availableReward.
     * |<--------------distributedAmount------------->|<---------rewardToDistribute*-------->|
     * |<-----claimedAmount----->|<-------------------------balance------------------------->|
     *                                                |<-----------availableReward*--------->|
     *                           |<-unclaimedAmount*->|                                       surplus* = 0
     *
     * Case: balance emptied after emergencyWithdraw.
     * |<--------------distributedAmount------------->| rewardToDistribute* = 0
     * |<-----claimedAmount----->|                      balance = 0, availableReward* = 0
     *                           |<-unclaimedAmount*->| surplus* = - unclaimedAmount* (negative to indicate deficit)
     *
     * (Variables with * are not in the RewardInfo state, but can be derived from it.)
     *
     * balance, is the amount of reward token in this contract. Not all of them are available for distribution as some are reserved
     * for unclaimed rewards.
     * distributedAmount, is the amount of reward token that has been distributed up to lastRewardTimestamp.
     * claimedAmount, is the amount of reward token that has been claimed by users. claimedAmount always <= distributedAmount.
     * unclaimedAmount = distributedAmount - claimedAmount, is the amount of reward token in balance that is reserved to be claimed by users.
     * availableReward = balance - unclaimedAmount, is the amount inside balance that is available for distribution (not reserved for
     * unclaimed rewards).
     * rewardToDistribute is the accumulated reward from [lastRewardTimestamp, now] that is yet to be distributed. as distributedAmount only
     * accounts for the distributed amount up to lastRewardTimestamp. it is used in _updateReward(), and to be added to distributedAmount.
     * to prevent bad debt, rewardToDistribute is capped at availableReward. as we cannot distribute more than the availableReward.
     * rewardToDistribute = min(tokenPerSec * (now - lastRewardTimestamp), availableReward)
     * surplus = availableReward - rewardToDistribute, is the amount inside balance that is available for future distribution.
     */

    IERC20 public lpToken;
    address public master;

    /// @notice Info of the reward tokens.
    RewardInfo[] public rewardInfos;
    /// @notice userAddr => UserBalanceInfo
    mapping(address => UserBalanceInfo) public userBalanceInfo;
    /// @notice tokenId => userId => UserRewardInfo
    mapping(uint256 => mapping(address => UserRewardInfo)) public userRewardInfo;

    IBribeRewarderFactory public bribeFactory;
    bool public isDeprecated;

    event OnReward(address indexed rewardToken, address indexed user, uint256 amount);
    event RewardRateUpdated(address indexed rewardToken, uint256 oldRate, uint256 newRate);
    event StartTimeUpdated(address indexed rewardToken, uint40 newStartTime);
    event IsDeprecatedUpdated(bool isDeprecated);

    modifier onlyMaster() {
        require(msg.sender == address(master), 'onlyMaster: only Master can call this function');
        _;
    }

    /// @notice payable function needed to receive BNB
    receive() external payable {}

    /**
     * @notice Initializes pool. Dev is set to be the account calling this function.
     */
    function initialize(
        IBribeRewarderFactory _bribeFactory,
        address _master,
        IERC20 _lpToken,
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec
    ) public virtual initializer {
        require(
            Address.isContract(address(_rewardToken)) || address(_rewardToken) == address(0),
            'constructor: reward token must be a valid contract'
        );
        require(Address.isContract(address(_lpToken)), 'constructor: LP token must be a valid contract');
        require(Address.isContract(address(_master)), 'constructor: Master must be a valid contract');
        require(_startTimestamp >= block.timestamp, 'constructor: invalid _startTimestamp');

        __Ownable_init();
        __AccessControlEnumerable_init_unchained();
        __ReentrancyGuard_init_unchained();

        bribeFactory = _bribeFactory; // bribeFactory can be 0 address
        master = _master;
        lpToken = _lpToken;

        // use non-zero amount for accTokenPerShare as we want to check if user
        // has activated the pool by checking rewardDebt > 0
        RewardInfo memory reward = RewardInfo({
            rewardToken: _rewardToken,
            tokenPerSec: _tokenPerSec,
            accTokenPerShare: 1e18,
            distributedAmount: 0,
            claimedAmount: 0,
            lastRewardTimestamp: uint40(_startTimestamp)
        });
        emit RewardRateUpdated(address(reward.rewardToken), 0, _tokenPerSec);
        emit StartTimeUpdated(address(reward.rewardToken), uint40(_startTimestamp));
        rewardInfos.push(reward);
    }

    function addOperator(address _operator) external onlyOwner {
        _grantRole(ROLE_OPERATOR, _operator);
    }

    function removeOperator(address _operator) external onlyOwner {
        _revokeRole(ROLE_OPERATOR, _operator);
    }

    function setIsDeprecated(bool _isDeprecated) external onlyOwner {
        isDeprecated = _isDeprecated;
        emit IsDeprecatedUpdated(_isDeprecated);
    }

    function addRewardToken(IERC20 _rewardToken, uint40 _startTimestampOrNow, uint96 _tokenPerSec) external virtual {
        require(hasRole(ROLE_OPERATOR, msg.sender) || msg.sender == owner(), 'not authorized');
        // Check `bribeFactory.isRewardTokenWhitelisted` if needed
        require(
            address(bribeFactory) == address(0) || bribeFactory.isRewardTokenWhitelisted(_rewardToken),
            'reward token must be whitelisted by bribe factory'
        );

        _addRewardToken(_rewardToken, _startTimestampOrNow, _tokenPerSec);
    }

    function _addRewardToken(IERC20 _rewardToken, uint40 _startTimestampOrNow, uint96 _tokenPerSec) internal {
        require(
            Address.isContract(address(_rewardToken)) || address(_rewardToken) == address(0),
            'reward token must be a valid contract'
        );
        require(_startTimestampOrNow == 0 || _startTimestampOrNow >= block.timestamp, 'invalid _startTimestamp');
        uint256 length = rewardInfos.length;
        require(length < MAX_REWARD_TOKENS, 'reward token length exceeded');
        for (uint256 i; i < length; ++i) {
            require(rewardInfos[i].rewardToken != _rewardToken, 'token has already been added');
        }
        _updateReward();
        uint40 startTimestamp = _startTimestampOrNow == 0 ? uint40(block.timestamp) : _startTimestampOrNow;
        // use non-zero amount for accTokenPerShare as we want to check if user
        // has activated the pool by checking rewardDebt > 0
        RewardInfo memory reward = RewardInfo({
            rewardToken: _rewardToken,
            tokenPerSec: _tokenPerSec,
            accTokenPerShare: 1e18,
            distributedAmount: 0,
            claimedAmount: 0,
            lastRewardTimestamp: startTimestamp
        });
        rewardInfos.push(reward);
        emit StartTimeUpdated(address(reward.rewardToken), startTimestamp);
        emit RewardRateUpdated(address(reward.rewardToken), 0, _tokenPerSec);
    }

    function updateReward() public {
        _updateReward();
    }

    /// @dev This function should be called before lpSupply and sumOfFactors update
    function _updateReward() internal {
        _updateReward(_getTotalShare());
    }

    function _updateReward(uint256 totalShare) internal {
        uint256 length = rewardInfos.length;
        uint256[] memory toDistribute = rewardsToDistribute();
        for (uint256 i; i < length; ++i) {
            RewardInfo storage info = rewardInfos[i];
            uint256 rewardToDistribute = toDistribute[i];
            if (rewardToDistribute > 0) {
                // use `max(totalShare, 1e18)` in case of overflow
                info.accTokenPerShare += toUint128((rewardToDistribute * ACC_TOKEN_PRECISION) / max(totalShare, 1e18));
                info.distributedAmount += toUint128(rewardToDistribute);
            }
            // update lastRewardTimestamp even if no reward is distributed.
            if (info.lastRewardTimestamp < block.timestamp) {
                // but don't update if info.lastRewardTimestamp is set in the future,
                // otherwise we would be starting the emission earlier than it's supposed to.
                info.lastRewardTimestamp = uint40(block.timestamp);
            }
        }
    }

    /// @notice Sets the distribution reward rate, and updates the emission start time if specified.
    /// @param _tokenId The token id
    /// @param _tokenPerSec The number of tokens to distribute per second
    /// @param _startTimestampToOverride the start time for the token emission.
    ///        A value of 0 indicates no changes, while a future timestamp starts the emission at the specified time.
    function setRewardRate(uint256 _tokenId, uint96 _tokenPerSec, uint40 _startTimestampToOverride) external {
        require(hasRole(ROLE_OPERATOR, msg.sender) || msg.sender == owner(), 'not authorized');
        require(_tokenId < rewardInfos.length, 'invalid _tokenId');
        require(
            _startTimestampToOverride == 0 || _startTimestampToOverride >= block.timestamp,
            'invalid _startTimestampToOverride'
        );
        require(_tokenPerSec <= 10000e18, 'reward rate too high'); // in case of accTokenPerShare overflow
        _updateReward();
        RewardInfo storage info = rewardInfos[_tokenId];
        uint256 oldRate = info.tokenPerSec;
        info.tokenPerSec = _tokenPerSec;
        if (_startTimestampToOverride > 0) {
            info.lastRewardTimestamp = _startTimestampToOverride;
            emit StartTimeUpdated(address(info.rewardToken), _startTimestampToOverride);
        }
        emit RewardRateUpdated(address(rewardInfos[_tokenId].rewardToken), oldRate, _tokenPerSec);
    }

    /// @notice Function called by Master whenever staker claims WOM harvest.
    /// @notice Allows staker to also receive a 2nd reward token.
    /// @dev Assume `_getTotalShare` isn't updated yet when this function is called
    /// @param _user Address of user
    /// @param _lpAmount The new amount of LP
    function onReward(
        address _user,
        uint256 _lpAmount
    ) external virtual override onlyMaster nonReentrant returns (uint256[] memory rewards) {
        _updateReward();
        return _onReward(_user, _lpAmount);
    }

    function _onReward(address _user, uint256 _lpAmount) internal virtual returns (uint256[] memory rewards) {
        uint256 length = rewardInfos.length;
        rewards = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            RewardInfo storage info = rewardInfos[i];
            UserRewardInfo storage user = userRewardInfo[i][_user];
            IERC20 rewardToken = info.rewardToken;

            if (user.rewardDebt > 0 || user.unpaidRewards > 0) {
                // rewardDebt > 0 indicates the user has activated the pool and we should distribute rewards
                uint256 pending = ((userBalanceInfo[_user].amount * uint256(info.accTokenPerShare)) /
                    ACC_TOKEN_PRECISION) +
                    user.unpaidRewards -
                    user.rewardDebt;

                if (address(rewardToken) == address(0)) {
                    // is native token
                    uint256 tokenBalance = address(this).balance;
                    if (pending > tokenBalance) {
                        // Note: this line may fail if the receiver is a contract and refuse to receive BNB
                        (bool success, ) = _user.call{value: tokenBalance}('');
                        require(success, 'Transfer failed');
                        rewards[i] = tokenBalance;
                        info.claimedAmount += toUint128(tokenBalance);
                        user.unpaidRewards = toUint128(pending - tokenBalance);
                    } else {
                        (bool success, ) = _user.call{value: pending}('');
                        require(success, 'Transfer failed');
                        rewards[i] = pending;
                        info.claimedAmount += toUint128(pending);
                        user.unpaidRewards = 0;
                    }
                } else {
                    // ERC20 token
                    uint256 tokenBalance = rewardToken.balanceOf(address(this));
                    if (pending > tokenBalance) {
                        rewardToken.safeTransfer(_user, tokenBalance);
                        rewards[i] = tokenBalance;
                        info.claimedAmount += toUint128(tokenBalance);
                        user.unpaidRewards = toUint128(pending - tokenBalance);
                    } else {
                        rewardToken.safeTransfer(_user, pending);
                        rewards[i] = pending;
                        info.claimedAmount += toUint128(pending);
                        user.unpaidRewards = 0;
                    }
                }
            }

            user.rewardDebt = toUint128((_lpAmount * info.accTokenPerShare) / ACC_TOKEN_PRECISION);
            emit OnReward(address(rewardToken), _user, rewards[i]);
        }
        userBalanceInfo[_user].amount = toUint128(_lpAmount);
    }

    function emergencyClaimReward() external nonReentrant returns (uint256[] memory rewards) {
        _updateReward();
        require(isDeprecated, 'rewarder / bribe is not deprecated');
        return _onReward(msg.sender, 0);
    }

    /// @notice returns reward length
    function rewardLength() public view virtual override returns (uint256) {
        return rewardInfos.length;
    }

    /// @notice View function to see pending tokens that have been distributed but not claimed by the user yet.
    /// @param _user Address of user.
    /// @return rewards_ reward for a given user.
    function pendingTokens(address _user) public view virtual override returns (uint256[] memory rewards_) {
        uint256 length = rewardInfos.length;
        rewards_ = new uint256[](length);

        uint256[] memory toDistribute = rewardsToDistribute();
        for (uint256 i; i < length; ++i) {
            RewardInfo memory info = rewardInfos[i];
            UserRewardInfo storage user = userRewardInfo[i][_user];

            uint256 accTokenPerShare = info.accTokenPerShare;
            uint256 totalShare = _getTotalShare();
            if (totalShare > 0) {
                uint256 rewardToDistribute = toDistribute[i];
                // use `max(totalShare, 1e18)` in case of overflow
                accTokenPerShare += (rewardToDistribute * ACC_TOKEN_PRECISION) / max(totalShare, 1e18);
            }

            rewards_[i] =
                ((userBalanceInfo[_user].amount * uint256(accTokenPerShare)) / ACC_TOKEN_PRECISION) -
                user.rewardDebt +
                user.unpaidRewards;
        }
    }

    /// @notice the amount of reward accumulated since the lastRewardTimestamp and is to be distributed.
    /// the case that lastRewardTimestamp is in the future is also handled
    function rewardsToDistribute() public view returns (uint256[] memory rewards_) {
        uint256 length = rewardInfos.length;
        rewards_ = new uint256[](length);

        uint256[] memory rewardBalances = balances();

        for (uint256 i; i < length; ++i) {
            RewardInfo memory info = rewardInfos[i];
            // if (block.timestamp < info.lastRewardTimestamp), then emission has not started yet.
            if (block.timestamp < info.lastRewardTimestamp) continue;

            uint40 timeElapsed = uint40(block.timestamp) - info.lastRewardTimestamp;
            uint256 accumulatedReward = uint256(info.tokenPerSec) * timeElapsed;

            // To prevent bad debt, need to cap at availableReward
            uint256 availableReward;
            // this is to handle the underflow case if claimedAmount + balance < distributedAmount,
            // which could happend only if balance was emergencyWithdrawn.
            if (info.claimedAmount + rewardBalances[i] > info.distributedAmount) {
                availableReward = info.claimedAmount + rewardBalances[i] - info.distributedAmount;
            }
            rewards_[i] = min(accumulatedReward, availableReward);
        }
    }

    function _getTotalShare() internal view virtual returns (uint256) {
        return lpToken.balanceOf(address(master));
    }

    /// @notice return an array of reward tokens
    function rewardTokens() public view virtual override returns (IERC20[] memory tokens_) {
        uint256 length = rewardInfos.length;
        tokens_ = new IERC20[](length);
        for (uint256 i; i < length; ++i) {
            RewardInfo memory info = rewardInfos[i];
            tokens_[i] = info.rewardToken;
        }
    }

    /// @notice View function to see surplus of each reward, i.e. reward balance - unclaimed amount
    /// it would be negative if there's bad debt/deficit, which would happend only if some token was emergencyWithdrawn.
    /// @return surpluses_ surpluses of the reward tokens.
    // override.
    function rewardTokenSurpluses() external view virtual returns (int256[] memory surpluses_) {
        return _rewardTokenSurpluses();
    }

    /// @notice View function to see surplus of each reward, i.e. reward balance - unclaimed amount
    /// surplus = claimed amount + balance - distributed amount - rewardToDistribute
    /// @return surpluses_ surpluses of the reward tokens.
    function _rewardTokenSurpluses() internal view returns (int256[] memory surpluses_) {
        uint256 length = rewardInfos.length;
        surpluses_ = new int256[](length);
        uint256[] memory toDistribute = rewardsToDistribute();
        uint256[] memory rewardBalances = balances();

        for (uint256 i; i < length; ++i) {
            RewardInfo memory info = rewardInfos[i];

            surpluses_[i] =
                int256(uint256(info.claimedAmount)) +
                int256(rewardBalances[i]) -
                int256(uint256(info.distributedAmount)) -
                int256(toDistribute[i]);
        }
    }

    function isEmissionActive() external view returns (bool[] memory isActive_) {
        return _isEmissionActive();
    }

    function _isEmissionActive() internal view returns (bool[] memory isActive_) {
        uint256 length = rewardInfos.length;
        isActive_ = new bool[](length);
        int256[] memory surpluses = _rewardTokenSurpluses();
        for (uint256 i; i < length; ++i) {
            RewardInfo memory info = rewardInfos[i];

            // conditions for emission to be active:
            // 1. surplus > 0
            // 2. tokenPerSec > 0
            // 3. lastRewardTimestamp <= block.timestamp
            isActive_[i] = surpluses[i] > 0 && info.tokenPerSec > 0 && info.lastRewardTimestamp <= block.timestamp;
        }
    }

    /// @notice In case rewarder is stopped before emissions finished, this function allows
    /// withdrawal of remaining tokens.
    /// there will be deficit which is equal to the unclaimed amount
    function emergencyWithdraw() external onlyOwner {
        uint256 length = rewardInfos.length;
        for (uint256 i; i < length; ++i) {
            RewardInfo storage info = rewardInfos[i];
            info.tokenPerSec = 0;
            info.lastRewardTimestamp = uint40(block.timestamp);
            emergencyTokenWithdraw(address(info.rewardToken));
        }
    }

    /// @notice avoids loosing funds in case there is any tokens sent to this contract
    /// the reward token will not be stopped and keep accumulating debts
    /// @dev only to be called by owner
    function emergencyTokenWithdraw(address token) public onlyOwner {
        // send that balance back to owner
        if (token == address(0)) {
            // is native token
            (bool success, ) = msg.sender.call{value: address(this).balance}('');
            require(success, 'Transfer failed');
        } else {
            IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
        }
    }

    /// @notice View function to see the timestamp when the reward will runout based on current emission rate and balance left.
    /// a timestamp of 0 indicates that the token is not emitting or already run out.
    /// also works for the case that emission start time (lastRewardTimestamp) is in the future.
    function runoutTimestamps() external view returns (uint40[] memory timestamps_) {
        uint256 length = rewardInfos.length;
        timestamps_ = new uint40[](length);
        uint256[] memory rewardBalances = balances();
        int256[] memory surpluses = _rewardTokenSurpluses();

        for (uint256 i; i < length; ++i) {
            RewardInfo memory info = rewardInfos[i];

            if (surpluses[i] > 0 && info.tokenPerSec > 0) {
                // we have: surplus = claimedAmount + balance - distributedAmount - tokenPerSec * (block.timestamp - lastRewardTimestamp)
                // surplus would reach 0 at runoutTimestamp. therefore, we have the formula:
                // 0 = claimedAmount + balance - distributedAmount - tokenPerSec * (runoutTimestamp - lastRewardTimestamp)
                // Solving for runoutTimestamp:
                // runoutTimestamp = (claimedAmount + balance - distributedAmount + tokenPerSec * lastRewardTimestamp) / tokenPerSec

                timestamps_[i] = uint40(
                    (info.claimedAmount +
                        rewardBalances[i] -
                        info.distributedAmount +
                        info.tokenPerSec *
                        info.lastRewardTimestamp) / info.tokenPerSec
                );
            }
        }
    }

    /// @notice View function to preserve backward compatibility, as the previous version uses rewardInfo instead of rewardInfos
    function rewardInfo(uint256 i) external view returns (RewardInfo memory info) {
        return rewardInfos[i];
    }

    /// @notice View function to see balances of reward token.
    function balances() public view returns (uint256[] memory balances_) {
        uint256 length = rewardInfos.length;
        balances_ = new uint256[](length);

        for (uint256 i; i < length; ++i) {
            RewardInfo storage info = rewardInfos[i];
            if (address(info.rewardToken) == address(0)) {
                // is native token
                balances_[i] = address(this).balance;
            } else {
                balances_[i] = info.rewardToken.balanceOf(address(this));
            }
        }
    }

    function toUint128(uint256 val) internal pure returns (uint128) {
        if (val > type(uint128).max) revert('uint128 overflow');
        return uint128(val);
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x >= y ? x : y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x <= y ? x : y;
    }

    uint256[50] private __gap;
}
