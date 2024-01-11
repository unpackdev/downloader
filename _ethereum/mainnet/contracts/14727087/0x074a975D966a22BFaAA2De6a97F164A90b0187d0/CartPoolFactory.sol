// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./IPool.sol";

/**
 * @title CART Pool Factory
 *
 * @notice CART Pool Factory manages CART Yield farming pools, provides a single
 *      public interface to access the pools, provides an interface for the pools
 *      to mint yield rewards, access pool-related info, update weights, etc.
 *
 * @notice The factory is authorized (via its owner) to register new pools, change weights
 *      of the existing pools, removing the pools (by changing their weights to zero)
 *
 * @dev The factory requires ROLE_TOKEN_CREATOR permission on the CART token to mint yield
 *      (see `mintYieldTo` function)
 *
 */
contract CartPoolFactory is Ownable, ReentrancyGuard {
    /**
     * @dev Smart contract unique identifier, a random number
     * @dev Should be regenerated each time smart contact source code is changed
     *      and changes smart contract itself is to be redeployed
     * @dev Generated using https://www.random.org/bytes/
     */
    uint256 public constant FACTORY_UID = 0xb77099a6d99df5887a6108e413b3c6dfe0c11a1583c9d9b3cd08bfb8ca996aef;

    /// @dev Link to CART STREET ERC20 Token instance
    address public immutable CART;

    /// @dev Auxiliary data structure used only in getPoolData() view function
    struct PoolData {
        // @dev pool token address (like CART)
        address poolToken;
        // @dev pool address (like deployed core pool instance)
        address poolAddress;
        // @dev pool weight (200 for CART pools, 800 for CART/ETH pools - set during deployment)
        uint256 weight;
        // @dev flash pool flag
        bool isFlashPool;
    }

    /**
     * @dev CART/block determines yield farming reward base
     *      used by the yield pools controlled by the factory
     */
    uint256 public cartPerBlock;

    /**
     * @dev The yield is distributed proportionally to pool weights;
     *      total weight is here to help in determining the proportion
     */
    uint256 public totalWeight;

    /**
     * @dev End block is the last block when CART/block can be decreased;
     *      it is implied that yield farming stops after that block
     */
    uint256 public endBlock;

    /// @dev Maps pool token address (like CART) -> pool address (like core pool instance)
    mapping(address => address) public pools;

    /// @dev Keeps track of registered pool addresses, maps pool address -> exists flag
    mapping(address => bool) public poolExists;

    /**
     * @dev Fired in createPool() and registerPool()
     *
     * @param _by an address which executed an action
     * @param poolToken pool token address (like CART)
     * @param poolAddress deployed pool instance address
     * @param weight pool weight
     * @param isFlashPool flag indicating if pool is a flash pool
     */
    event PoolRegistered(
        address indexed _by,
        address indexed poolToken,
        address indexed poolAddress,
        uint256 weight,
        bool isFlashPool
    );

    /**
     * @dev Fired in changePoolWeight()
     *
     * @param _by an address which executed an action
     * @param poolAddress deployed pool instance address
     * @param weight new pool weight
     */
    event WeightUpdated(address indexed _by, address indexed poolAddress, uint256 weight);

    /**
     * @dev Fired in updateCartPerBlock()
     *
     * @param _by an address which executed an action
     * @param newCartPerBlock new CART/block value
     */
    event CartRatioUpdated(address indexed _by, uint256 newCartPerBlock);

    /**
     * @dev Fired in mintYieldTo()
     *
     * @param _to an address to mint tokens to
     * @param amount amount of CART tokens to mint
     */
    event MintYield(address indexed _to, uint256 amount);

    /**
     * @dev Creates/deploys a factory instance
     *
     * @param _cart CART ERC20 token address
     * @param _cartPerBlock initial CART/block value for rewards
     * @param _endBlock block number when farming stops and rewards cannot be updated anymore
     */
    constructor(
        address _cart,
        uint256 _cartPerBlock,
        uint256 _endBlock
    ) {
        // verify the inputs are set
        require(_cart != address(0) , "CART is invalid");
        require(_cartPerBlock > 0, "CART/block not set");

        // save the inputs into internal state variables
        CART = _cart;
        cartPerBlock = _cartPerBlock;
        endBlock = _endBlock;
    }

    /**
     * @notice Given a pool token retrieves corresponding pool address
     *
     * @dev A shortcut for `pools` mapping
     *
     * @param poolToken pool token address (like CART) to query pool address for
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
        require(poolAddr != address(0), "pool not found");

        // read pool information from the pool smart contract
        // via the pool interface (IPool)
        bool isFlashPool = IPool(poolAddr).isFlashPool();
        uint256 weight = IPool(poolAddr).weight();

        // create the in-memory structure and return it
        return PoolData({ poolToken: _poolToken, poolAddress: poolAddr, weight: weight, isFlashPool: isFlashPool });
    }

    /**
     * @dev Registers an already deployed pool instance within the factory
     *
     * @dev Can be executed by the pool factory owner only
     *
     * @param poolAddr address of the already deployed pool instance
     */
    function registerPool(address poolAddr) external onlyOwner {
        // read pool information from the pool smart contract
        // via the pool interface (IPool)
        address poolToken = IPool(poolAddr).poolToken();
        bool isFlashPool = IPool(poolAddr).isFlashPool();
        uint256 weight = IPool(poolAddr).weight();

        // ensure that the pool is not already registered within the factory
        require(pools[poolToken] == address(0), "this pool is already registered");

        // create pool structure, register it within the factory
        pools[poolToken] = poolAddr;
        poolExists[poolAddr] = true;
        // update total pool weight of the factory
        totalWeight += weight;

        // emit an event
        emit PoolRegistered(msg.sender, poolToken, poolAddr, weight, isFlashPool);
    }

    /**
     * @dev Mints CART tokens; executed by CART Pool only
     *
     * @dev Requires factory to have ROLE_TOKEN_CREATOR permission
     *      on the CART ERC20 token instance
     *
     * @param _to an address to mint tokens to
     * @param _amount amount of CART tokens to mint
     */
    function mintYieldTo(address _to, uint256 _amount) external {
        // verify that sender is a pool registered withing the factory
        require(poolExists[msg.sender], "access denied");

        // transfer CART tokens as required
        transferCartToken(_to, _amount);

        emit MintYield(_to, _amount);
    }

    /**
     * @dev Changes the weight of the pool;
     *      executed by the pool itself or by the factory owner
     *
     * @param poolAddr address of the pool to change weight for
     * @param weight new weight value to set to
     */
    function changePoolWeight(address poolAddr, uint256 weight) external {
        // verify function is executed either by factory owner or by the pool itself
        require(msg.sender == owner() || poolExists[msg.sender]);

        // recalculate total weight
        totalWeight = totalWeight + weight - IPool(poolAddr).weight();

        // set the new pool weight
        IPool(poolAddr).setWeight(weight);

        // emit an event
        emit WeightUpdated(msg.sender, poolAddr, weight);
    }

    /**
     * @dev set NFT Info of the pool;
     *      executed by the pool itself or by the factory owner
     *
     * @param poolAddr address of the pool to change NFT Info
     * @param nftAddress address of NFT
     * @param nftWeight weight of NFT
     */
    function setNFTWeight(address poolAddr, address nftAddress, uint256 nftWeight) external {
        // verify function is executed either by factory owner or by the pool itself
        require(msg.sender == owner() || poolExists[msg.sender]);

        // set the new NFT Info
        IPool(poolAddr).NFTWeightUpdated(nftAddress, nftWeight);
    }

    /**
     * @dev set new stake weight multiplier
     *      executed by the factory owner

     ** @param poolAddr address of the pool to change weight multiplier
     * @param _newWeightMultiplier  new stake weight multiplier
     */
    function setWeightMultiplier(address poolAddr, uint256 _newWeightMultiplier) external {
        // verify function is executed either by factory owner
        require(msg.sender == owner());
        // set the new weight multiplier
        IPool(poolAddr).setWeightMultiplierbyFactory(_newWeightMultiplier);
    }

    /**
     * @dev set new cartPerBlock
     *      executed by the factory owner
     *
     * @param _cartPerBlock  new CART/block value for rewards
     */
    function setCartPerBlock(uint256 _cartPerBlock) external {
        // verify function is executed either by factory owner
        require(msg.sender == owner());
        // set new CART/block value for rewards
        cartPerBlock = _cartPerBlock;
    }

    /**
     * @dev set new endBlock
     *      executed by the factory owner
     *
     * @param _endBlock  new endblock number, this number means when farming stops and rewards cannot be updated anymore
     */
    function setEndBlock(uint256 _endBlock) external {
        // verify function is executed either by factory owner
        require(msg.sender == owner());
        // verify block number
        require(_endBlock > block.number, "invalid end block: must be greater than current block");
        // set new endblock number
        endBlock = _endBlock;
    }

    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override block number in helper test smart contracts
     *
     * @return `block.number` in mainnet, custom values in testnets (if overridden)
     */
    function blockNumber() public view virtual returns (uint256) {
        // return current block number
        return block.number;
    }

    /**
     * @dev Keeps track of registered pool addresses
     *
     * @param _pool pool address
     * @return bool  whether is pool Exists
     */
    function isPoolExists(address _pool) external view returns (bool) {
        return poolExists[_pool];
    }

    /**
     * @dev Executes SafeERC20.safeTransfer on a CART token
     *
     */
    function transferCartToken(address _to, uint256 _value) internal {
        // just delegate call to the target
        SafeERC20.safeTransfer(IERC20(CART), _to, _value);
    }

    /**
     * @notice Emergency withdraw specified amount of tokens, call only by owner
     *
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     */
    function emergencyWithdraw() external nonReentrant {
        require(msg.sender == owner(), 'Access denied!');
        SafeERC20.safeTransfer(IERC20(CART), msg.sender, IERC20(CART).balanceOf(address(this)));
    }

}