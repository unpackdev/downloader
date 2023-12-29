// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IPool.sol";
import "./ModaAware.sol";
import "./ModaCorePool.sol";
import "./Ownable.sol";
import "./ABDKMath64x64.sol";

/**
 * @title Moda Pool Factory
 *
 * @notice Moda Pool Factory manages Moda Yield farming pools, provides a single
 *      public interface to access the pools, provides an interface for the pools
 *      to mint yield rewards, access pool-related info, update weights, etc.
 *
 * @notice The factory is authorized (via its owner) to register new pools, change weights
 *      of the existing pools, removing the pools (by changing their weights to zero)
 *
 * @dev The factory requires ROLE_TOKEN_CREATOR permission on the Moda token to mint yield
 *      (see `mintYieldTo` function)
 *
 * @author Kevin Brown, based on Illuvium Pool Factory Contract by Pedro Bergamini, reviewed by Basil Gorin
 */
contract ModaPoolFactory is Ownable, ModaAware {
	// @dev FACTORY_UID defined to add another check to ensure compliance with the contract.
	function FACTORY_UID() external pure returns (uint256) {
		return ModaConstants.FACTORY_UID;
	}

	/// @dev Auxiliary data structure used only in getPoolData() view function
	struct PoolData {
		// @dev pool token address (like Moda, or an LP token)
		address poolToken;
		// @dev pool address (like deployed core pool instance)
		address poolAddress;
		// @dev pool weight (200 for Moda pools, 400 for Moda/ETH pools - set during deployment)
		uint32 weight;
	}

	/**
	 * @dev Moda/second determines yield farming reward base
	 *      used by the yield pools controlled by the factory
	 */
	uint256 public immutable initialModaPerSecond;

	/**
	 * @dev The yield is distributed proportionally to pool weights;
	 *      total weight is here to help in determining the proportion
	 */
	uint32 public totalWeight;

	/**
	 * @dev Moda/second decreases by 3% every period;
	 *      updates are lazy calculated via a compound interest function.
	 */
	uint32 public immutable secondsPerUpdate;

	/**
	 * @dev Start timestamp is when the pool starts.
	 */
	uint public immutable startTimestamp;

	/**
	 * @dev End timestamp is the last time when Moda/second can be decreased;
	 *      it is implied that yield farming stops after that block
	 */
	uint public immutable endTimestamp;

	/// @dev Maps pool token address (like Moda) -> pool address (like core pool instance)
	mapping(address => address) public pools;

	/// @dev Keeps track of registered pool addresses, maps pool address -> exists flag
	mapping(address => bool) public poolExists;

	/**
	 * @dev Fired in createPool() and registerPool()
	 *
	 * @param _by an address which executed an action
	 * @param poolToken pool token address (like Moda or a Moda / ETH LP token)
	 * @param poolAddress deployed pool instance address
	 * @param weight pool weight
	 */
	event PoolRegistered(address indexed _by, address indexed poolToken, address indexed poolAddress, uint64 weight);

	/**
	 * @dev Fired in changePoolWeight()
	 *
	 * @param _by an address which executed an action
	 * @param _poolAddress deployed pool instance address
	 * @param _weight new pool weight
	 */
	event WeightUpdated(address indexed _by, address indexed _poolAddress, uint32 _weight);

	/**
	 * @dev Fired in mintYieldTo()
	 *
	 * @param _to recipient of the minting
	 * @param _amount amount minted in wei
	 */
	event YieldMinted(address indexed _to, uint256 _amount);

	/**
	 * @dev Fired in createCorePool()
	 *
	 * @param _by an address which executed an action
	 * @param poolAddress deployed pool instance address
	 */
	event CorePoolCreated(address indexed _by, address indexed poolAddress);

	/**
	 * @dev Creates/deploys a factory instance
	 *
	 * @param _moda Moda ERC20 token address
	 * @param _modaPerSecond initial Moda/second value for rewards
	 * @param _secondsPerUpdate how frequently the rewards gets updated (decreased by 3%)
	 * @param _startTimestamp timestamp to measure _secondsPerUpdate from
	 * @param _endTimestamp timestamp when farming stops and rewards cannot be updated anymore
	 */
	constructor(
		address _moda,
		uint256 _modaPerSecond,
		uint32 _secondsPerUpdate,
		uint _startTimestamp,
		uint _endTimestamp
	) ModaAware(_moda) {
		// verify the inputs are set
		require(_modaPerSecond > 0, 'Moda/second not set');
		require(_secondsPerUpdate > 0, 'seconds/update not set');
		require(_startTimestamp > 0, 'start timestamp not set');
		require(_endTimestamp > _startTimestamp, 'invalid end timestamp: must be greater than init timestamp');

		// save the inputs into internal state variables
		initialModaPerSecond = _modaPerSecond;
		secondsPerUpdate = _secondsPerUpdate;
		startTimestamp = _startTimestamp;
		endTimestamp = _endTimestamp;
	}

	/**
	 * @notice Given a pool token retrieves corresponding pool address
	 *
	 * @dev A shortcut for `pools` mapping
	 *
	 * @param poolToken pool token address (like Moda) to query pool address for
	 * @return pool address for the token specified
	 */
	function getPoolAddress(address poolToken) external view returns (address) {
		// read the mapping and return
		return pools[poolToken];
	}

	/**
	 * @notice Reads pool information for the pool defined by its pool token address,
	 *      designed to simplify integration with the front ends
	 *
	 * @param _poolToken pool token address to query pool information for
	 * @return pool information packed in a PoolData struct
	 */
	function getPoolData(address _poolToken) external view returns (PoolData memory) {
		// get the pool address from the mapping
		address poolAddr = pools[_poolToken];

		// throw if there is no pool registered for the token specified
		require(poolAddr != address(0), 'pool not found');

		// read pool information from the pool smart contract
		// via the pool interface (IPool)
		address poolToken = IPool(poolAddr).poolToken();
		uint32 weight = IPool(poolAddr).weight();

		// create the in-memory structure and return it
		return PoolData({poolToken: poolToken, poolAddress: poolAddr, weight: weight});
	}

	/**
	 * @dev Creates a core pool (ModaCorePool) and registers it within the factory
	 *
	 * @dev Can be executed by the pool factory owner only
	 *
	 * @param poolStartTimestamp init timestamp to be used for the pool creation time
	 * @param weight weight of the pool to be created
	 */
	function createCorePool(uint256 poolStartTimestamp, uint32 weight) external virtual onlyOwner {
		// create/deploy new core pool instance
		IPool pool = new ModaCorePool(moda, address(this), address(0), moda, weight, poolStartTimestamp);

		// Now the owner needs to be set to whoever is calling this function.
		pool.transferOwnership(msg.sender);

		// register it within this factory
		registerPool(address(pool));

		// Tell the world we've done that
		emit CorePoolCreated(msg.sender, address(pool));
	}

	/**
	 * @dev Registers an already deployed pool instance within the factory
	 *
	 * @dev Can be executed by the pool factory owner only
	 *
	 * @param poolAddr address of the already deployed pool instance
	 */
	function registerPool(address poolAddr) public onlyOwner {
		// read pool information from the pool smart contract
		// via the pool interface (IPool)
		address poolToken = IPool(poolAddr).poolToken();
		uint32 weight = IPool(poolAddr).weight();

		// ensure that the pool is not already registered within the factory
		require(pools[poolToken] == address(0), 'this pool is already registered');

		// create pool structure, register it within the factory
		pools[poolToken] = poolAddr;
		poolExists[poolAddr] = true;
		// update total pool weight of the factory
		totalWeight += weight;

		// emit an event
		emit PoolRegistered(msg.sender, poolToken, poolAddr, weight);
	}

	/**
	 * @notice Calculates compound interest
	 */
	function compound(uint principal, uint periods) public pure returns (uint) {
		return
			ABDKMath64x64.mulu(
				// Rate is -3% per period, e.g. 97/100.
				ABDKMath64x64.pow(ABDKMath64x64.div(97, 100), periods),
				principal
			);
	}

	/// @notice Calculates the effective moda per second at a future timestamp.
	function modaPerSecondAt(uint time) external view returns (uint256) {
		// If we're before the start, just return initial.
		if (time < startTimestamp) return 0;

		// Override for now. Return initialModaPerSecond for all times
		return initialModaPerSecond;

		// // If we're at the end, we don't continue to decrease.
		// if (time > endTimestamp) time = endTimestamp;

		// // How many times do we need to decrease the rewards
		// // between the last time we've calculated and now?
		// uint periods = (time - startTimestamp) / secondsPerUpdate;

		// // Calculate the resulting amount after applying that many decreases.
		// return compound(initialModaPerSecond, periods);
	}

	/**
	 * @dev Mints Moda tokens; executed by Moda Pool only
	 *
	 * @dev Requires factory to have ROLE_TOKEN_CREATOR permission
	 *      on the Moda ERC20 token instance
	 *
	 * @param _to an address to mint tokens to
	 * @param _amount amount of Moda tokens to mint
	 */
	function mintYieldTo(address _to, uint256 _amount) external {
		// verify that sender is a pool registered withing the factory
		require(poolExists[msg.sender], 'pool is not registered with this factory');

		// mint Moda tokens as required
		mintModa(_to, _amount);

		// Tell the world we've done this
		emit YieldMinted(_to, _amount);
	}

	/**
	 * @dev Changes the weight of the pool;
	 *      executed by the pool itself or by the factory owner
	 *
	 * @param poolAddr address of the pool to change weight for
	 * @param weight new weight value to set to
	 */
	function changePoolWeight(address poolAddr, uint32 weight) external {
		// verify function is executed either by factory owner or by the pool itself
		require(msg.sender == owner(), 'Must be owner');
		require(poolExists[poolAddr], 'Pool not registered');

		// recalculate total weight
		totalWeight = totalWeight + weight - IPool(poolAddr).weight();

		// set the new pool weight
		IPool(poolAddr).setWeight(weight);

		// emit an event
		emit WeightUpdated(msg.sender, poolAddr, weight);
	}
}
