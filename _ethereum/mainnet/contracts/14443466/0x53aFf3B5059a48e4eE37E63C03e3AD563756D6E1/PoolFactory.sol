// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeCast.sol";
import "./Timestamp.sol";
import "./ICorePool.sol";
import "./IERC20Mintable.sol";
import "./ErrorHandler.sol";

/**
 * @title Pool Factory V2
 *
 * @dev Pool Factory manages Illuvium staking pools, provides a single
 *      public interface to access the pools, provides an interface for the pools
 *      to mint yield rewards, access pool-related info, update weights, etc.
 *
 * @dev The factory is authorized (via its owner) to register new pools, change weights
 *      of the existing pools, removing the pools (by changing their weights to zero).
 *
 * @dev The factory requires ROLE_TOKEN_CREATOR permission on the ILV and sILV tokens to mint yield
 *      (see `mintYieldTo` function).
 *
 * @notice The contract uses Ownable implementation, so only the eDAO is able to handle
 *         admin activities, such as registering new pools, doing contract upgrades,
 *         changing pool weights, managing emission schedules and so on.
 *
 */
contract PoolFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable, Timestamp {
    using ErrorHandler for bytes4;
    using SafeCast for uint256;

    /// @dev Auxiliary data structure used only in getPoolData() view function
    struct PoolData {
        // @dev pool token address (like ILV)
        address poolToken;
        // @dev pool address (like deployed core pool instance)
        address poolAddress;
        // @dev pool weight (200 for ILV pools, 800 for ILV/ETH pools - set during deployment)
        uint32 weight;
        // @dev flash pool flag
        bool isFlashPool;
    }

    /**
     * @dev ILV/second determines yield farming reward base
     *      used by the yield pools controlled by the factory.
     */
    uint192 public ilvPerSecond;

    /**
     * @dev The yield is distributed proportionally to pool weights;
     *      total weight is here to help in determining the proportion.
     */
    uint32 public totalWeight;

    /**
     * @dev ILV/second decreases by 3% every seconds/update
     *      an update is triggered by executing `updateILVPerSecond` public function.
     */
    uint32 public secondsPerUpdate;

    /**
     * @dev End time is the last timestamp when ILV/second can be decreased;
     *      it is implied that yield farming stops after that timestamp.
     */
    uint32 public endTime;

    /**
     * @dev Each time the ILV/second ratio gets updated, the timestamp
     *      when the operation has occurred gets recorded into `lastRatioUpdate`.
     * @dev This timestamp is then used to check if seconds/update `secondsPerUpdate`
     *      has passed when decreasing yield reward by 3%.
     */
    uint32 public lastRatioUpdate;

    /// @dev ILV token address.
    address private _ilv;

    /// @dev sILV token address
    address private _silv;

    /// @dev Maps pool token address (like ILV) -> pool address (like core pool instance).
    mapping(address => address) public pools;

    /// @dev Keeps track of registered pool addresses, maps pool address -> exists flag.
    mapping(address => bool) public poolExists;

    /**
     * @dev Fired in registerPool()
     *
     * @param by an address which executed an action
     * @param poolToken pool token address (like ILV)
     * @param poolAddress deployed pool instance address
     * @param weight pool weight
     * @param isFlashPool flag indicating if pool is a flash pool
     */
    event LogRegisterPool(
        address indexed by,
        address indexed poolToken,
        address indexed poolAddress,
        uint64 weight,
        bool isFlashPool
    );

    /**
     * @dev Fired in `changePoolWeight()`.
     *
     * @param by an address which executed an action
     * @param poolAddress deployed pool instance address
     * @param weight new pool weight
     */
    event LogChangePoolWeight(address indexed by, address indexed poolAddress, uint32 weight);

    /**
     * @dev Fired in `updateILVPerSecond()`.
     *
     * @param by an address which executed an action
     * @param newIlvPerSecond new ILV/second value
     */
    event LogUpdateILVPerSecond(address indexed by, uint256 newIlvPerSecond);

    /**
     * @dev Fired in `setEndTime()`.
     *
     * @param by an address which executed the action
     * @param endTime new endTime value
     */
    event LogSetEndTime(address indexed by, uint32 endTime);

    /**
     * @dev Initializes a factory instance
     *
     * @param ilv_ ILV ERC20 token address
     * @param silv_ sILV ERC20 token address
     * @param _ilvPerSecond initial ILV/second value for rewards
     * @param _secondsPerUpdate how frequently the rewards gets updated (decreased by 3%), seconds
     * @param _initTime timestamp to measure _secondsPerUpdate from
     * @param _endTime timestamp number when farming stops and rewards cannot be updated anymore
     */

    function initialize(
        address ilv_,
        address silv_,
        uint192 _ilvPerSecond,
        uint32 _secondsPerUpdate,
        uint32 _initTime,
        uint32 _endTime
    ) external initializer {
        bytes4 fnSelector = this.initialize.selector;
        // verify the inputs are set correctly
        fnSelector.verifyNonZeroInput(uint160(ilv_), 0);
        fnSelector.verifyNonZeroInput(uint160(silv_), 1);
        fnSelector.verifyNonZeroInput(_ilvPerSecond, 2);
        fnSelector.verifyNonZeroInput(_secondsPerUpdate, 3);
        fnSelector.verifyNonZeroInput(_initTime, 4);
        fnSelector.verifyInput(_endTime > _now256(), 5);

        __Ownable_init();

        // save the inputs into internal state variables
        _ilv = ilv_;
        _silv = silv_;
        ilvPerSecond = _ilvPerSecond;
        secondsPerUpdate = _secondsPerUpdate;
        lastRatioUpdate = _initTime;
        endTime = _endTime;
    }

    /**
     * @notice Given a pool token retrieves corresponding pool address.
     *
     * @dev A shortcut for `pools` mapping.
     *
     * @param poolToken pool token address (like ILV) to query pool address for
     * @return pool address for the token specified
     */
    function getPoolAddress(address poolToken) external view virtual returns (address) {
        // read the mapping and return
        return address(pools[poolToken]);
    }

    /**
     * @notice Reads pool information for the pool defined by its pool token address,
     *      designed to simplify integration with the front ends.
     *
     * @param _poolToken pool token address to query pool information for.
     * @return pool information packed in a PoolData struct.
     */
    function getPoolData(address _poolToken) public view virtual returns (PoolData memory) {
        bytes4 fnSelector = this.getPoolData.selector;
        // get the pool address from the mapping
        ICorePool pool = ICorePool(pools[_poolToken]);

        // throw if there is no pool registered for the token specified
        fnSelector.verifyState(uint160(address(pool)) != 0, 0);

        // read pool information from the pool smart contract
        // via the pool interface (ICorePool)
        address poolToken = pool.poolToken();
        bool isFlashPool = pool.isFlashPool();
        uint32 weight = pool.weight();

        // create the in-memory structure and return it
        return PoolData({ poolToken: poolToken, poolAddress: address(pool), weight: weight, isFlashPool: isFlashPool });
    }

    /**
     * @dev Verifies if `secondsPerUpdate` has passed since last ILV/second
     *      ratio update and if ILV/second reward can be decreased by 3%.
     *
     * @return true if enough time has passed and `updateILVPerSecond` can be executed.
     */
    function shouldUpdateRatio() public view virtual returns (bool) {
        // if yield farming period has ended
        if (_now256() > endTime) {
            // ILV/second reward cannot be updated anymore
            return false;
        }

        // check if seconds/update have passed since last update
        return _now256() >= lastRatioUpdate + secondsPerUpdate;
    }

    /**
     * @dev Registers an already deployed pool instance within the factory.
     *
     * @dev Can be executed by the pool factory owner only.
     *
     * @param pool address of the already deployed pool instance
     */
    function registerPool(address pool) public virtual onlyOwner {
        // read pool information from the pool smart contract
        // via the pool interface (ICorePool)
        address poolToken = ICorePool(pool).poolToken();
        bool isFlashPool = ICorePool(pool).isFlashPool();
        uint32 weight = ICorePool(pool).weight();

        // create pool structure, register it within the factory
        pools[poolToken] = pool;
        poolExists[pool] = true;
        // update total pool weight of the factory
        totalWeight += weight;

        // emit an event
        emit LogRegisterPool(msg.sender, poolToken, address(pool), weight, isFlashPool);
    }

    /**
     * @notice Decreases ILV/second reward by 3%, can be executed
     *      no more than once per `secondsPerUpdate` seconds.
     */
    function updateILVPerSecond() external virtual {
        bytes4 fnSelector = this.updateILVPerSecond.selector;
        // checks if ratio can be updated i.e. if seconds/update have passed
        fnSelector.verifyState(shouldUpdateRatio(), 0);

        // decreases ILV/second reward by 3%.
        // To achieve that we multiply by 97 and then
        // divide by 100
        ilvPerSecond = (ilvPerSecond * 97) / 100;

        // set current timestamp as the last ratio update timestamp
        lastRatioUpdate = (_now256()).toUint32();

        // emit an event
        emit LogUpdateILVPerSecond(msg.sender, ilvPerSecond);
    }

    /**
     * @dev Mints ILV tokens; executed by ILV Pool only.
     *
     * @dev Requires factory to have ROLE_TOKEN_CREATOR permission
     *      on the ILV ERC20 token instance.
     *
     * @param _to an address to mint tokens to
     * @param _value amount of ILV tokens to mint
     * @param _useSILV whether ILV or sILV should be minted
     */
    function mintYieldTo(
        address _to,
        uint256 _value,
        bool _useSILV
    ) external virtual {
        bytes4 fnSelector = this.mintYieldTo.selector;
        // verify that sender is a pool registered withing the factory
        fnSelector.verifyState(poolExists[msg.sender], 0);

        // mints the requested token to the indicated address
        if (!_useSILV) {
            IERC20Mintable(_ilv).mint(_to, _value);
        } else {
            IERC20Mintable(_silv).mint(_to, _value);
        }
    }

    /**
     * @dev Changes the weight of the pool;
     *      executed by the pool itself or by the factory owner.
     *
     * @param pool address of the pool to change weight for
     * @param weight new weight value to set to
     */
    function changePoolWeight(address pool, uint32 weight) external virtual {
        bytes4 fnSelector = this.changePoolWeight.selector;
        // verify function is executed either by factory owner or by the pool itself
        fnSelector.verifyAccess(msg.sender == owner() || poolExists[msg.sender]);

        // recalculate total weight
        totalWeight = totalWeight + weight - ICorePool(pool).weight();

        // set the new pool weight
        ICorePool(pool).setWeight(weight);

        // emit an event
        emit LogChangePoolWeight(msg.sender, address(pool), weight);
    }

    /**
     * @dev Updates yield generation ending timestamp.
     *
     * @param _endTime new end time value to be stored
     */
    function setEndTime(uint32 _endTime) external virtual onlyOwner {
        bytes4 fnSelector = this.setEndTime.selector;
        // checks if _endTime is a timestap after the last time that
        // ILV/second has been updated
        fnSelector.verifyInput(_endTime > lastRatioUpdate, 0);
        // updates endTime state var
        endTime = _endTime;

        // emits an event
        emit LogSetEndTime(msg.sender, _endTime);
    }

    /**
     * @dev Overrides `Ownable.renounceOwnership()`, to avoid accidentally
     *      renouncing ownership of the PoolFactory contract.
     */
    function renounceOwnership() public virtual override {}

    /// @dev See `CorePool._authorizeUpgrade()`
    function _authorizeUpgrade(address) internal virtual override onlyOwner {}

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}
