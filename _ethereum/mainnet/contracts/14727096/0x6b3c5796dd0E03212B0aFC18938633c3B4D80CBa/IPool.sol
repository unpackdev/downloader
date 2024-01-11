// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
* @dev Data structure representing token holder using a pool
*/
struct User {
    // @dev Total staked amount
    uint256 tokenAmount;
    // @dev Total reward amount
    uint256 rewardAmount;
    // @dev Total weight
    uint256 totalWeight;
    // @dev Auxiliary variable for yield calculation
    uint256 subYieldRewards;
    // @dev An array of holder's deposits
    Deposit[] deposits;
}

/**
* @dev Deposit is a key data structure used in staking,
*      it represents a unit of stake with its amount, weight and term (time interval)
*/
struct Deposit {
    // @dev token amount staked
    uint256 tokenAmount;
    // @dev stake weight
    uint256 weight;
    // @dev locking period - from
    uint64 lockedFrom;
    // @dev locking period - until
    uint64 lockedUntil;
    // @dev indicates if the stake was created as a yield reward
    bool isYield;
}

/**
 * @title Cart Pool
 *
 * @notice An abstraction representing a pool, see CARTPoolBase for details
 *
 */
interface IPool {
    
    // for the rest of the functions see Soldoc in CARTPoolBase
    function CART() external view returns (address);

    function poolToken() external view returns (address);

    function isFlashPool() external view returns (bool);

    function weight() external view returns (uint256);

    function lastYieldDistribution() external view returns (uint256);

    function yieldRewardsPerWeight() external view returns (uint256);

    function usersLockingWeight() external view returns (uint256);

    function weightMultiplier() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function getDepositsLength(address _user) external view returns (uint256);

    function getOriginDeposit(address _user, uint256 _depositId) external view returns (Deposit memory);

    function getUser(address _user) external view returns (User memory);

    function stake(
        uint256 _amount,
        uint64 _lockedUntil,
        address _nftAddress,
        uint256 _nftTokenId
    ) external;

    function unstake(
        uint256 _depositId,
        uint256 _amount
    ) external;

    function sync() external;

    function processRewards() external;

    function setWeight(uint256 _weight) external;

    function NFTWeightUpdated(address _nftAddress, uint256 _nftWeight) external;

    function setWeightMultiplierbyFactory(uint256 _newWeightMultiplier) external;

    function getNFTWeight(address _nftAddress) external view returns (uint256);

    function weightToReward(uint256 _weight, uint256 rewardPerWeight) external pure returns (uint256);

    function rewardToWeight(uint256 reward, uint256 rewardPerWeight) external pure returns (uint256);

}