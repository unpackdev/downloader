// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./ModaConstants.sol";
import "./ModaPoolBase.sol";

/**
 * @title Moda Core Pool
 *
 * @notice Core pools represent permanent pools like MODA or MODA/ETH Pair pool,
 *      core pools allow staking for arbitrary periods of time up to 1 year
 *
 * @dev See ModaPoolBase for more details
 */
contract ModaCorePool is ModaPoolBase {
	/// @dev Pool tokens value available in the pool;
	///      pool token examples are MODA (MODA core pool) or MODA/ETH pair (LP core pool)
	/// @dev For LP core pool this value doesn't count for MODA tokens received as Vault rewards
	///      while for MODA core pool it does count for such tokens as well
	uint256 public poolTokenReserve;

	/**
	 * @dev Creates/deploys an instance of the core pool
	 *
	 * @param _moda MODA ERC20 Token ModaERC20 address
	 * @param _modaPoolFactory MODA Pool Factory Address
	 * @param _modaPool MODA Pool Address or address(0) if this is the Moda pool.
	 * @param _poolToken The token this pool uses.
	 * @param _weight number representing a weight of the pool, actual weight fraction
	 *      is calculated as that number divided by the total pools weight and doesn't exceed one
	 * @param _startTimestamp The start time for this pool as an EVM timestamp (seconds since epoch)
	 */
	constructor(
		address _moda,
		address _modaPoolFactory,
		address _modaPool,
		address _poolToken,
		uint32 _weight,
		uint256 _startTimestamp
	)
		ModaPoolBase(
			_moda,
			_modaPoolFactory,
			_modaPool,
			_poolToken,
			_weight,
			_startTimestamp
		)
	{
		poolTokenReserve = 0;
	}

	/**
	 * @notice Service function to calculate and pay pending vault and yield rewards to the sender
	 *
	 * @dev Internally executes similar function `_processRewards` from the parent smart contract
	 *      to calculate and pay yield rewards; adds vault rewards processing
	 *
	 * @dev Can be executed by anyone at any time, but has an effect only when
	 *      executed by deposit holder and when at least one block passes from the
	 *      previous reward processing
	 * @dev Executed internally when "staking as a pool" (`stakeAsPool`)
	 * @dev When timing conditions are not met (executed too frequently, or after
	 *      end block), function doesn't throw and exits silently
	 */
	function processRewards() external override {
		_processRewards(msg.sender);
	}

	/**
	 * @dev Executed by another pool (from the parent `ModaPoolBase` smart contract)
	 *      as part of yield rewards processing logic (`ModaPoolBase._processRewards` function)
	 * @dev Executed when pool is not an Moda pool - see `ModaPoolBase._processRewards`
	 *
	 * @param _staker an address which stakes (the yield reward)
	 * @param _amount amount to be staked (yield reward amount)
	 */
	function stakeAsPool(address _staker, uint256 _amount)
		external
	{
		require(modaPoolFactory.poolExists(msg.sender), 'pool is not registered');

		User storage user = users[_staker];
		if (user.tokenAmount > 0) {
			_processRewards(_staker);
		}

		uint256 depositWeight = _amount * YEAR_STAKE_WEIGHT_MULTIPLIER;
		Deposit memory newDeposit = Deposit({
			tokenAmount: _amount,
			lockedFrom: block.timestamp,
			lockedUntil: block.timestamp + rewardLockingPeriod,
			weight: depositWeight,
			isYield: true
		});
		user.tokenAmount += _amount;
		user.totalWeight += depositWeight;
		user.deposits.push(newDeposit);

		usersLockingWeight += depositWeight;

		// update `poolTokenReserve` only if this is a LP Core Pool (stakeAsPool can be executed only for LP pool)
		poolTokenReserve += _amount;

		// Tell the world we've done this
		emit Staked(_staker, _staker, _amount);
	}

	/**
	 * @inheritdoc ModaPoolBase
	 *
	 * @dev Additionally to the parent smart contract,
	 *      and updates (increases) pool token reserve (pool tokens value available in the pool)
	 */
	function _stake(
		address _staker,
		uint256 _amount,
		uint256 _lockUntil,
		bool _isYield
	) internal override {
		super._stake(_staker, _amount, _lockUntil, _isYield);
		poolTokenReserve += _amount;
	}

	/**
	 * @inheritdoc ModaPoolBase
	 *
	 * @dev Additionally to the parent smart contract,
	 *      and updates (decreases) pool token reserve
	 *      (pool tokens value available in the pool)
	 */
	function _unstake(
		address _staker,
		uint256 _depositId,
		uint256 _amount
	) internal override {
		User storage user = users[_staker];
		Deposit memory stakeDeposit = user.deposits[_depositId];
		require(
			block.timestamp > stakeDeposit.lockedUntil,
			'deposit not yet unlocked'
		);
		poolTokenReserve -= _amount;
		super._unstake(_staker, _depositId, _amount);
	}

	/**
	 * @inheritdoc ModaPoolBase
	 *
	 * @dev Additionally to the parent smart contract,
	 *      and for MODA pool updates (increases) pool token reserve
	 *      (pool tokens value available in the pool)
	 */
	function _processRewards(address _staker) internal override returns (uint256 rewards) {
		rewards = super._processRewards(_staker);

		// update `poolTokenReserve` only if this is a MODA Core Pool
		if (poolToken == moda) {
			poolTokenReserve += rewards;
		}
	}
}
