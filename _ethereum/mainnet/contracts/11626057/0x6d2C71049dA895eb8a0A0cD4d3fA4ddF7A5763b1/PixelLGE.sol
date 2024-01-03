pragma solidity ^0.6.2;



// File @openzeppelin/contracts/GSN/Context.sol

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
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// File @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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

// File @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   *
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   *
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// File @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies in extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{ value: amount }("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain`call` is an unsafe replacement for a function call: use this
   * function instead.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data. To convert to the expected return value,
   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   *
   * _Available since v3.1._
   */
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
   * `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but also transferring `value` wei to `target`.
   *
   * Requirements:
   *
   * - the calling contract must have an ETH balance of at least `value`.
   * - the called Solidity function must be `payable`.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    return _functionCallWithValue(target, data, value, errorMessage);
  }

  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  ) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

// File @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
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
  constructor() internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
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
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol@v1.0.1

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// File contracts/uniswapv2/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function migrator() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;

  function setMigrator(address) external;
}

// File contracts/uniswapv2/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// File contracts/uniswapv2/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

// File contracts/uniswapv2/interfaces/IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;
}

contract PixelLGE is Context, Ownable {
  using SafeMath for uint256;
  using Address for address;

  // Uniswap addresses
  IUniswapV2Factory public uniswapFactory;
  IUniswapV2Router02 public uniswapRouterV2;
  address public tokenUniswapPairETH;
  address public tokenUniswapPairDEFLCT;

  // LGE value book-keeping
  mapping(address => uint256) public ethContributedForLPTokens;
  uint256 public ETHLPperETHUnit;
  uint256 public DEFLCTLPperETHUnit;
  uint256 public totalETHContributed;
  uint256 public totalETHLPTokensMinted;
  uint256 public totalDEFLCTLPTokensMinted;

  // Event book-keeping
  bool public lgeStarted;
  bool public LPGenerationCompleted;
  uint256 public lgeEndTime;
  uint256 public lpUnlockTime;

  // Bonus token book-keepings
  mapping(address => uint256) public ETHContributedForBonusTokens;
  uint256 public bonusTokenPerETHUnit;

  /** TOKEN AMOUNTS, breakdown:
   * 6250 FOR PIXEL/ETH
   * 6250 FOR DEF/PIXEL
   * 2500 AS BONUS.
   * = 12,500
   */
  uint256 public pixelInitialLiq = 6250 * 10**18;
  uint256 public deflectInitialLiq = 6250 * 10**18;
  uint256 public bonusTokens = 2500 * 10**18;
  uint256 public ethUsedForDeflectPair;

  address public pixelDevAddr;
  address public deflctDevAddr;
  address public DEFLCT;
  address public WETH;
  IERC20 public pixelToken;

  event LiquidityAddition(address indexed dst, uint256 value);
  event totalLPTokenClaimed(address dst, uint256 ethLP, uint256 defLP);
  event TokenClaimed(address dst, uint256 value);

  event LPTokenClaimed(address dst, uint256 value);

  constructor(
    address _pixelTokenAddr,
    address _uniswapRouterAddr,
    address _uniswapFactoryAddr,
    address _pixelDevAddr,
    address _deflectDevAddr,
    address _deflectTokenAddr
  ) public {
    uniswapRouterV2 = IUniswapV2Router02(_uniswapRouterAddr);
    uniswapFactory = IUniswapV2Factory(_uniswapFactoryAddr);

    pixelToken = IERC20(_pixelTokenAddr);

    pixelDevAddr = _pixelDevAddr;
    deflctDevAddr = _deflectDevAddr;

    DEFLCT = _deflectTokenAddr;
    WETH = uniswapRouterV2.WETH();

    createUniswapPairs();
  }

  function startLGE() external onlyOwner {
    require(!lgeStarted, "LGE already started");
    lgeEndTime = now.add(7 days);
    lpUnlockTime = now.add(7 days).add(2 hours);
    lgeStarted = true;
  }

  // Liquidity Generation Event
  function createUniswapPairs() public onlyOwner returns (address, address) {
    require(tokenUniswapPairETH == address(0), "PIX/ETH pair already created");
    tokenUniswapPairETH = uniswapFactory.createPair(address(uniswapRouterV2.WETH()), address(pixelToken));

    require(tokenUniswapPairDEFLCT == address(0), "PIX/DEFLCT pair already created");
    tokenUniswapPairDEFLCT = uniswapFactory.createPair(address(DEFLCT), address(pixelToken));

    return (tokenUniswapPairETH, tokenUniswapPairDEFLCT);
  }

  function addLiquidity() public payable {
    require(now < lgeEndTime && lgeStarted, "Liquidity Generation Event over or not started yet");
    ethContributedForLPTokens[msg.sender] += msg.value; // Overflow protection from safemath is not needed here
    ETHContributedForBonusTokens[msg.sender] = ethContributedForLPTokens[msg.sender];

    // 50% of ETH is used to market purchase DEFLCT
    uint256 ethForBuyingDeflect = msg.value.div(100).mul(50);
    ethUsedForDeflectPair = ethUsedForDeflectPair.add(ethForBuyingDeflect);

    uint256 deadline = block.timestamp + 15;
    address[] memory path = new address[](2);
    path[0] = WETH;
    path[1] = DEFLCT;

    require(IERC20(DEFLCT).approve(address(uniswapRouterV2), uint256(-1)), "Approval issue");
    uniswapRouterV2.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: ethForBuyingDeflect }(0, path, address(this), deadline);

    totalETHContributed = totalETHContributed.add(msg.value);
    emit LiquidityAddition(msg.sender, msg.value);
  }

  function addLiquidityETHToUniswapPair() internal {
    require(now >= lgeEndTime, "Liquidity generation ongoing");
    require(LPGenerationCompleted == false, "Liquidity generation already finished");
    if (_msgSender() != owner()) {
      require(now > (lgeEndTime + 2 hours), "Please wait for dev grace period");
    }

    uint256 pixelDevETHFee = totalETHContributed.div(100).mul(5);
    uint256 deflctDevETHFee = totalETHContributed.div(100).mul(5);
    uint256 ETHRemaining = address(this).balance.sub(pixelDevETHFee).sub(deflctDevETHFee);

    IWETH(WETH).deposit{ value: ETHRemaining }();

    // Transfer the team fees here.
    (bool pixelDevETHTransferSuccess, ) = pixelDevAddr.call{ value: pixelDevETHFee }("");
    (bool deflectDevETHTransferSuccess, ) = deflctDevAddr.call{ value: deflctDevETHFee }("");
    require(pixelDevETHTransferSuccess && deflectDevETHTransferSuccess, "Dev eth transfer failed");

    IUniswapV2Pair pixelETHPair = IUniswapV2Pair(tokenUniswapPairETH);

    // Transfer remaining eth liquidity to the pair
    IWETH(WETH).transfer(address(pixelETHPair), ETHRemaining);
    // Transfer the pixel liquidity to the pair
    pixelToken.transfer(address(pixelETHPair), pixelInitialLiq);

    // Mint tokens here.
    pixelETHPair.mint(address(this));

    // Book-keep the total
    totalETHLPTokensMinted = pixelETHPair.balanceOf(address(this));
    require(totalETHLPTokensMinted != 0, "LP creation failed");

    // For user distribution
    ETHLPperETHUnit = totalETHLPTokensMinted.mul(1e18).div(totalETHContributed);
    require(ETHLPperETHUnit != 0, "LP creation failed");
  }

  // Create PIX/DEFLCT LP
  function addLiquidityToDEFLCTUniswapPair() internal {
    require(now >= lgeEndTime, "Liquidity generation ongoing");
    require(LPGenerationCompleted == false, "Liquidity generation already finished");
    if (_msgSender() != owner()) {
      require(now > (lgeEndTime + 2 hours), "Please wait for dev grace period");
    }

    IUniswapV2Pair defPair = IUniswapV2Pair(tokenUniswapPairDEFLCT);

    // Send deflect tokens to pair
    IERC20(DEFLCT).transfer(address(defPair), IERC20(DEFLCT).balanceOf(address(this)));

    // Send pixel tokens to pair
    pixelToken.transfer(address(defPair), deflectInitialLiq);

    // Mint LP's here.
    defPair.mint(address(this));

    // Book-keep
    totalDEFLCTLPTokensMinted = defPair.balanceOf(address(this));
    require(totalDEFLCTLPTokensMinted != 0, "DEFLCT LP creation failed");

    // What's being shared per user contributed.
    DEFLCTLPperETHUnit = totalDEFLCTLPTokensMinted.mul(1e18).div(totalETHContributed); // 1e9x for change
    require(DEFLCTLPperETHUnit != 0, "DEFLCT LP creation failed");
  }

  function addLiquidityToUniswap() public onlyOwner {
    addLiquidityETHToUniswapPair();
    addLiquidityToDEFLCTUniswapPair();

    // Bonus tokens being distributed per wei.
    bonusTokenPerETHUnit = bonusTokens.mul(1e18).div(totalETHContributed);
    require(bonusTokenPerETHUnit != 0, "Token calculation failed");

    LPGenerationCompleted = true;
  }

  function claimLPTokens() public {
    require(now >= lpUnlockTime, "LP not unlocked yet");
    require(LPGenerationCompleted, "Event not over yet");
    require(ethContributedForLPTokens[msg.sender] > 0, "Nothing to claim, move along");

    IUniswapV2Pair ethpair = IUniswapV2Pair(tokenUniswapPairETH);
    uint256 amountETHLPToTransfer = ethContributedForLPTokens[msg.sender].mul(ETHLPperETHUnit).div(1e18);
    ethpair.transfer(msg.sender, amountETHLPToTransfer); // stored as 1e18x value for change

    IUniswapV2Pair defpair = IUniswapV2Pair(tokenUniswapPairDEFLCT);
    uint256 amountDEFLCTLPToTransfer = ethContributedForLPTokens[msg.sender].mul(DEFLCTLPperETHUnit).div(1e18);
    defpair.transfer(msg.sender, amountDEFLCTLPToTransfer); // stored as 1e18x value for change

    ethContributedForLPTokens[msg.sender] = 0;
    emit totalLPTokenClaimed(msg.sender, amountETHLPToTransfer, amountDEFLCTLPToTransfer);
  }

  function claimTokens() public {
    require(now >= lpUnlockTime, "LP not unlocked yet");
    require(LPGenerationCompleted, "Event not over yet");
    require(ETHContributedForBonusTokens[msg.sender] > 0, "Nothing to claim, move along");
    uint256 amountTokenToTransfer = ETHContributedForBonusTokens[msg.sender].mul(bonusTokenPerETHUnit).div(1e18);


    pixelToken.transfer(msg.sender, amountTokenToTransfer); // stored as 1e18x value for change
    ETHContributedForBonusTokens[msg.sender] = 0;
    emit TokenClaimed(msg.sender, amountTokenToTransfer);
  }

  function emergencyRecoveryIfLiquidityGenerationEventFails() public onlyOwner {
    require(lgeEndTime.add(1 days) < now, "Liquidity generation grace period still ongoing");
    (bool success, ) = msg.sender.call{ value: address(this).balance }("");
    IERC20(DEFLCT).transfer(msg.sender, IERC20(DEFLCT).balanceOf(address(this)));
    require(success, "Transfer failed.");
  }

  function setPixelDev(address _pixelDevAddr) public {
    require(_msgSender() == pixelDevAddr, "!pixel dev");
    pixelDevAddr = _pixelDevAddr;
  }

  function setDeflctDev(address _deflctDevAddr) public {
    require(_msgSender() == deflctDevAddr, "!deflect dev");
    deflctDevAddr = _deflctDevAddr;
  }
}
