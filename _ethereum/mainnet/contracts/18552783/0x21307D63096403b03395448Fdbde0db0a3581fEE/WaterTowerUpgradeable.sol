// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./WaterTowerStorage.sol";
import "./EIP2535Initializable.sol";
import "./IrrigationAccessControl.sol";
import "./ICurveSwapRouter.sol";
import "./ICurveMetaPool.sol";
import "./Constants.sol";
import "./ISprinklerUpgradeable.sol";
import "./IPriceOracleUpgradeable.sol";
import "./IWaterTowerUpgradeable.sol";
import "./IWell.sol";
import "./IWETH.sol";

/// @title  WaterTower Contract
/// @notice Allows users deposit Water token and receive ETH reward
/// @dev    Admin should setup pool with monthly reward, at the end of each month.
///         Once admin set total monthly reward, users can receive ETH reward for last month
///         by the percentage of deposited water amount.
///         Note that users should run any more than one transaction in the month to receive
///         ETH reward.

contract WaterTowerUpgradeable is
    EIP2535Initializable,
    IrrigationAccessControl,
    ReentrancyGuardUpgradeable,
    IWaterTowerUpgradeable,
    PausableUpgradeable
{
    using WaterTowerStorage for WaterTowerStorage.Layout;

    error NotAutoIrrigate();
    error InsufficientBalance();
    error InsufficientReward();
    error InvalidRewardPool();
    /// @dev admin errors
    error InvalidTime();
    error InsufficientEther();
    error LockedWater();

    uint256 internal constant IRRIGATE_BONUS_DOMINATOR = 100;
    uint256 internal constant AUTOIRRIGATE_GASLIMIT = 602000;
    uint256 internal constant POOL_PERIOD = 30 days;

    /// @notice deposit water token
    function deposit(uint256 amount, bool bAutoIrrigate) external whenNotPaused {
        IERC20Upgradeable(address(this)).transferFrom(msg.sender, address(this), amount);
        setAutoIrrigate(bAutoIrrigate);
        _deposit(msg.sender, amount);
    }

    // withdraw water token
    function withdraw(uint256 amount) external nonReentrant whenNotPaused {
        _withdraw(msg.sender, amount);
        IERC20Upgradeable(address(this)).transfer(msg.sender, amount);
    }

    /// @notice claim ETH rewards
    function claim(uint256 amount) external nonReentrant whenNotPaused {
        uint256 claimAmount = _claimReward(msg.sender, amount);
        (bool success, ) = msg.sender.call{value: claimAmount}("");
        if (!success) revert InsufficientBalance();
    }

    /// @notice irrigate user reward
    /// @param amount user's ether reward
    /// @param minSwapAmount minimum middle asset amount swapped by irrigate
    function irrigate(uint256 amount, uint256 minSwapAmount) external nonReentrant whenNotPaused {
        _irrigate(msg.sender, amount, minSwapAmount);
    }

    /// @notice irrigate user reward per a month by admin
    /// @param user user address
    /// @param rewardAmount reward amount
    /// @param minSwapAmount minimum middle asset amount swapped by irrigate
    /// @dev rewardAmount should be smaller than user reward - gas fee
    function autoIrrigate(
        address user,
        uint256 rewardAmount,
        uint256 minSwapAmount
    ) external onlyAutoIrrigateAdminRole {
        /// @dev gas fee is paid based on precalculated gasLimit(870200)
        uint256 gasFee = AUTOIRRIGATE_GASLIMIT * tx.gasprice;
        _autoIrrigate(user, rewardAmount, minSwapAmount, gasFee);
        (bool success, ) = msg.sender.call{value: gasFee}("");
        if (!success) revert InsufficientBalance();
        emit AutoIrrigate(user, rewardAmount, gasFee);
    }

    function _autoIrrigate(
        address userAddress,
        uint256 rewardAmount,
        uint256 minSwapAmount,
        uint256 gasFee
    ) internal {
        UserInfo storage user = WaterTowerStorage.layout().users[userAddress];
        if (!user.isAutoIrrigate) revert NotAutoIrrigate();
        _irrigate(userAddress, rewardAmount, minSwapAmount);
        user.pending -= gasFee;
    }

    function batchAutoIrrigate(
        address[] calldata users,
        uint256[] calldata rewardAmounts,
        uint256[] calldata minSwapAmounts
    ) external onlyAutoIrrigateAdminRole {
        /// @dev gas fee is paid based on precalculated gasLimit(542000)
        uint256 gasFee = AUTOIRRIGATE_GASLIMIT * tx.gasprice;
        for (uint256 i; i < users.length; ) {
            _autoIrrigate(users[i], rewardAmounts[i], minSwapAmounts[i], gasFee);
            unchecked {
                ++i;
            }
        }
        (bool success, ) = msg.sender.call{value: gasFee * users.length}("");
        if (!success) revert InsufficientBalance();
    }

    function setAutoIrrigate(bool bAutoIrrigate) public {
        WaterTowerStorage.layout().users[msg.sender].isAutoIrrigate = bAutoIrrigate;
        emit SetAutoIrrigate(msg.sender, block.timestamp, bAutoIrrigate);
    }

    /// @dev internal

    /// @dev if user is not updated in current pool index, reward rate is calculated
    /// @param user user address
    /// @param poolInfo current pool info
    /// @param curPoolIndex curren pool index
    function _updateUserPool(
        address user,
        PoolInfo memory poolInfo,
        uint256 curPoolIndex
    ) internal {
        WaterTowerStorage.Layout storage l = WaterTowerStorage.layout();
        UserInfo storage _userInfo = l.users[user];
        if (_userInfo.lastPoolIndex != curPoolIndex) {
            PoolInfo memory lastPoolInfo = l.pools[_userInfo.lastPoolIndex];
            if (_userInfo.rewardRate != 0) {
                _userInfo.pending +=
                    (_userInfo.rewardRate * lastPoolInfo.monthlyRewards) /
                    lastPoolInfo.totalRewardRate;
            }
            /// if there is no deposit for user, reward rate start from 0
            _userInfo.lastPoolIndex = curPoolIndex;
            if (_userInfo.amount == 0) {
                _userInfo.rewardRate = 0;
                return;
            }
            /// @dev if user deposit in last month, reward rate is increased
            uint256 userRewardRate = _userInfo.amount * (poolInfo.endTime - poolInfo.startTime);
            _userInfo.rewardRate = userRewardRate;
            l.pools[curPoolIndex].totalRewardRate = poolInfo.totalRewardRate + userRewardRate;
        }
    }

    function _irrigate(address irrigator, uint256 irrigateAmount, uint256 minSwapAmount) internal {
        uint256 rewardAmount = _claimReward(irrigator, irrigateAmount);
        uint256 swappedWaterAmount = _swapEthForWater(rewardAmount, minSwapAmount);
        uint256 bonusAmount = (swappedWaterAmount * WaterTowerStorage.layout().irrigateBonusRate) /
            IRRIGATE_BONUS_DOMINATOR;
        uint256 totalDepositWaterAmount = swappedWaterAmount + bonusAmount;
        _deposit(irrigator, totalDepositWaterAmount);
        WaterTowerStorage.layout().totalBonus += bonusAmount;
        emit Irrigate(
            irrigator,
            WaterTowerStorage.layout().middleAssetForIrrigate,
            rewardAmount,
            totalDepositWaterAmount,
            bonusAmount
        );
    }

    /// @dev if amount is 0, claim with max claimable amount
    function _claimReward(address user, uint256 amount) internal returns (uint256) {
        uint256 curPoolIndex = WaterTowerStorage.layout().curPoolIndex;
        _updateUserPool(user, WaterTowerStorage.layout().pools[curPoolIndex], curPoolIndex);
        uint256 ethReward = WaterTowerStorage.userInfo(user).pending;
        if (ethReward < amount) revert InsufficientReward();
        if (amount == 0) amount = ethReward;
        unchecked {
            WaterTowerStorage.layout().users[user].pending = ethReward - amount;
        }
        emit Claimed(msg.sender, amount);
        return amount;
    }

    function _deposit(address user, uint amount) internal {
        WaterTowerStorage.Layout storage l = WaterTowerStorage.layout();
        uint256 curPoolIndex = l.curPoolIndex;
        PoolInfo memory poolInfo = l.pools[curPoolIndex];
        _updateUserPool(user, poolInfo, curPoolIndex);
        // if amount is 0, update only pool info
        if (amount == 0) return;
        l.users[user].amount += amount;
        uint256 rewardRate = amount * (poolInfo.endTime - block.timestamp);
        l.users[user].rewardRate += rewardRate;
        l.pools[curPoolIndex].totalRewardRate += rewardRate;
        l.totalDeposits += amount;
        emit Deposited(user, amount);
    }

    function _withdraw(address user, uint amount) internal {
        WaterTowerStorage.Layout storage l = WaterTowerStorage.layout();
        uint256 curPoolIndex = l.curPoolIndex;
        PoolInfo memory poolInfo = l.pools[curPoolIndex];
        _updateUserPool(user, poolInfo, curPoolIndex);
        // if amount is 0, update only pool info
        if (amount == 0) return;
        l.users[user].amount -= amount;
        // can't withdraw locked water amount
        if (l.users[user].amount < l.lockedUsers[user].lockedAmount) revert LockedWater();
        uint256 rewardRate = amount * (poolInfo.endTime - block.timestamp);
        l.users[user].rewardRate -= rewardRate;
        l.pools[curPoolIndex].totalRewardRate -= rewardRate;
        l.totalDeposits -= amount;
        emit Withdrawn(user, amount);
    }

    function _swapEthForWater(
        uint256 amount,
        uint256 minSwapAmount
    ) internal returns (uint256 waterAmount) {
        if (WaterTowerStorage.layout().middleAssetForIrrigate == Constants.BEAN) {
            /// @dev swap ETH for BEAN using bean-weth liquidity
            IWETH(Constants.WETH).deposit{value: amount}();
            IERC20Upgradeable(Constants.WETH).approve(Constants.BEAN_ETH_WELL, amount);
            uint256 beanAmount = IWell(Constants.BEAN_ETH_WELL).swapFrom(
                IERC20Upgradeable(Constants.WETH),
                IERC20Upgradeable(Constants.BEAN),
                amount,
                minSwapAmount,
                address(this),
                block.timestamp
            );

            waterAmount = ISprinklerUpgradeable(address(this)).getWaterAmount(
                Constants.BEAN,
                beanAmount
            );
        }
    }

    function getBonusForIrrigate(
        uint256 ethAmount
    ) external view returns (uint256 waterAmount, uint256 bonusAmount, uint256 swapAmount) {
        if (WaterTowerStorage.layout().middleAssetForIrrigate == Constants.BEAN) {
            /// @dev swap amount ETH->BEAN through well lp
            swapAmount = IWell(Constants.BEAN_ETH_WELL).getSwapOut(
                IERC20Upgradeable(Constants.WETH),
                IERC20Upgradeable(Constants.BEAN),
                ethAmount
            );

            /// @dev calculate swap water amount through Sprinkler
            waterAmount = ISprinklerUpgradeable(address(this)).getWaterAmount(
                Constants.BEAN,
                swapAmount
            );
            bonusAmount =
                (waterAmount * WaterTowerStorage.layout().irrigateBonusRate) /
                IRRIGATE_BONUS_DOMINATOR;
        } else return (0, 0, 0);
    }

    /// @notice add ether reward in watertower
    function addETHReward() external payable {
        if (msg.value == 0) revert InsufficientEther();
        WaterTowerStorage.layout().totalRewards += msg.value;
        emit AddETHReward(msg.value);
    }

    function updateMonthlyReward(uint256 monthlyRewards) internal onlyAdminRole {
        uint256 totalRewards = WaterTowerStorage.layout().totalRewards;
        if (monthlyRewards > totalRewards) revert InsufficientReward();
        unchecked {
            totalRewards -= monthlyRewards;
        }
        WaterTowerStorage.layout().totalRewards = totalRewards;
        WaterTowerStorage.curPool().monthlyRewards = monthlyRewards;
    }

    /// @dev admin setters
    function setMiddleAsset(address middleAsset) external onlyAdminRole {
        WaterTowerStorage.layout().middleAssetForIrrigate = middleAsset;
    }

    function setIrrigateBonusRate(uint256 bonusRate) external onlyAdminRole {
        WaterTowerStorage.layout().irrigateBonusRate = bonusRate;
    }

    function setPool(uint256 endTime, uint256 monthlyRewards) external payable onlyAdminRole {
        if ((endTime != 0 && endTime < block.timestamp)) revert InvalidTime();
        updateMonthlyReward(monthlyRewards);
        /// @dev default period is 30 days
        if (endTime == 0) endTime = block.timestamp + POOL_PERIOD;
        uint256 poolIndex = WaterTowerStorage.layout().curPoolIndex;
        ++poolIndex;
        WaterTowerStorage.layout().pools[poolIndex].endTime = uint128(endTime);
        WaterTowerStorage.layout().pools[poolIndex].startTime = uint128(block.timestamp);
        WaterTowerStorage.layout().curPoolIndex = poolIndex;
        emit UpdateRewardPeriod(poolIndex, endTime, monthlyRewards);
    }

    /// @dev getters for users

    /// @notice userInfo contains deposit amount by the user, irrigate setting, and so on
    function userInfo(address user) external view returns (UserInfo memory) {
        return WaterTowerStorage.userInfo(user);
    }

    function getLockedUserInfo(address user) external view returns (LockedUserInfo memory) {
        return WaterTowerStorage.layout().lockedUsers[user];
    }

    /// @notice view function to get pending eth reward for user
    function userETHReward(address user) external view returns (uint256 ethReward) {
        uint256 curPoolIndex = WaterTowerStorage.layout().curPoolIndex;
        if (curPoolIndex <= 1) return 0;
        UserInfo memory _userInfo = WaterTowerStorage.userInfo(user);
        PoolInfo memory lastPoolInfo = WaterTowerStorage.layout().pools[_userInfo.lastPoolIndex];
        ethReward = _userInfo.pending;
        if (_userInfo.lastPoolIndex != curPoolIndex) {
            if (_userInfo.rewardRate != 0) {
                ethReward +=
                    (_userInfo.rewardRate * lastPoolInfo.monthlyRewards) /
                    lastPoolInfo.totalRewardRate;
            }
        }
    }

    function totalDeposits() external view returns (uint256) {
        return WaterTowerStorage.layout().totalDeposits;
    }

    function getPoolIndex() external view returns (uint256) {
        return WaterTowerStorage.layout().curPoolIndex;
    }

    /// @notice return pool info for poolIndex. If poolIndex is greater than current pool index, return current pool
    function getPoolInfo(uint256 poolIndex) external view returns (PoolInfo memory) {
        WaterTowerStorage.Layout storage l = WaterTowerStorage.layout();
        if (poolIndex > l.curPoolIndex) poolIndex = l.curPoolIndex;
        return l.pools[poolIndex];
    }

    function getMiddleAsset() external view returns (address) {
        return WaterTowerStorage.layout().middleAssetForIrrigate;
    }

    function getTotalRewards() external view returns (uint256 totalRewards) {
        totalRewards = WaterTowerStorage.layout().totalRewards;
    }
}
