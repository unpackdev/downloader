// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/eth/interface/IBalancerPool.sol

pragma solidity ^0.5.0;


interface IBalancerPool {
  function isPublicSwap()
  external view
  returns (bool);

  function getCurrentTokens()
  external
  view
  returns (IERC20[] memory tokens);

  function calcOutGivenIn(
    uint tokenBalanceIn,
    uint tokenWeightIn,
    uint tokenBalanceOut,
    uint tokenWeightOut,
    uint tokenAmountIn,
    uint swapFee
  )
  external
  pure
  returns (uint tokenAmountOut);

  function swapExactAmountIn(
    IERC20 tokenIn,
    uint tokenAmountIn,
    IERC20 tokenOut,
    uint minAmountOut,
    uint maxPrice
  )
  external
  returns (uint tokenAmountOut, uint spotPriceAfter);

  function getColor()
  external view
  returns (bytes32);

  function getBalance(IERC20 token)
  external
  view
  returns (uint);

  function getSwapFee()
  external
  view
  returns (uint);

  function getDenormalizedWeight(IERC20 token)
  external
  view
  returns (uint);
}

// File: contracts/eth/BalancerRoute.sol

pragma solidity ^0.5.0;



contract BalancerRoute is Ownable {
  // token => pool
  mapping(address => IBalancerPool[]) _balancerPools;
  // pool => tokens
  mapping(address => IERC20[]) _balancerPoolTokens;
  // pool => token => bool
  mapping(address => mapping(address => bool)) public poolTokenEnabled;

  function _cleanPool(IBalancerPool pool)
  internal
  {
    IERC20[] memory oldTokens = _balancerPoolTokens[address(pool)];

    if (oldTokens.length == 0) return;

    for (uint256 i = 0; i < oldTokens.length; i++) {
      address oldToken = address(oldTokens[i]);
      poolTokenEnabled[address(pool)][oldToken] = false;

      IBalancerPool[] storage currentPools = _balancerPools[oldToken];
      for (uint256 j = 0; j < currentPools.length; j++) {
        if (currentPools[j] == pool) {
          currentPools[j] = currentPools[currentPools.length - 1];
          currentPools.length--;
          break;
        }
      }
    }

    delete _balancerPoolTokens[address(pool)];
  }

  function getPools(IERC20 token)
  public
  view
  returns (IBalancerPool[] memory pools)
  {
    return _balancerPools[address(token)];
  }

  function getPoolTokens(IBalancerPool pool)
  public
  view
  returns (IERC20[] memory tokens)
  {
    return _balancerPoolTokens[address(pool)];
  }

  function addPool(IBalancerPool pool)
  public
  onlyOwner
  {
    require(pool.getColor() == bytes32("BRONZE"), 'Invalid color');
    require(pool.isPublicSwap(), 'Must be public');

    IERC20[] memory tokens = pool.getCurrentTokens();
    require(tokens.length > 1, 'Invalid token size');

    _cleanPool(pool);

    _balancerPoolTokens[address(pool)] = tokens;
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = address(tokens[i]);
      IBalancerPool[] storage currentPools = _balancerPools[token];
      // require(currentPools.length <= 50, 'Too many pools');

      poolTokenEnabled[address(pool)][token] = true;
      currentPools.push(pool);
    }
  }

  function addPools(IBalancerPool[] memory pools)
  public
  {
    for (uint256 i = 0; i < pools.length; i++) {
      addPool(pools[i]);
    }
  }

  function removePool(IBalancerPool pool)
  public
  onlyOwner
  {
    _cleanPool(pool);
  }
}