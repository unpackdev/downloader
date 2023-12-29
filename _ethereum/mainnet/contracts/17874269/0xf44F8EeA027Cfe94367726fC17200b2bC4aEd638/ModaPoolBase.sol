// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IPool.sol";
import "./ICorePool.sol";
import "./ModaConstants.sol";
import "./ModaPoolFactory.sol";

/**
 * @title Moda Pool Base
 * @notice An abstract contract containing common logic for any MODA pool,
 *      be it core pool (permanent pool like MODA/ETH or MODA core pool) or something else.
 * @dev Deployment and initialization.
 *      Any pool deployed must have 3 token instance addresses defined on deployment:
 *          - MODA token address
 *          - pool token address, it can be MODA token address, MODA/ETH pair address, and others
 */
abstract contract ModaPoolBase is Ownable, IPool, ModaAware, ReentrancyGuard {
	// @dev POOL_UID defined to add another check to ensure compliance with the contract.
	function POOL_UID() public pure returns (uint256) {
		return ModaConstants.POOL_UID;
	}

	// @dev modaPool MODA ERC20 Liquidity Pool contract address.
	// @dev This value is address(0) for the default MODA Core Pool.
	// @dev This value MUST be provided for any pool created which is not a MODA pool.
	// @dev This is used in the case where poolToken != moda.
	//      The use case relates to shadowing Liquidity Pool stakes
	//      by allowing people to store the LP tokens here to gain
	//      further MODA rewards. I'm not sure it's both. (dex 2021.09.16)
	address immutable modaPool;

	/// @dev Data structure representing token holder using a pool
	struct User {
		// @dev Total staked amount
		uint256 tokenAmount;
		// @dev Total weight
		uint256 totalWeight;
		// @dev An array of holder's deposits
		Deposit[] deposits;
		// @dev timestamp of when the user last processed rewards
		uint256 lastProcessedRewards;
	}

	/// @dev Token holder storage, maps token holder address to their data record
	mapping(address => User) public users;

	/// @dev Link to the pool token instance, for example MODA or MODA/ETH pair
	address public immutable override poolToken;

	/// @dev Link to the pool factory instance that manages weights
	ModaPoolFactory public immutable modaPoolFactory;

	/// @dev Pool weight, 200 for MODA pool or 800 for MODA/ETH
	uint32 public override weight;

	/// @dev Used to calculate yield rewards, keeps track of the tokens weight locked in staking
	uint256 public override usersLockingWeight;

	/// @dev Used to calculate yield rewards, keeps track of when the pool started
	uint256 public immutable override startTimestamp;

	/// @dev Reward locking period, added to block.timestamp when rewards are locked up in the pool
	///      Can be changed by the contract owner.
	uint public rewardLockingPeriod = 150 days;

	/**
	 * @dev Stake weight is proportional to deposit amount and time locked, precisely
	 *      "deposit amount wei multiplied by (fraction of the year locked plus one)"
	 * @dev To avoid significant precision loss due to multiplication by "fraction of the year" [0, 1],
	 *      weight is stored multiplied by 1e6 constant, as an integer
	 * @dev Corner case 1: if time locked is zero, weight is deposit amount multiplied by 1e6
	 * @dev Corner case 2: if time locked is one year, fraction of the year locked is one, and
	 *      weight is a deposit amount multiplied by 2 * 1e6
	 */
	uint256 internal constant WEIGHT_MULTIPLIER = 1e6;

	/**
	 * @dev When we know beforehand that staking is done for a year, and fraction of the year locked is one,
	 *      we use simplified calculation and use the following constant instead previous one
	 */
	uint256 internal constant YEAR_STAKE_WEIGHT_MULTIPLIER = 2 * WEIGHT_MULTIPLIER;

	/**
	 * @dev Fired in _stake() and stake()
	 *
	 * @param _by an address which performed an operation, usually token holder
	 * @param _from token holder address, the tokens will be returned to that address
	 * @param amount amount of tokens staked
	 */
	event Staked(address indexed _by, address indexed _from, uint256 amount);

	/**
	 * @dev Fired in _updateStakeLock() and updateStakeLock()
	 *
	 * @param _by an address which performed an operation
	 * @param depositId updated deposit ID
	 * @param lockedFrom deposit locked from value
	 * @param lockedUntil updated deposit locked until value
	 */
	event StakeLockUpdated(address indexed _by, uint256 depositId, uint256 lockedFrom, uint256 lockedUntil);

	/**
	 * @dev Fired in _unstake() and unstake()
	 *
	 * @param _by an address which performed an operation, usually token holder
	 * @param _to an address which received the unstaked tokens, usually token holder
	 * @param amount amount of tokens unstaked
	 */
	event Unstaked(address indexed _by, address indexed _to, uint256 amount);

	/**
	 * @dev Fired in _processRewards(), processRewards() and dependent functions (stake, unstake, etc.)
	 *
	 * @param _by an address which performed an operation
	 * @param _to an address which claimed the yield reward
	 * @param amount amount of yield paid
	 */
	event YieldClaimed(address indexed _by, address indexed _to, uint256 amount);

	/**
	 * @dev Fired in setWeight()
	 *
	 * @param _by an address which performed an operation, always a factory
	 * @param _fromVal old pool weight value
	 * @param _toVal new pool weight value
	 */
	event PoolWeightUpdated(address indexed _by, uint32 _fromVal, uint32 _toVal);

	/**
	 * @dev Fired whenever the owner sets the reward locking period. Existing stakes
	 *      are not affected by this change, as it's queried and added on lock up.
	 *
	 * @param _from the previous reward locking period in seconds
	 * @param _to the new reward locking period in seconds
	 */
	event RewardLockingPeriodUpdated(uint _from, uint _to);

	/**
	 * @dev Overridden in sub-contracts to construct the pool
	 *
	 * @param _moda MODA ERC20 Token ModaERC20 address
	 * @param _modaPoolFactory MODA Pool Factory Address
	 * @param _modaPool MODA ERC20 Liquidity Pool contract address
	 * @param _poolToken token the pool operates on, for example MODA or MODA/ETH pair
	 * @param _weight number representing a weight of the pool, actual weight fraction
	 *      is calculated as that number divided by the total pools weight and doesn't exceed one
	 * @param _startTimestamp timestamp that pool should start from
	 */
	constructor(
		address _moda,
		address _modaPoolFactory,
		address _modaPool,
		address _poolToken,
		uint32 _weight,
		uint256 _startTimestamp
	) ModaAware(_moda) {
		require(_poolToken != address(0), 'pool token address not set');
		require(_modaPoolFactory != address(0), 'pool factory address not set');
		require(_weight > 0, 'pool weight not set');
		require(_startTimestamp >= block.timestamp, 'start already passed');
		require(
			_startTimestamp < ModaPoolFactory(_modaPoolFactory).endTimestamp(),
			'start too late compared to factory'
		);
		require(
			((_poolToken == _moda ? 1 : 0) ^ (_modaPool != address(0) ? 1 : 0)) == 1,
			'Either a MODA pool or manage external tokens, never both'
		);

		require(Token(_moda).TOKEN_UID() == ModaConstants.TOKEN_UID, 'Moda TOKEN_UID invalid');
		require(
			ModaPoolFactory(_modaPoolFactory).FACTORY_UID() == ModaConstants.FACTORY_UID,
			'Moda FACTORY_UID invalid'
		);
		if (_modaPool != address(0)) {
			require(ModaPoolBase(_modaPool).POOL_UID() == ModaConstants.POOL_UID, 'Moda POOL_UID invalid');
		}

		modaPool = _modaPool;
		modaPoolFactory = ModaPoolFactory(_modaPoolFactory);
		poolToken = _poolToken;
		weight = _weight;
		startTimestamp = _startTimestamp;
	}

	/**
	 * @notice Calculates current yield rewards value available for address specified
	 * @param _staker an address to calculate yield rewards value for
	 * @return calculated yield reward value for the given address
	 */
	function pendingYieldRewards(address _staker) public view override returns (uint256) {
		if (block.timestamp < startTimestamp) return 0;
		if (usersLockingWeight == 0) return 0;

		uint256 factoryEnd = modaPoolFactory.endTimestamp();
		uint256 endOfTimeframe = block.timestamp > factoryEnd ? factoryEnd : block.timestamp;

		User memory user = users[_staker];
		if (user.lastProcessedRewards > endOfTimeframe) return 0;

		uint256 depositCount = user.deposits.length;
		if (depositCount < 1) return 0;

		Deposit memory stakeDeposit = user.deposits[depositCount - 1];
		uint256 lastRewards = user.lastProcessedRewards > 0 ? user.lastProcessedRewards : stakeDeposit.lockedFrom;

		uint256 timeElapsedSinceLastReward = endOfTimeframe < startTimestamp
			? endOfTimeframe - startTimestamp
			: endOfTimeframe - lastRewards;

		uint256 modaPerSecond = modaPoolFactory.modaPerSecondAt(endOfTimeframe);
		uint256 allPoolsTotalSinceLastReward = modaPerSecond * timeElapsedSinceLastReward;
		uint256 poolRewards = (allPoolsTotalSinceLastReward * weight) / modaPoolFactory.totalWeight();

		return (poolRewards * user.totalWeight) / usersLockingWeight;
	}

	/**
	 * @notice Returns total staked token balance for the given address
	 *
	 * @param _user an address to query balance for
	 * @return total staked token balance
	 */
	function balanceOf(address _user) external view override returns (uint256) {
		return users[_user].tokenAmount;
	}

	/**
	 * @notice Returns information on the given deposit for the given address
	 * @dev See getDepositsLength
	 * @param _user an address to query deposit for
	 * @param _depositId zero-indexed deposit ID for the address specified
	 * @return deposit info as Deposit structure
	 */
	function getDeposit(address _user, uint256 _depositId) external view override returns (Deposit memory) {
		return users[_user].deposits[_depositId];
	}

	/**
	 * @notice Returns number of deposits for the given address. Allows iteration over deposits.
	 * @dev See getDeposit
	 * @param _user an address to query deposit length for
	 * @return number of deposits for the given address
	 */
	function getDepositsLength(address _user) external view override returns (uint256) {
		return users[_user].deposits.length;
	}

	/**
	 * @notice Stakes specified amount of tokens for the specified amount of time,
	 *      and pays pending yield rewards if any
	 * @dev Requires amount to stake to be greater than zero
	 * @param _amount amount of tokens to stake
	 * @param _lockUntil stake period as unix timestamp; zero means no locking
	 */
	function stake(uint256 _amount, uint256 _lockUntil) external override {
		_stake(msg.sender, _amount, _lockUntil, false);
	}

	/**
	 * @notice Un-stakes specified amount of tokens, and pays pending yield rewards if any
	 * @dev Requires amount to unstake to be greater than zero
	 * @param _depositId deposit ID to unstake from, zero-indexed
	 * @param _amount amount of tokens to unstake
	 */
	function unstake(uint256 _depositId, uint256 _amount) external override {
		_unstake(msg.sender, _depositId, _amount);
	}

	/**
	 * @notice Extends locking period for a given deposit
	 * @dev Requires new lockedUntil value to be:
	 *      higher than the current one, and
	 *      in the future, but
	 *      no more than 1 year in the future
	 * @param depositId updated deposit ID
	 * @param lockedUntil updated deposit locked until value
	 */
	function updateStakeLock(uint256 depositId, uint256 lockedUntil) external {
		_processRewards(msg.sender);
		_updateStakeLock(msg.sender, depositId, lockedUntil);
	}

	/**
	 * @notice Service function to calculate and pay pending yield rewards to the sender
	 * @dev Can be executed by anyone at any time, but has an effect only when
	 *      executed by deposit holder and when at least one block passes from the
	 *      previous reward processing
	 * @dev When timing conditions are not met (executed too frequently, or after
	 *      end block), function doesn't throw and exits silently
	 */
	function processRewards() external virtual override {
		_processRewards(msg.sender);
	}

	/**
	 * @dev Executed by the factory to modify pool weight; the factory is expected
	 *      to keep track of the total pools weight when updating
	 * @dev Set weight to zero to disable the pool
	 * @param _weight new weight to set for the pool
	 */
	function setWeight(uint32 _weight) external override {
		require(msg.sender == address(modaPoolFactory), 'Access denied: factory only');

		uint32 oldWeight = weight;
		weight = _weight;

		emit PoolWeightUpdated(msg.sender, oldWeight, weight);
	}

	/**
	 * @dev Used internally, mostly by children implementations, see stake()
	 * @param _staker an address which stakes tokens and which will receive them back
	 * @param _amount amount of tokens to stake
	 * @param _lockUntil stake period as unix timestamp; zero means no locking
	 * @param _isYield a flag indicating if that stake is created to store yield reward
	 *      from the previously unstaked stake
	 */
	function _stake(address _staker, uint256 _amount, uint256 _lockUntil, bool _isYield) internal virtual {
		require(_amount > 0, 'zero amount');
		require(block.timestamp >= startTimestamp, 'pool not active');
		require(
			_lockUntil == 0 || (_lockUntil > block.timestamp && _lockUntil - block.timestamp <= 365 days),
			'invalid lock interval'
		);

		User storage user = users[_staker];
		if (user.tokenAmount > 0) {
			_processRewards(_staker);
		}

		uint256 previousBalance = IERC20(poolToken).balanceOf(address(this));
		transferPoolTokenFrom(address(msg.sender), address(this), _amount);
		// Note: some tokens may get burnt here if the token contract
		// withholds fees on transfers. We must re-fetch the balance. Usually
		// this is just the difference: `previousBalance - _amount`
		uint256 newBalance = IERC20(poolToken).balanceOf(address(this));
		// calculate real amount taking into account deflation
		uint256 addedAmount = newBalance - previousBalance;

		// set the `lockFrom` and `lockUntil` taking into account that
		// zero value for `_lockUntil` means "no locking" and leads to zero values
		// for both `lockFrom` and `lockUntil`
		uint256 lockFrom = block.timestamp;
		uint256 lockUntil = _lockUntil;

		// Stake weight rewards formula for locking
		uint256 stakeWeight = lockUntil == 0
			? WEIGHT_MULTIPLIER * addedAmount
			: ((WEIGHT_MULTIPLIER * (lockUntil - lockFrom)) / 365 days + WEIGHT_MULTIPLIER) * addedAmount;

		require(stakeWeight > 0, 'Stake weight is zero');

		Deposit memory deposit = Deposit({
			tokenAmount: addedAmount,
			weight: stakeWeight,
			lockedFrom: lockFrom,
			lockedUntil: lockUntil,
			isYield: _isYield
		});
		user.deposits.push(deposit);

		user.tokenAmount += addedAmount;
		user.totalWeight += stakeWeight;

		usersLockingWeight += stakeWeight;

		emit Staked(msg.sender, _staker, _amount);
	}

	/**
	 * @dev Used internally, mostly by children implementations, see unstake()
	 * @param _staker an address which un-stakes tokens (which previously staked them)
	 * @param _depositId deposit ID to unstake from, zero-indexed
	 * @param _amount amount of tokens to unstake
	 */
	function _unstake(address _staker, uint256 _depositId, uint256 _amount) internal virtual {
		require(_amount > 0, 'zero amount');

		User storage user = users[_staker];
		Deposit storage stakeDeposit = user.deposits[_depositId];
		bool isYield = stakeDeposit.isYield;

		require(stakeDeposit.tokenAmount >= _amount, 'amount exceeds stake');

		_processRewards(_staker);

		uint256 previousWeight = stakeDeposit.weight;
		uint256 newWeight = stakeDeposit.lockedUntil == 0
			? WEIGHT_MULTIPLIER * (stakeDeposit.tokenAmount - _amount)
			: ((stakeDeposit.lockedUntil - stakeDeposit.lockedFrom) / 365 days + 1) *
				(WEIGHT_MULTIPLIER * (stakeDeposit.tokenAmount - _amount));

		if (stakeDeposit.tokenAmount - _amount == 0) {
			delete user.deposits[_depositId];
		} else {
			stakeDeposit.tokenAmount -= _amount;
			stakeDeposit.weight = newWeight;
		}

		user.tokenAmount -= _amount;
		user.totalWeight = user.totalWeight - previousWeight + newWeight;

		usersLockingWeight = usersLockingWeight - previousWeight + newWeight;

		if (isYield) {
			modaPoolFactory.mintYieldTo(msg.sender, _amount);
		} else {
			transferPoolToken(msg.sender, _amount);
		}

		emit Unstaked(msg.sender, _staker, _amount);
	}

	/**
	 * @dev Used internally, mostly by children implementations, see processRewards()
	 * @param _staker an address which receives the reward (which has staked some tokens earlier)
	 * @return pendingYield the rewards calculated and optionally re-staked
	 */
	function _processRewards(address _staker) internal virtual returns (uint256 pendingYield) {
		pendingYield = pendingYieldRewards(_staker);
		if (pendingYield == 0) return 0;

		User storage user = users[_staker];
		user.lastProcessedRewards = block.timestamp;

		if (poolToken == moda) {
			uint256 depositWeight = pendingYield * YEAR_STAKE_WEIGHT_MULTIPLIER;

			Deposit memory newDeposit = Deposit({
				tokenAmount: pendingYield,
				lockedFrom: block.timestamp,
				lockedUntil: block.timestamp + rewardLockingPeriod,
				weight: depositWeight,
				isYield: true
			});
			user.deposits.push(newDeposit);

			user.tokenAmount += pendingYield;
			user.totalWeight += depositWeight;

			usersLockingWeight += depositWeight;
		} else {
			require(modaPool != address(0), 'modaPool address is zero');

			ICorePool(modaPool).stakeAsPool(_staker, pendingYield);
		}

		emit YieldClaimed(msg.sender, _staker, pendingYield);
	}

	/**
	 * @dev See updateStakeLock()
	 * @param _staker an address to update stake lock
	 * @param _depositId updated deposit ID
	 * @param _lockedUntil updated deposit locked until value
	 */
	function _updateStakeLock(address _staker, uint256 _depositId, uint256 _lockedUntil) internal {
		require(_lockedUntil > block.timestamp, 'lock should be in the future');

		User storage user = users[_staker];
		Deposit storage stakeDeposit = user.deposits[_depositId];
		require(_lockedUntil > stakeDeposit.lockedUntil, 'invalid new lock');

		if (stakeDeposit.lockedFrom == 0) {
			require(_lockedUntil - block.timestamp <= 365 days, 'max lock period is 365 days');
			stakeDeposit.lockedFrom = block.timestamp;
		} else {
			require(_lockedUntil - stakeDeposit.lockedFrom <= 365 days, 'max lock period is 365 days');
		}

		stakeDeposit.lockedUntil = _lockedUntil;
		uint256 newWeight = (((stakeDeposit.lockedUntil - stakeDeposit.lockedFrom) * WEIGHT_MULTIPLIER) /
			365 days +
			WEIGHT_MULTIPLIER) * stakeDeposit.tokenAmount;

		uint256 previousWeight = stakeDeposit.weight;
		stakeDeposit.weight = newWeight;

		user.totalWeight = user.totalWeight - previousWeight + newWeight;
		usersLockingWeight = usersLockingWeight - previousWeight + newWeight;

		emit StakeLockUpdated(_staker, _depositId, stakeDeposit.lockedFrom, _lockedUntil);
	}

	/**
	 * @dev Executes SafeERC20.safeTransfer on a pool token
	 * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
	 */
	function transferPoolToken(address _to, uint256 _value) internal nonReentrant {
		SafeERC20.safeTransfer(IERC20(poolToken), _to, _value);
	}

	/**
	 * @dev Executes SafeERC20.safeTransferFrom on a pool token
	 * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
	 */
	function transferPoolTokenFrom(address _from, address _to, uint256 _value) internal nonReentrant {
		SafeERC20.safeTransferFrom(IERC20(poolToken), _from, _to, _value);
	}

	/**
	 * @dev Allows the owner to update the reward locking period
	 */
	function setRewardLockingPeriod(uint newRewardLockingPeriod) external override onlyOwner {
		uint oldRewardLockingPeriod = rewardLockingPeriod;
		rewardLockingPeriod = newRewardLockingPeriod;

		emit RewardLockingPeriodUpdated(oldRewardLockingPeriod, rewardLockingPeriod);
	}

	/**
	 * @dev Here because of multiple inheritance, we have to override.
	 */
	function transferOwnership(address newOwner) public virtual override(IPool, Ownable) onlyOwner {
		require(newOwner != address(0), 'Ownable: new owner is the zero address');
		_transferOwnership(newOwner);
	}
}
