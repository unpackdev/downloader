// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";

import "./IesToken.sol";
import "./IStaking.sol";

contract Boost is OwnableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // Define a struct for the lock settings
    struct esTokenLockSetting {
        uint256 duration;
        uint256 miningBoost;
    }

    // Define a struct for the user's lock status
    struct LockStatus {
        uint256 lockAmount;
        uint256 unlockTime;
        uint256 duration;
        uint256 miningBoost;
    }

    uint256 public constant MAX_TOTAL_LOCK_FLOOR = 10000 ether;
    uint256 public totalLockFloor;
    uint256 public totalLockAmount;

    esTokenLockSetting[] public esTokenLockSettings;
    mapping(address => LockStatus) public userLockStatus;
    IesToken public esToken;
    IesToken public token;

    uint256 public constant MAX_STAKING_POOLS = 10;
    EnumerableSetUpgradeable.AddressSet private stakingPools;

    /********************************************/
    /****************** EVENTS ******************/
    /********************************************/

    event StakingPoolAdded(address indexed poolAddress);
    event StakingPoolRemoved(address indexed poolAddress);

    function initialize() public initializer {
        __Ownable_init();

        esTokenLockSettings.push(esTokenLockSetting(30 days, 5 * 1e18));
        esTokenLockSettings.push(esTokenLockSetting(90 days, 10 * 1e18));
        esTokenLockSettings.push(esTokenLockSetting(180 days, 25 * 1e18));
        esTokenLockSettings.push(esTokenLockSetting(365 days, 50 * 1e18));
    }

    /*******************************************/
    /****************** VIEWS ******************/
    /*******************************************/

    // Function to get the user's unlock time
    function getUnlockTime(address user) external view returns (uint256 unlockTime) {
        unlockTime = userLockStatus[user].unlockTime;
    }

    /**
     * @notice calculate the user's mining boost based on their lock status
     * @dev Based on the user's userUpdatedAt time, finishAt time, and the current time,
     * there are several scenarios that could occur, including no acceleration, full acceleration, and partial acceleration.
     */
    function getUserBoost(address user, uint256 userUpdatedAt, uint256 finishAt) external view returns (uint256) {
        LockStatus memory userStatus = userLockStatus[user];
        uint256 boostEndTime = userStatus.unlockTime;

        if (userUpdatedAt >= boostEndTime || userUpdatedAt >= finishAt || userStatus.lockAmount == 0) {
            return 0;
        }

        uint256 maxBoost = userLockStatus[user].miningBoost;

        if (finishAt > boostEndTime && block.timestamp > boostEndTime) {
            uint256 time = block.timestamp > finishAt ? finishAt : block.timestamp;
            maxBoost = ((boostEndTime - userUpdatedAt) * maxBoost) / (time - userUpdatedAt);
        }

        if (totalLockAmount < totalLockFloor) {
            return (totalLockAmount * maxBoost) / totalLockFloor;
        }

        return maxBoost;
    }

    function getLockSettingsLength() external view returns (uint256) {
        return esTokenLockSettings.length;
    }

    function getAmountNeedLocked(
        address user,
        uint256 userStakedAmount,
        uint256 totalStakedAmount
    ) external view returns (uint256) {
        LockStatus memory userStatus = userLockStatus[user];

        if (totalStakedAmount == 0 || totalLockAmount == 0 || (totalStakedAmount == userStakedAmount)) return 0;

        return (userStakedAmount * (totalLockAmount - userStatus.lockAmount)) / (totalStakedAmount - userStakedAmount);
    }

    /**
     * @dev Returns the number of staking pools
     */
    function stakingPoolsLength() external view returns (uint256) {
        return stakingPools.length();
    }

    /**
     * @dev Returns staking pool address from given index
     */
    function stakingPool(uint256 index) external view returns (address) {
        // BT_INE: index does not exists
        require(index < stakingPools.length(), "BT_INE");

        return address(stakingPools.at(index));
    }

    /**
     * @dev Returns true if given address is a staking pool address
     */
    function isStakingPool(address pool) external view returns (bool) {
        return stakingPools.contains(pool);
    }

    /****************************************************************/
    /****************** EXTERNAL PUBLIC FUNCTIONS  ******************/
    /****************************************************************/

    // Function to set the user's lock status
    function setLockStatus(uint256 id, uint256 tokenAmount, bool useToken) external {
        // BT_ISID: invalid setting id
        require(id < esTokenLockSettings.length, "BT_ISID");

        _refreshRewards(msg.sender);

        esTokenLockSetting memory _setting = esTokenLockSettings[id];
        LockStatus memory userStatus = userLockStatus[msg.sender];
        if (userStatus.unlockTime > block.timestamp) {
            // BT_DCNR: the duration can not reduced
            require(userStatus.duration <= _setting.duration, "BT_DCNR");
        }
        if (useToken) {
            IesToken(token).burn(msg.sender, tokenAmount);
            IesToken(esToken).mint(msg.sender, tokenAmount);
        }
        // BT_IB: insufficient balance
        require(IesToken(esToken).balanceOf(msg.sender) >= userStatus.lockAmount + tokenAmount, "BT_IB");

        totalLockAmount += tokenAmount;

        userLockStatus[msg.sender] = LockStatus(
            userStatus.lockAmount + tokenAmount,
            block.timestamp + _setting.duration,
            _setting.duration,
            _setting.miningBoost
        );
    }

    function unLock() external {
        LockStatus storage userStatus = userLockStatus[msg.sender];
        // BT_TNE: locktime not end
        require(userStatus.unlockTime < block.timestamp, "BT_TNE");

        _refreshRewards(msg.sender);

        totalLockAmount -= userStatus.lockAmount;

        userStatus.lockAmount = 0;
    }

    /****************************************************************/
    /*********************** OWNABLE FUNCTIONS  *********************/
    /****************************************************************/

    function setTotalLockFloor(uint256 _totalLockFloor) external onlyOwner {
        // BT_TLEM: totalLockFloor exceed maximum
        require(_totalLockFloor <= MAX_TOTAL_LOCK_FLOOR, "BT_TLEM");
        totalLockFloor = _totalLockFloor;
    }

    function setTokenAddress(address _esToken, address _token) external onlyOwner {
        esToken = IesToken(_esToken);
        token = IesToken(_token);
    }

    function addStakingPool(address _stakingPool) external onlyOwner {
        // BT_TMSP: too many staking pools
        require(stakingPools.length() < MAX_STAKING_POOLS, "BT_TMSP");
        // BT_SPAE: staking pool already exists
        require(!stakingPools.contains(_stakingPool), "BT_SPAE");

        stakingPools.add(_stakingPool);
        emit StakingPoolAdded(_stakingPool);
    }

    function removeStakingPool(address _stakingPool) external onlyOwner {
        // BT_SPNE: staking pool not exists
        require(stakingPools.contains(_stakingPool), "BT_SPNE");

        stakingPools.remove(_stakingPool);
        emit StakingPoolRemoved(_stakingPool);
    }

    // Function to add a new lock setting
    function addLockSetting(esTokenLockSetting memory setting) external onlyOwner {
        esTokenLockSettings.push(setting);
    }

    /********************************************************/
    /****************** INTERNAL FUNCTIONS ******************/
    /********************************************************/

    function _refreshRewards(address _account) internal {
        for (uint256 index = 0; index < stakingPools.length(); ++index) {
            IStaking(stakingPools.at(index)).refreshReward(_account);
        }
    }
}
