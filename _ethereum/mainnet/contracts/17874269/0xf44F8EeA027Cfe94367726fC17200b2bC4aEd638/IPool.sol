// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "./ILinkedToMODA.sol";

/**
 * @title Moda Pool
 *
 * @notice An abstraction representing a pool, see ModaPoolBase for details
 *
 * @author Pedro Bergamini, reviewed by Basil Gorin
 */
interface IPool is ILinkedToMODA {
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
		uint256 lockedFrom;
		// @dev locking period - until
		uint256 lockedUntil;
		// @dev indicates if the stake was created as a yield reward
		bool isYield;
	}

	// for the rest of the functions see Soldoc in ModaPoolBase

	function poolToken() external view returns (address);

	function weight() external view returns (uint32);

	function usersLockingWeight() external view returns (uint256);

	function startTimestamp() external view returns (uint256);

	function pendingYieldRewards(address _user) external view returns (uint256);

	function balanceOf(address _user) external view returns (uint256);

	function getDeposit(address _user, uint256 _depositId) external view returns (Deposit memory);

	function getDepositsLength(address _user) external view returns (uint256);

	function stake(
		uint256 _amount,
		uint256 _lockedUntil
	) external;

	function unstake(
		uint256 _depositId,
		uint256 _amount
	) external;

	function processRewards() external;

	function setWeight(uint32 _weight) external;

	function setRewardLockingPeriod(uint newRewardLockingPeriod) external;

	function transferOwnership(address newOwner) external;
}
