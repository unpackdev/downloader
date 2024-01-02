// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./IAccessControl.sol";
import "./IERC165Upgradeable.sol";
import "./IAccessControl.sol";
import "./WadRayMath.sol";

import "./LiquidityMiningRewardDistributorStorage.sol";
import "./Constants.sol";
import "./IWhiteBlackList.sol";
import "./ILiquidityMiningRewardDistributor.sol";
import "./IBucket.sol";
import "./ITreasury.sol";

contract LiquidityMiningRewardDistributor is
    ILiquidityMiningRewardDistributor,
    LiquidityMiningRewardDistributorStorage
{
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
     * @inheritdoc ILiquidityMiningRewardDistributor
     */
    function initialize(
        IPrimexDNS _primexDNS,
        IERC20 _pmx,
        ITraderBalanceVault _traderBalanceVault,
        address _registry,
        address _treasury,
        uint256 _reinvestmentRate,
        uint256 _reinvestmentDuration,
        IWhiteBlackList _whiteBlackList
    ) external override initializer {
        _require(
            IERC165Upgradeable(address(_pmx)).supportsInterface(type(IERC20).interfaceId) &&
                IERC165Upgradeable(_registry).supportsInterface(type(IAccessControl).interfaceId) &&
                IERC165Upgradeable(_treasury).supportsInterface(type(ITreasury).interfaceId) &&
                IERC165Upgradeable(address(_primexDNS)).supportsInterface(type(IPrimexDNS).interfaceId) &&
                IERC165Upgradeable(address(_traderBalanceVault)).supportsInterface(
                    type(ITraderBalanceVault).interfaceId
                ) &&
                IERC165Upgradeable(address(_whiteBlackList)).supportsInterface(type(IWhiteBlackList).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        _require(_reinvestmentRate <= WadRayMath.WAD, Errors.INVALID_PERCENT_NUMBER.selector);
        treasury = _treasury;
        pmx = _pmx;
        primexDNS = _primexDNS;
        traderBalanceVault = _traderBalanceVault;
        registry = _registry;
        whiteBlackList = _whiteBlackList;
        reinvestmentRate = _reinvestmentRate;
        reinvestmentDuration = _reinvestmentDuration;
        __Pausable_init();
        __ERC165_init();
        __ReentrancyGuard_init();
    }

    /**
     * @inheritdoc ILiquidityMiningRewardDistributor
     */
    function updateBucketReward(string memory _bucketName, uint256 _pmxRewardAmount) external override {
        _require(address(primexDNS) == msg.sender, Errors.FORBIDDEN.selector);
        buckets[_bucketName].totalPmxReward = _pmxRewardAmount;
    }

    /**
     * @inheritdoc ILiquidityMiningRewardDistributor
     */
    function addPoints(
        string memory _bucketName,
        address _user,
        uint256 _miningAmount,
        uint256 _maxStabilizationPeriodEnd,
        uint256 _maxPeriodTime,
        uint256 _currentTimestamp
    ) external override {
        _require(primexDNS.getBucketAddress(_bucketName) == msg.sender, Errors.FORBIDDEN.selector);
        uint256 points = _calculatePoints(_miningAmount, _maxStabilizationPeriodEnd, _maxPeriodTime, _currentTimestamp);
        buckets[_bucketName].totalPoints += points;
        buckets[_bucketName].lendersInfo[_user].points += points;
        buckets[_bucketName].lendersInfo[_user].depositedAmount += _miningAmount;
    }

    /**
     * @inheritdoc ILiquidityMiningRewardDistributor
     */
    function removePoints(string memory _bucketName, address _user, uint256 _amount) external override {
        (address bucketAddress, , , ) = primexDNS.buckets(_bucketName);
        _require(bucketAddress == msg.sender, Errors.FORBIDDEN.selector);
        LenderInfo storage userInfo = buckets[_bucketName].lendersInfo[_user];
        if (userInfo.depositedAmount == _amount || _amount == type(uint256).max) {
            buckets[_bucketName].totalPoints -= userInfo.points;
            delete buckets[_bucketName].lendersInfo[_user];
            delete extraRewards[_user][_bucketName];
            return;
        }
        _require(userInfo.depositedAmount > _amount, Errors.ATTEMPT_TO_WITHDRAW_MORE_THAN_DEPOSITED.selector);

        uint256 multiplier = _amount.wdiv(userInfo.depositedAmount);
        uint256 removedPoints = userInfo.points.wmul(multiplier);

        buckets[_bucketName].totalPoints -= removedPoints;
        userInfo.points -= removedPoints;
        userInfo.depositedAmount -= _amount;
        if (extraRewards[_user][_bucketName] > 0) {
            extraRewards[_user][_bucketName] -= extraRewards[_user][_bucketName].wmul(multiplier);
        }
    }

    /**
     * @inheritdoc ILiquidityMiningRewardDistributor
     */
    function claimReward(string memory _bucketName) external override nonReentrant notBlackListed {
        (address bucketAddress, , , ) = primexDNS.buckets(_bucketName);
        _require(IBucket(bucketAddress).isBucketStable(), Errors.BUCKET_IS_NOT_STABLE.selector);
        uint256 reward = _calculateRewardAndUpdateState(_bucketName, msg.sender, WadRayMath.WAD);
        _claimReward(reward, msg.sender, bucketAddress);
    }

    /**
     * @inheritdoc ILiquidityMiningRewardDistributor
     */
    function reinvest(
        string memory _bucketFrom,
        string memory _bucketTo,
        address _user,
        bool _isBucketToLaunched,
        uint256 _bucketFromLiquidityMiningDeadline
    ) external override {
        address bucketFromAddress = primexDNS.getBucketAddress(_bucketFrom);
        _require(bucketFromAddress == msg.sender, Errors.FORBIDDEN.selector);
        // _bucketTo was checked in _bucketFrom
        _require(
            block.timestamp <= _bucketFromLiquidityMiningDeadline + reinvestmentDuration,
            Errors.DEADLINE_IS_PASSED.selector
        );
        uint256 reward = _calculateRewardAndUpdateState(_bucketFrom, _user, reinvestmentRate);

        if (_isBucketToLaunched) {
            _claimReward(reward, _user, bucketFromAddress);
        } else {
            extraRewards[_user][_bucketTo] += reward;
        }
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
     * @inheritdoc ILiquidityMiningRewardDistributor
     */
    function withdrawPmxByAdmin(string calldata _bucketFrom) external override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        uint256 currentTimestamp = block.timestamp;
        (address bucketAddress, , , ) = primexDNS.buckets(_bucketFrom);
        IBucket.LiquidityMiningParams memory lmParams = IBucket(bucketAddress).getLiquidityMiningParams();
        _require(
            IBucket(bucketAddress).isWithdrawAfterDelistingAvailable() ||
                (currentTimestamp > (lmParams.deadlineTimestamp + reinvestmentDuration) && !lmParams.isBucketLaunched),
            Errors.WITHDRAW_PMX_BY_ADMIN_FORBIDDEN.selector
        );
        // Overflow is not possible because withdrawnRewards is a sum of rewards, where
        // reward is the quotient of dividing (totalPmxReward*user points)/totalPoints
        // and additionally it is reduced by reinvestmentRate which is less than 1.
        // There is no setter for reinvestmentRate for now.
        uint256 amountToWithdraw = buckets[_bucketFrom].totalPmxReward - buckets[_bucketFrom].withdrawnRewards;

        _require(amountToWithdraw != 0, Errors.ZERO_AMOUNT.selector);
        buckets[_bucketFrom].withdrawnRewards = buckets[_bucketFrom].totalPmxReward;
        pmx.transfer(treasury, amountToWithdraw);
        emit WithdrawPmxByAdmin(amountToWithdraw);
    }

    /**
     * @inheritdoc ILiquidityMiningRewardDistributor
     */
    function getLenderInfo(
        string calldata _bucketName,
        address _lender,
        uint256 _timestamp
    )
        external
        view
        override
        returns (uint256 amountInMining, uint256 currentPercent, RewardsInPMX memory rewardsInPMX)
    {
        LenderInfo storage lenderInfo = buckets[_bucketName].lendersInfo[_lender];
        amountInMining = lenderInfo.depositedAmount;
        rewardsInPMX.extraReward = extraRewards[_lender][_bucketName];

        (address bucketAddress, , , ) = primexDNS.buckets(_bucketName);
        // solhint-disable-next-line var-name-mixedcase
        IBucket.LiquidityMiningParams memory LMparams = IBucket(bucketAddress).getLiquidityMiningParams();

        if (buckets[_bucketName].totalPoints == 0) {
            return (amountInMining, currentPercent, rewardsInPMX);
        }

        currentPercent = lenderInfo.points.wdiv(buckets[_bucketName].totalPoints);
        uint256 maxExpectedPoints;
        uint256 minExpectedPoints;
        uint256 multiplier = WadRayMath.WAD;

        if (_timestamp > LMparams.deadlineTimestamp && !LMparams.isBucketLaunched) {
            maxExpectedPoints = buckets[_bucketName].totalPoints;
            minExpectedPoints = buckets[_bucketName].totalPoints;
            multiplier = reinvestmentRate;
        } else if (
            LMparams.isBucketLaunched || LMparams.accumulatingAmount <= IBucket(bucketAddress).availableLiquidity()
        ) {
            maxExpectedPoints = buckets[_bucketName].totalPoints;
            minExpectedPoints = buckets[_bucketName].totalPoints;
        } else {
            uint256 tokensLeft = LMparams.accumulatingAmount - IBucket(bucketAddress).availableLiquidity();
            maxExpectedPoints =
                buckets[_bucketName].totalPoints +
                _calculatePoints(tokensLeft, LMparams.maxStabilizationEndTimestamp, LMparams.maxDuration, _timestamp);

            minExpectedPoints =
                buckets[_bucketName].totalPoints +
                _calculatePoints(tokensLeft, LMparams.stabilizationDuration, LMparams.maxDuration, 0);
        }
        uint256 pointsInPMX = lenderInfo.points * buckets[_bucketName].totalPmxReward;
        rewardsInPMX.minReward = (pointsInPMX / maxExpectedPoints).wmul(multiplier);
        rewardsInPMX.maxReward = (pointsInPMX / minExpectedPoints).wmul(multiplier);

        return (amountInMining, currentPercent, rewardsInPMX);
    }

    /**
     * @inheritdoc ILiquidityMiningRewardDistributor
     */
    function getBucketInfo(
        string calldata _bucketName
    ) external view override returns (uint256 totalPmxReward, uint256 withdrawnRewards, uint256 totalPoints) {
        return (
            buckets[_bucketName].totalPmxReward,
            buckets[_bucketName].withdrawnRewards,
            buckets[_bucketName].totalPoints
        );
    }

    /**
     * @inheritdoc ILiquidityMiningRewardDistributor
     */
    function getLenderAmountInMining(
        string calldata _bucketName,
        address _lender
    ) external view override returns (uint256) {
        return buckets[_bucketName].lendersInfo[_lender].depositedAmount;
    }

    /**
     * @notice Interface checker
     * @param _interfaceId The interface id to check
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(ILiquidityMiningRewardDistributor).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /**
     * @notice Calculates the reward and updates the state for a user in a specific bucket.
     * @param _bucketName The name of the bucket.
     * @param _user The address of the user.
     * @param _multiplicator The multiplicator in WAD format to be applied to the reward calculation.
     * @return reward The calculated reward amount.
     */
    function _calculateRewardAndUpdateState(
        string memory _bucketName,
        address _user,
        uint256 _multiplicator
    ) internal returns (uint256 reward) {
        reward =
            (buckets[_bucketName].lendersInfo[_user].points * buckets[_bucketName].totalPmxReward) /
            buckets[_bucketName].totalPoints;
        reward = reward.wmul(_multiplicator);

        delete buckets[_bucketName].lendersInfo[_user];
        buckets[_bucketName].withdrawnRewards += reward;

        reward += extraRewards[_user][_bucketName];
        delete extraRewards[_user][_bucketName];
    }

    /**
     * @notice Claims the specified reward amount for a user from a specific bucket.
     * @param _reward The amount of reward to be claimed.
     * @param _user The address of the user.
     * @param _bucket The address of the bucket.
     */
    function _claimReward(uint256 _reward, address _user, address _bucket) internal whenNotPaused {
        // transfer rewards on the balance in traderBalanceVault
        pmx.transfer(address(traderBalanceVault), _reward);
        traderBalanceVault.topUpAvailableBalance(_user, address(pmx), _reward);
        emit ClaimedReward(_user, _bucket, _reward);
    }

    /**
     * @notice Calculates the mining points based on params provided.
     * @param _depositedAmount The amount of tokens deposited by the user.
     * @param _stabilizationEndTimestamp The timestamp when stabilization period ends.
     * @param _maxDuration The maximum duration.
     * @param _currentTimestamp The current timestamp.
     * @return The calculated mining points.
     */
    function _calculatePoints(
        uint256 _depositedAmount,
        uint256 _stabilizationEndTimestamp,
        uint256 _maxDuration,
        uint256 _currentTimestamp
    ) private pure returns (uint256) {
        return (_depositedAmount * (_stabilizationEndTimestamp - _currentTimestamp)).wdiv(_maxDuration);
    }
}
