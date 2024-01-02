// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./IERC165Upgradeable.sol";
import "./IAccessControl.sol";
import "./WadRayMath.sol";

import "./ActivityRewardDistributorStorage.sol";
import "./Constants.sol";
import "./IActivityRewardDistributor.sol";
import "./IWhiteBlackList.sol";
import "./ITreasury.sol";

contract ActivityRewardDistributor is IActivityRewardDistributor, ActivityRewardDistributorStorage {
    using WadRayMath for uint256;

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Modifier that checks if the caller has a specific role.
     * @param _role The role identifier to check.
     */
    modifier onlyRole(bytes32 _role) {
        _require(IAccessControl(registry).hasRole(_role, msg.sender), Errors.FORBIDDEN.selector);
        _;
    }

    /**
     * @dev Modifier to check if the sender is not blacklisted.
     */
    modifier notBlackListed() {
        _require(!whiteBlackList.isBlackListed(msg.sender), Errors.SENDER_IS_BLACKLISTED.selector);
        _;
    }

    /**
     * @inheritdoc IActivityRewardDistributor
     */
    function initialize(
        IERC20 _pmx,
        IPrimexDNS _dns,
        address _registry,
        address _treasury,
        ITraderBalanceVault _traderBalanceVault,
        IWhiteBlackList _whiteBlackList
    ) external override initializer {
        _require(
            IERC165Upgradeable(_registry).supportsInterface(type(IAccessControl).interfaceId) &&
                IERC165Upgradeable(address(_dns)).supportsInterface(type(IPrimexDNS).interfaceId) &&
                IERC165Upgradeable(address(_traderBalanceVault)).supportsInterface(
                    type(ITraderBalanceVault).interfaceId
                ) &&
                IERC165Upgradeable(address(_pmx)).supportsInterface(type(IERC20).interfaceId) &&
                IERC165Upgradeable(address(_whiteBlackList)).supportsInterface(type(IWhiteBlackList).interfaceId) &&
                IERC165Upgradeable(_treasury).supportsInterface(type(ITreasury).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        whiteBlackList = _whiteBlackList;
        registry = _registry;
        dns = _dns;
        pmx = _pmx;
        traderBalanceVault = _traderBalanceVault;
        treasury = _treasury;
        __ReentrancyGuard_init();
        __Pausable_init();
        __ERC165_init();
    }

    /**
     * @inheritdoc IActivityRewardDistributor
     */
    function claimReward(
        BucketWithRole[] calldata bucketsArray
    ) external override nonReentrant whenNotPaused notBlackListed {
        uint256 totalReward;

        for (uint256 i; i < bucketsArray.length; i++) {
            BucketInfo storage bucketInfo = buckets[bucketsArray[i].bucketAddress][uint256(bucketsArray[i].role)];
            _require(bucketInfo.totalReward > 0, Errors.TOTAL_REWARD_AMOUNT_IS_ZERO.selector);
            UserInfo storage userInfo = bucketInfo.users[msg.sender];
            uint256 reward = userInfo.fixedReward;
            if (userInfo.oldBalance != 0) {
                if (!bucketInfo.isFinished) {
                    uint256 timestamp = block.timestamp;
                    // there is no need to check that "rewardPerToken" is 0 and raise "endTimestamp",
                    // because "rewardPerToken" is 0 can be in two cases.
                    // The first case is when all funds are withdrawn from the bucket,
                    // but in this case "userInfo.oldBalance != 0" check will work,
                    // The second case is when rewardPerDay is set to 0, but then bucketInfo.endTimestamp = type(uint256).max
                    if (timestamp >= bucketInfo.endTimestamp) {
                        bucketInfo.isFinished = true;
                        timestamp = bucketInfo.endTimestamp;
                    }
                    bucketInfo.rewardIndex += _accumulatedRewardIndex(
                        bucketInfo.rewardPerToken,
                        timestamp,
                        bucketInfo.lastUpdatedTimestamp
                    );
                    bucketInfo.lastUpdatedTimestamp = timestamp;
                }

                reward += _calculateUserAccumulatedReward(
                    userInfo.oldBalance,
                    bucketInfo.rewardIndex,
                    userInfo.lastUpdatedRewardIndex
                );
                userInfo.lastUpdatedRewardIndex = bucketInfo.rewardIndex;
            }
            _require(reward > 0, Errors.REWARD_AMOUNT_IS_ZERO.selector);

            totalReward += reward;

            delete userInfo.fixedReward;
            emit ClaimReward(msg.sender, bucketsArray[i].bucketAddress, bucketsArray[i].role, reward);
        }

        pmx.transfer(address(traderBalanceVault), totalReward);
        traderBalanceVault.topUpAvailableBalance(msg.sender, address(pmx), totalReward);
    }

    /**
     * @inheritdoc IActivityRewardDistributor
     */
    function setupBucket(
        address bucket,
        Role role,
        uint256 increaseAmount,
        uint256 rewardPerDay
    ) external override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        BucketInfo storage bucketInfo = buckets[bucket][uint256(role)];
        uint256 fixedReward = getBucketAccumulatedReward(bucket, role);
        if (bucketInfo.rewardPerDay != rewardPerDay) {
            bucketInfo.fixedReward = fixedReward;
            uint256 timestamp = bucketInfo.totalReward > fixedReward ? block.timestamp : bucketInfo.endTimestamp;
            bucketInfo.rewardIndex += _accumulatedRewardIndex(
                bucketInfo.rewardPerToken,
                timestamp,
                bucketInfo.lastUpdatedTimestamp
            );
            bucketInfo.lastUpdatedTimestamp = block.timestamp;
            bucketInfo.rewardPerDay = rewardPerDay;
            bucketInfo.rewardPerToken = _calculateRewardPerToken(rewardPerDay, bucketInfo.scaledTotalSupply);
            bucketInfo.lastUpdatedRewardTimestamp = block.timestamp;
        }

        if (increaseAmount > 0) {
            if (bucketInfo.totalReward == fixedReward) {
                bucketInfo.lastUpdatedTimestamp = block.timestamp;
                bucketInfo.fixedReward = fixedReward;
                bucketInfo.lastUpdatedRewardTimestamp = block.timestamp;
                bucketInfo.isFinished = false;
            }

            bucketInfo.totalReward += increaseAmount;
            pmx.transferFrom(msg.sender, address(this), increaseAmount);
        }

        bucketInfo.endTimestamp = bucketInfo.rewardPerDay == 0
            ? type(uint256).max
            : block.timestamp +
                ((bucketInfo.totalReward - bucketInfo.fixedReward) * SECONDS_PER_DAY) /
                bucketInfo.rewardPerDay;
    }

    /**
     * @inheritdoc IActivityRewardDistributor
     */
    function decreaseRewardPerDay(
        address bucket,
        Role role,
        uint256 rewardPerDay
    ) external override onlyRole(EMERGENCY_ADMIN) {
        BucketInfo storage bucketInfo = buckets[bucket][uint256(role)];
        _require(rewardPerDay < bucketInfo.rewardPerDay, Errors.REWARD_PER_DAY_IS_NOT_CORRECT.selector);

        bucketInfo.fixedReward = getBucketAccumulatedReward(bucket, role);
        uint256 timestamp = bucketInfo.totalReward > bucketInfo.fixedReward ? block.timestamp : bucketInfo.endTimestamp;
        bucketInfo.rewardIndex += _accumulatedRewardIndex(
            bucketInfo.rewardPerToken,
            timestamp,
            bucketInfo.lastUpdatedTimestamp
        );
        bucketInfo.lastUpdatedTimestamp = block.timestamp;
        bucketInfo.rewardPerDay = rewardPerDay;
        bucketInfo.rewardPerToken = _calculateRewardPerToken(rewardPerDay, bucketInfo.scaledTotalSupply);
        bucketInfo.lastUpdatedRewardTimestamp = block.timestamp;
        bucketInfo.endTimestamp = rewardPerDay == 0
            ? type(uint256).max
            : block.timestamp +
                ((bucketInfo.totalReward - bucketInfo.fixedReward) * SECONDS_PER_DAY) /
                bucketInfo.rewardPerDay;
    }

    /**
     * @inheritdoc IPausable
     */
    function pause() external override onlyRole(EMERGENCY_ADMIN) {
        _pause();
    }

    /**
     * @inheritdoc IPausable
     */
    function unpause() external override onlyRole(SMALL_TIMELOCK_ADMIN) {
        _unpause();
    }

    /**
     * @inheritdoc IActivityRewardDistributor
     */
    function withdrawPmx(address bucket, Role role, uint256 amount) external override onlyRole(BIG_TIMELOCK_ADMIN) {
        BucketInfo storage bucketInfo = buckets[bucket][uint256(role)];
        uint256 fixedReward = getBucketAccumulatedReward(bucket, role);
        _require(bucketInfo.totalReward - fixedReward >= amount, Errors.AMOUNT_EXCEEDS_AVAILABLE_BALANCE.selector);
        bucketInfo.totalReward -= amount;
        bucketInfo.endTimestamp = bucketInfo.rewardPerDay == 0
            ? type(uint256).max
            : block.timestamp + ((bucketInfo.totalReward - fixedReward) * SECONDS_PER_DAY) / bucketInfo.rewardPerDay;
        IERC20(pmx).transfer(treasury, amount);
    }

    /**
     * @inheritdoc IActivityRewardDistributor
     */
    function updateUserActivity(IBucket bucket, address user, uint256 newBalance, Role role) public override {
        (address bucketAddress, , , ) = dns.buckets(bucket.name());
        _require(bucketAddress != address(0), Errors.ZERO_BUCKET_ADDRESS.selector);
        _require(msg.sender == _getToken(bucketAddress, role), Errors.FORBIDDEN.selector);

        BucketInfo storage bucketInfo = buckets[bucketAddress][uint256(role)];
        if (bucketInfo.totalReward == 0 || bucketInfo.isFinished || bucketInfo.rewardPerDay == 0) return;

        address[] memory users = new address[](1);
        users[0] = user;
        uint256[] memory newBalances = new uint256[](1);
        newBalances[0] = newBalance;
        _updateBucketInfo(bucketInfo, users, newBalances, 1, true);
    }

    /**
     * @inheritdoc IActivityRewardDistributor
     */
    function updateUsersActivities(
        IBucket bucket,
        address[] calldata users,
        uint256[] calldata newBalances,
        uint256 length,
        Role role
    ) public override {
        (address bucketAddress, , , ) = dns.buckets(bucket.name());
        _require(msg.sender == _getToken(bucketAddress, role), Errors.FORBIDDEN.selector);

        BucketInfo storage bucketInfo = buckets[bucketAddress][uint256(role)];
        if (bucketInfo.totalReward == 0 || bucketInfo.isFinished || bucketInfo.rewardPerDay == 0) return;
        _updateBucketInfo(bucketInfo, users, newBalances, length, role == Role.TRADER);
    }

    /**
     * @inheritdoc IActivityRewardDistributor
     */
    function getBucketAccumulatedReward(address bucket, Role role) public view override returns (uint256) {
        BucketInfo storage currentBucket = buckets[bucket][uint256(role)];
        if (currentBucket.lastUpdatedRewardTimestamp == 0) return 0;

        uint256 lastUpdatedRewardTimestamp = currentBucket.lastUpdatedRewardTimestamp;
        uint256 endTimestamp = currentBucket.endTimestamp;

        if (currentBucket.rewardPerToken == 0) {
            uint256 unusedTime = block.timestamp - currentBucket.lastUpdatedTimestamp;
            lastUpdatedRewardTimestamp += unusedTime;
            if (endTimestamp != type(uint256).max) {
                endTimestamp += unusedTime;
            }
        }
        if (block.timestamp >= endTimestamp) return currentBucket.totalReward;

        return
            currentBucket.fixedReward +
            ((block.timestamp - lastUpdatedRewardTimestamp) * currentBucket.rewardPerDay) /
            SECONDS_PER_DAY;
    }

    /**
     * @inheritdoc IActivityRewardDistributor
     */
    function getClaimableReward(
        BucketWithRole[] calldata bucketsArray,
        address user
    ) public view override returns (uint256) {
        uint256 reward;
        for (uint256 i; i < bucketsArray.length; i++) {
            BucketInfo storage bucketInfo = buckets[bucketsArray[i].bucketAddress][uint256(bucketsArray[i].role)];
            if (bucketInfo.totalReward == 0) continue;

            UserInfo storage userInfo = bucketInfo.users[user];
            if (userInfo.oldBalance == 0) {
                reward += userInfo.fixedReward;
                continue;
            }

            uint256 rewardIndex = bucketInfo.rewardIndex;
            if (!bucketInfo.isFinished) {
                uint256 timestamp = block.timestamp;
                if (timestamp >= bucketInfo.endTimestamp) {
                    timestamp = bucketInfo.endTimestamp;
                }
                rewardIndex += _accumulatedRewardIndex(
                    bucketInfo.rewardPerToken,
                    timestamp,
                    bucketInfo.lastUpdatedTimestamp
                );
            }
            reward += (userInfo.fixedReward +
                _calculateUserAccumulatedReward(userInfo.oldBalance, rewardIndex, userInfo.lastUpdatedRewardIndex));
        }
        return reward;
    }

    /**
     * @inheritdoc IActivityRewardDistributor
     */
    function getUserInfoFromBucket(
        address bucket,
        Role role,
        address user
    ) public view override returns (UserInfo memory) {
        return buckets[bucket][uint256(role)].users[user];
    }

    /**
     * @notice Interface checker
     * @param _interfaceId The interface id to check
     */
    function supportsInterface(bytes4 _interfaceId) public view override returns (bool) {
        return _interfaceId == type(IActivityRewardDistributor).interfaceId || super.supportsInterface(_interfaceId);
    }

    /**
     * @notice Updates information in UserInfo struct
     * @param bucketInfo  The storage reference to BucketInfo struct
     * @param user  User address
     * @param newBalance  User balance of PToken or DebtToken after action
     */
    function _fixUserReward(BucketInfo storage bucketInfo, address user, uint256 newBalance) internal {
        UserInfo storage userInfo = bucketInfo.users[user];
        userInfo.fixedReward += _calculateUserAccumulatedReward(
            userInfo.oldBalance,
            bucketInfo.rewardIndex,
            userInfo.lastUpdatedRewardIndex
        );
        userInfo.lastUpdatedRewardIndex = bucketInfo.rewardIndex;
        userInfo.oldBalance = newBalance;
    }

    /**
     * @notice Updates BucketInfo struct
     * @param bucketInfo  The storage reference to BucketInfo struct
     * @param needUpdateRPT  Scaled totalSupply of PToken or DebtToken
     */
    function _updateBucketInfo(
        BucketInfo storage bucketInfo,
        address[] memory users,
        uint256[] memory newBalances,
        uint256 length,
        bool needUpdateRPT
    ) internal {
        uint256 timestamp = block.timestamp;
        if (bucketInfo.rewardPerToken == 0) {
            uint256 unusedTime = timestamp - bucketInfo.lastUpdatedTimestamp;
            bucketInfo.endTimestamp += unusedTime;
            bucketInfo.lastUpdatedRewardTimestamp += unusedTime;
        } else {
            if (timestamp >= bucketInfo.endTimestamp) {
                bucketInfo.isFinished = true;
                timestamp = bucketInfo.endTimestamp;
            }
            bucketInfo.rewardIndex += _accumulatedRewardIndex(
                bucketInfo.rewardPerToken,
                timestamp,
                bucketInfo.lastUpdatedTimestamp
            );
        }
        bucketInfo.lastUpdatedTimestamp = timestamp;
        if (needUpdateRPT) {
            for (uint256 i; i < length; i++) {
                bucketInfo.scaledTotalSupply =
                    bucketInfo.scaledTotalSupply +
                    newBalances[i] -
                    bucketInfo.users[users[i]].oldBalance;
                _fixUserReward(bucketInfo, users[i], newBalances[i]);
            }
            bucketInfo.rewardPerToken = _calculateRewardPerToken(bucketInfo.rewardPerDay, bucketInfo.scaledTotalSupply);
        } else {
            for (uint256 i; i < length; i++) {
                _fixUserReward(bucketInfo, users[i], newBalances[i]);
            }
        }
    }

    /**
     * @notice Returns the token address for a specific bucket and role.
     * @param bucket The address of the bucket for which to retrieve the token.
     * @param role The role associated with the user
     * @return tokenAddress The address of the token
     */
    function _getToken(address bucket, Role role) internal view returns (address tokenAddress) {
        if (role == Role.LENDER) {
            tokenAddress = address(IBucket(bucket).pToken());
        } else {
            tokenAddress = address(IBucket(bucket).debtToken());
        }
    }

    /**
     * @notice Calculates reward in PMX per token
     * @dev decimals of rewardPerDay is 18 (PMX decimals)
     * X - decimality of the token whose scaledTotalSupply
     * decimals of output is 18+18(from WadRayMath wdiv) - X
     * @param rewardPerDay  Current reward in PMX per day
     * @param scaledTotalSupply  Scaled totalSupply of PToken or DebtToken
     * @return uint256  reward in PMX per token
     */
    function _calculateRewardPerToken(uint256 rewardPerDay, uint256 scaledTotalSupply) internal pure returns (uint256) {
        // wdiv without rounding up
        return scaledTotalSupply == 0 ? 0 : ((rewardPerDay / SECONDS_PER_DAY) * WadRayMath.WAD) / (scaledTotalSupply);
    }

    /**
     * @notice Calculates rewardIndex for specific rewardPerToken and timestamps
     * @dev decimals of output is decimals of _calculateRewardPerToken output
     * @param rewardPerToken  Current reward in PMX per token
     * @param currentTimestamp  Current timestamp of the block
     * @param bucketLastUpdatedTimestamp  Last updated timestamp
     * @return uint256  Calculated rewardIndex
     */
    function _accumulatedRewardIndex(
        uint256 rewardPerToken,
        uint256 currentTimestamp,
        uint256 bucketLastUpdatedTimestamp
    ) internal pure returns (uint256) {
        return rewardPerToken * (currentTimestamp - bucketLastUpdatedTimestamp);
    }

    /**
     * @notice Calculates the accumulated reward for a user based on their old balance, new rewardIndex, and old rewardIndex.
     * @dev decimals of output is decimals of _accumulatedRewardIndex output + X - 18(from WadRayMath wmul)
     * decimals of output is (18+18-X)+X-18 = 18 PMX decimals
     * @param _oldBalance The user's previous balance.
     * @param _newRewardIndex The new reward index.
     * @param _oldRewardIndex The old reward index.
     * @return The accumulated reward for the user.
     */
    function _calculateUserAccumulatedReward(
        uint256 _oldBalance,
        uint256 _newRewardIndex,
        uint256 _oldRewardIndex
    ) internal pure returns (uint256) {
        // wmul without rounding up
        return (_oldBalance * (_newRewardIndex - _oldRewardIndex)) / WadRayMath.WAD;
    }
}
