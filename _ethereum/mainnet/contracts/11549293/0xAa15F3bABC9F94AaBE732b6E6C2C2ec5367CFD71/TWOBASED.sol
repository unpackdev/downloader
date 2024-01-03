// File: @openzeppelin/contracts-ethereum-package/contracts/utils/SafeCast.sol

pragma solidity ^0.6.0;


/**
 * @dev Wrappers over Solidity's uintXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.6.0;


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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol

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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


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

    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
}

// File: contracts/TWOBASED.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20UpgradeSafe is Initializable, ContextUpgradeSafe, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */

    function __ERC20_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
    }

    function __ERC20_init_unchained(string memory name, string memory symbol) internal initializer {


        _name = name;
        _symbol = symbol;
        _decimals = 18;

    }


    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "zero address");
        require(recipient != address(0), "zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "zero address");
        require(spender != address(0), "zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    uint256[44] private __gap;
}

/*
 *
 * Copyright 2020 2based.finance. ALL RIGHTS RESERVED.
 *
 */


contract TWOBASED is ERC20UpgradeSafe, OwnableUpgradeSafe {

	// PLEASE READ BEFORE CHANGING ANY ACCOUNTING OR MATH
    // Anytime there is division, there is a risk of numerical instability from rounding errors. In
    // order to minimize this risk, we adhere to the following guidelines:
    // 1) The conversion rate adopted is the number of gons that equals 1 fragment.
    //    The inverse rate must not be used--TOTAL_GONS is always the numerator and _totalSupply is
    //    always the denominator. (i.e. If you want to convert gons to fragments instead of
    //    multiplying by the inverse rate, you should divide by the normal rate)
    // 2) Gon balances converted into Fragments are always rounded down (truncated).
    //
    // We make the following guarantees:
    // - If address 'A' transfers x Fragments to address 'B'. A's resulting external balance will
    //   be decreased by precisely x Fragments, and B's external balance will be precisely
    //   increased by x Fragments.
    //
    // We do not guarantee that the sum of all balances equals the result of calling totalSupply().
    // This is because, for any conversion function 'f()' that has non-zero rounding error,
    // f(x0) + f(x1) + ... + f(xn) is not always equal to f(x0 + x1 + ... xn).
	

    using SafeMath for uint256;
    using SafeCast for int256;
    using Address for address;
	
	struct Transaction {
        bool enabled;
        address destination;
        bytes data;
    }

    event TransactionFailed(address indexed destination, uint index, bytes data);
	
	// Stable ordering is not guaranteed.

    Transaction[] public transactions;

    event Rebase(uint256 indexed epoch, uint256 priceUSD, int256 rebasePercent, uint256 totalSupply, uint8 jackpotLevel);

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1 * 10**6 * 10**DECIMALS;

	// TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

	// MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1
	
	uint256 private _epoch;

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;
	
	// This is denominated in Fragments, because the gons-fragments conversion might change before
    // it's fully paid.
    mapping (address => mapping (address => uint256)) private _allowedFragments;
    
    address public _router;
    
    address public _tokenQuote;
    address public _tokenUSD;
    
    uint256 public _rebasingPriceUSD;
    uint256 public _rebasingPriceLastBlock;
    
    bool public _rebasingPriceUseCurrent;
    
    uint256 public _limitExpiresTimestamp;
    uint256 public _limitTransferAmount;
    uint256 public _limitMaxBalance;
    uint256 public _limitSellFeePercent;
    
    uint256 public _limitTimestamp;
    
    bool public _rebasePaused;
    
    int256 public _rebasePositivePercent;
    uint256 public _rebasePositivePriceUSD;
    
    int256 public _rebaseNegativePercent;
    uint256 public _rebaseNegativePriceUSD;
    
    uint256 public _rebaseTokensMinSupplyPercent;
    
    uint256 public _rebaseNextTimestamp;
    uint256 public _rebaseNextSeconds;
    
    uint8 public _rebaseJackpotLevel;
    uint256 public _rebaseJackpotLastBlock;
    
    uint256 public _rebaseJackpotRewardDivisor;
    
    uint256 public _rebaseLastPriceUSD;
    uint256 public _rebasingPriceStartBlock;
    uint256 public _rebaseLastPriceUSDCumulative;
    
    uint256 public _rebaseOptionsTimestamp;
    
    mapping (address => bool) private _isExchanger;
    mapping (address => bool) private _isDistributor;
    
    address public _vault;
    
    uint256 public _sellFeePercent;
    address public _sellFeeAddress;
    
    uint256 public _sellFeeTimestamp;
    

    function initialize(uint256 initialSupply, address router, address tokenQuote, address tokenUSD, address team, address dev, address eco, address vault) public initializer
    {
        __ERC20_init("2based.finance", "2BASED");
        _setupDecimals(uint8(DECIMALS));
        __Ownable_init();
        
        _totalSupply = initialSupply;
        _gonBalances[_msgSender()] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        
        _router = router;
        
        _tokenQuote = tokenQuote;
        _tokenUSD = tokenUSD;
        
        _vault = vault;
        
        _sellFeePercent = 200; //2%
        _sellFeeAddress = vault;
        
        _rebasePositivePercent = 200;
        _rebasePositivePriceUSD = 2 * 10**6;
    
        _rebaseNegativePercent = -200;
        _rebaseNegativePriceUSD = 1 * 10**6;
        
        _rebaseTokensMinSupplyPercent = 100; // Precision 4 eg. 1 = 0.0001, 10 = 0.001 %
        
        _rebaseNextSeconds = 1342; // 22:22, 22 minutes 22 seconds
        
        _rebaseJackpotRewardDivisor = 2;
        
        setDistributor(_msgSender(), true);
        setDistributor(team, true);
        setDistributor(dev, true);
        setDistributor(eco, true);
        setDistributor(vault, true);
        
        //multisender
        setDistributor(address(0xA5025FABA6E70B84F74e9b1113e5F7F4E7f4859f), true);
        setDistributor(address(0xE7BD68547F41413A6bAa7609550A7eB58C84c406), true);

        emit Transfer(address(0x0), _msgSender(), _totalSupply);
    }

    function rebase()
        external
        returns (uint256)
    {
        require(!_rebasePaused, "Paused");
        require(_rebaseJackpotLevel != 10, "Paused until rewards released");
        require(now >= _rebaseNextTimestamp, "Countdown > 0");
        require(balanceOf(_msgSender()) >= getMinTokensToRebase(), "Sender must hold a minimum number of tokens to rebase");
	   
	    uint256 priceUSD = _internalRebasingPriceUSD();
	   
	    require(priceUSD < _rebaseNegativePriceUSD || priceUSD > _rebasePositivePriceUSD, "Err: Rebasing range");
	    
	    uint256 totalSupplyNew = _totalSupply;
	    int256 rebasePercent = 0;
	   
	    if(priceUSD > _rebasePositivePriceUSD) {
	        rebasePercent = _rebasePositivePercent;
	    }
	   
	    if(priceUSD < _rebaseNegativePriceUSD) {
	        rebasePercent = _rebaseNegativePercent;
	    }	        
	   	
	   	totalSupplyNew = _totalSupply.mul((10000 + rebasePercent).toUint256()).div(10000);

        if (totalSupplyNew > MAX_SUPPLY) {
            totalSupplyNew = MAX_SUPPLY;
        }
        
        _epoch = _epoch.add(1);
        _totalSupply = totalSupplyNew;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        
		// From this point forward, _gonsPerFragment is taken as the source of truth.
        // We recalculate a new _totalSupply to be in agreement with the _gonsPerFragment
        // conversion rate.
        // This means our applied supplyDelta can deviate from the requested supplyDelta,
        // but this deviation is guaranteed to be < (_totalSupply^2)/(TOTAL_GONS - _totalSupply).
        //
        // In the case of _totalSupply <= MAX_UINT128 (our current supply cap), this
        // deviation is guaranteed to be < 1, so we can omit this step. If the supply cap is
        // ever increased, it must be re-included.
        // _totalSupply = TOTAL_GONS.div(_gonsPerFragment)      
        
        _rebaseNextTimestamp = now + _rebaseNextSeconds;
        
        if (priceUSD > _rebasePositivePriceUSD && priceUSD > _rebaseLastPriceUSD && _rebaseLastPriceUSD > 0) {
            _rebaseJackpotLevel++;
            if(_rebaseJackpotLevel == 10) {
                _rebaseJackpotLastBlock = block.number;
                _rebaseNextTimestamp = now + 24 hours;
            }
        } else {
            _rebaseJackpotLevel = 0;
        }

		for (uint i = 0; i < transactions.length; i++) {
            Transaction storage t = transactions[i];
            if (t.enabled) {
                bool result = externalCall(t.destination, t.data);
                if (!result) {
                    emit TransactionFailed(t.destination, i, t.data);
                    revert("Transaction Failed");
                }
            }
        }
        
        emit Rebase(_epoch, priceUSD, rebasePercent, _totalSupply, _rebaseJackpotLevel);
        
        _rebaseLastPriceUSD = _rebasePositivePriceUSD; //priceUSD;
        _resetRebasingPrice();
		
        return _totalSupply;
    }

    function setRebaseOptions(
    
        bool rebasePaused, 
        int256 rebasePositivePercent,
        uint256 rebasePositivePriceUSD, 
        int256 rebaseNegativePercent,
        uint256 rebaseNegativePriceUSD,
        bool rebasingPriceUseCurrent,
        uint256 rebaseTokensMinSupplyPercent,
        uint256 rebaseNextTimestamp,
        uint256 rebaseNextSeconds,
        uint8 rebaseJackpotLevel,
        uint256 rebaseJackpotLastBlock,
        uint256 rebaseJackpotRewardDivisor,
        uint256 rebaseLastPriceUSD
        
        ) external onlyOwner() {
        
        if(rebasePaused != _rebasePaused) _rebasePaused = rebasePaused;
        
        if(rebasePositivePercent != _rebasePositivePercent) _rebasePositivePercent = rebasePositivePercent;
        
        if(rebasePositivePriceUSD != _rebasePositivePriceUSD) _rebasePositivePriceUSD = rebasePositivePriceUSD;
        
        if(rebaseNegativePercent != _rebaseNegativePercent) _rebaseNegativePercent = rebaseNegativePercent;
        
        if(rebaseNegativePriceUSD != _rebaseNegativePriceUSD) _rebaseNegativePriceUSD = rebaseNegativePriceUSD;
        
        if(rebasingPriceUseCurrent != _rebasingPriceUseCurrent) _rebasingPriceUseCurrent = rebasingPriceUseCurrent;
        
        if(rebaseTokensMinSupplyPercent != _rebaseTokensMinSupplyPercent) _rebaseTokensMinSupplyPercent = rebaseTokensMinSupplyPercent;
        
        if(rebaseNextTimestamp != _rebaseNextTimestamp) _rebaseNextTimestamp = rebaseNextTimestamp;
        
        if(rebaseNextSeconds != _rebaseNextSeconds) _rebaseNextSeconds = rebaseNextSeconds;
        
        if(rebaseJackpotLevel != _rebaseJackpotLevel) _rebaseJackpotLevel = rebaseJackpotLevel;
        
        if(rebaseJackpotLastBlock != _rebaseJackpotLastBlock) _rebaseJackpotLastBlock = rebaseJackpotLastBlock;
        
        if(rebaseJackpotRewardDivisor != _rebaseJackpotRewardDivisor && rebaseJackpotRewardDivisor > 0) _rebaseJackpotRewardDivisor = rebaseJackpotRewardDivisor;
        
        if(rebaseLastPriceUSD != _rebaseLastPriceUSD) _rebaseLastPriceUSD = rebaseLastPriceUSD;
        
        _rebaseOptionsTimestamp = now;
    }

    function beforeLaunch(uint256 rebaseFirstTimestamp, uint256 limitExpiresTimestamp, uint256 limitTransferAmount, uint256 limitMaxBalance, uint256 limitSellFeePercent) public onlyOwner() {
        _rebaseJackpotLevel = 0;
        _rebaseNextTimestamp = rebaseFirstTimestamp;
        _rebaseLastPriceUSD = _rebasePositivePriceUSD;
        setLimit(limitExpiresTimestamp, limitTransferAmount, limitMaxBalance, limitSellFeePercent);
    }
    
    function afterLaunch() public onlyOwner() {
        _resetRebasingPrice();
    }
    
    function resetJackpot() public onlyOwner() {
        _rebaseJackpotLevel = 0;
        _rebaseNextTimestamp = now + _rebaseNextSeconds;
        _rebaseLastPriceUSD = _rebasePositivePriceUSD;
        _resetRebasingPrice();
    }
    
    function _resetRebasingPrice() internal {
        _rebasingPriceStartBlock = block.number;
        _rebaseLastPriceUSDCumulative = 0;
        _rebasingPriceLastBlock = block.number;   
    }
    
    function setVault(address vault) external onlyOwner() {
        _vault = vault;
    }
    
    function setSellFee(uint256 sellFeePercent, address sellFeeAddress) external onlyOwner() {
        
        _sellFeePercent = sellFeePercent;
        _sellFeeAddress = sellFeeAddress;
        
        _sellFeeTimestamp = now;
    }
    
    function setLimit(uint256 expiresTimestamp, uint256 transferAmount, uint256 maxBalance, uint256 sellFeePercent) public onlyOwner() {
        
        _limitExpiresTimestamp = expiresTimestamp;
        _limitTransferAmount = transferAmount;
        _limitMaxBalance = maxBalance;
        _limitSellFeePercent = sellFeePercent;

        _limitTimestamp = now;
    }
    
    function setExchanger(address account, bool exchanger) public onlyOwner() {
        _isExchanger[account] = exchanger;
    }
    
    function setDistributor(address account, bool distributor) public onlyOwner() {
        _isDistributor[account] = distributor;
    }
    
    function setUniswapRouter(address router) external onlyOwner
    {
        require(address(router) != address(0));
        
        _router = router;
    }
    
    function setTokenUSD(address token) external onlyOwner
    {
        require(address(token) != address(0));
        
        _tokenUSD = token;
    }
    
    function _internalRebasingPriceUSD() internal returns (uint256) {
        
        uint256 priceUSD;
        
        if(_rebasingPriceUseCurrent) {
            (priceUSD,) = getPrices();
            return priceUSD;
        } else {
        
            if(block.number > _rebasingPriceLastBlock) {
                
                (priceUSD,) = getPrices();
                
                if(_rebasingPriceStartBlock == 0) _rebasingPriceStartBlock = block.number;
                
                uint256 blocksSinceRebasingPriceStartBlock = block.number - _rebasingPriceStartBlock;
                if(blocksSinceRebasingPriceStartBlock > 0) {
                    uint256 blocksDiff = (_rebasingPriceLastBlock == 0 ? 0 : block.number - _rebasingPriceLastBlock);
                    _rebaseLastPriceUSDCumulative = _rebaseLastPriceUSDCumulative.add(blocksDiff.mul(priceUSD));
                    _rebasingPriceUSD = _rebaseLastPriceUSDCumulative.div(blocksSinceRebasingPriceStartBlock);
                } else {
                    _rebasingPriceUSD = priceUSD;
                }
                
                _rebasingPriceLastBlock = block.number;
                
            }
            
        }
        
        return _rebasingPriceUSD;

    }
    
    function externalRebasingPriceUSD() public view returns (uint256) {
        
        (uint256 priceUSD,) = getPrices();
        
        uint256 rebasingPriceUSD = priceUSD;
        
        if(!_rebasingPriceUseCurrent) {
        
            uint256 blocksSinceRebasingPriceStartBlock = (block.number - _rebasingPriceStartBlock)+1;
            
            uint256 blocksDiff = (_rebasingPriceLastBlock == 0 ? 0 : (block.number - _rebasingPriceLastBlock)+1);
    
            rebasingPriceUSD = _rebaseLastPriceUSDCumulative.add(blocksDiff.mul(priceUSD)).div(blocksSinceRebasingPriceStartBlock);
        
        }
        
        return rebasingPriceUSD;
        
    }
    
    function getJackpotValueUSD() public view returns (uint256) {
        require(_rebaseJackpotRewardDivisor > 0, "Reward Divisor must be > 0");
        
        uint256 amount = balanceOf(_vault).div(_rebaseJackpotRewardDivisor);
        (uint256 priceUSD,) = getPrices();
        return amount.mul(priceUSD).div(10**DECIMALS);
    }
    
    /**
     * info() - called by frontend
     * 
     * Returns :
     * 
     * - $ price of 2BASED used for rebasing (6 DECIMALS)
     * - current $ price of 2BASED (6 DECIMALS)
     * - current ETH price of 2 BASED (18 DECIMALS)
     * - next rebase UTC timestamp (seconds)
     * - $ price of 2BASED at last rebase (6 DECIMALS)
     * - senders balance of 2BASED (9 DECIMALS)
     * - minimum sender balance of 2BASED required to call rebase() (9 DECIMALS)
     * - current jackpot level (0-10)
     * - current jackpot $ value (6 DECIMALS)
     * - block number last jockpot was hit
     * 
     */
    
    function info() public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint8, uint256, uint256) {
        (uint256 priceUSD, uint256 priceETH) = getPrices();
        return (externalRebasingPriceUSD(), priceUSD, priceETH, _rebaseNextTimestamp, _rebaseLastPriceUSD, balanceOf(_msgSender()), getMinTokensToRebase(), _rebaseJackpotLevel, getJackpotValueUSD(), _rebaseJackpotLastBlock);
    }

    
    function getMinTokensToRebase() public view returns (uint256) {
        return _totalSupply.mul(_rebaseTokensMinSupplyPercent).div(1000000); // 4dp
    }
    
    
    function getPrices() public view returns (uint256, uint256) {
        
        address[] memory path = new address[](3);
        
        path[0] = address(this);
        path[1] = _tokenQuote;
        path[2] = _tokenUSD;

        uint256[] memory prices = IUniswapV2Router02(_router).getAmountsOut(10**DECIMALS, path);
        
        require(prices.length == 3, "Error retreiving current prices");
        
        return (prices[2], prices[1]);
    }
    
	/**
     * @return The total number of fragments.
     */

    function totalSupply()
        public
        view
        override
        returns (uint256)
    {
        return _totalSupply;
    }
	
	/**
     * @param who The address to query.
     * @return The balance of the specified address.
     */

    function balanceOf(address who)
        public
        view
        override
        returns (uint256)
    {
        return _gonBalances[who].div(_gonsPerFragment);
    }

	/**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
	 
    function allowance(address owner_, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }
    
    
    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
	 
    function transfer(address to, uint256 value)
        public
        validRecipient(to)
        override
        returns (bool)
    {
        _transfer(_msgSender(), to, value);
        return true;
    }
	
	/**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */

    function transferFrom(address from, address to, uint256 value)
        public
        validRecipient(to)
        override
        returns (bool)
    {
        _allowedFragments[from][_msgSender()] = _allowedFragments[from][_msgSender()].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount)
        internal
        override
    {
        uint256 sellFeeAmount = 0;
        uint256 transferAmount = amount;
        
        //no fees for distributors
        if(!_isDistributor[sender] && !_isDistributor[recipient]) {
        
            //no fees between exchangers
            if(!(_isExchanger[sender] && _isExchanger[recipient])) {
                
                if(_limitExpiresTimestamp >= now) {
                    require(amount <= _limitTransferAmount, "Initial Uniswap listing - amount exceeds transfer limit");
                    require(balanceOf(recipient).add(amount) <= _limitMaxBalance, "Initial Uniswap listing - max balance limit");
                }
                
                if(!_isExchanger[sender] && _isExchanger[recipient]) {
                    //selling
    
                    if(_limitExpiresTimestamp >= now) {
                        sellFeeAmount = amount.mul(_limitSellFeePercent).div(10000);
                    } else {
                        sellFeeAmount = amount.mul(_sellFeePercent).div(10000);
                    }
                } else if (!_isExchanger[sender] && !_isExchanger[recipient]) {
                    require(_limitExpiresTimestamp < now, "Initial Uniswap listing - Wallet to Wallet transfers temporarily disabled");
                }
                
                
                if((_isExchanger[sender] && !_isExchanger[recipient]) || (!_isExchanger[sender] && _isExchanger[recipient])) {
                    //buying or selling
                    uint256 rebasingPriceUSD = _internalRebasingPriceUSD();
                    (uint256 priceUSD,) = getPrices();
                    
                    if(now > _rebaseNextTimestamp) {
                        
                        if(rebasingPriceUSD < _rebasePositivePriceUSD && priceUSD >= _rebasePositivePriceUSD) {
                            
                            _rebaseJackpotLevel = 0;
                            
                            _rebaseNextTimestamp = now + _rebaseNextSeconds;
                            _rebaseLastPriceUSD = _rebasePositivePriceUSD;
                            
                            _resetRebasingPrice();
                            
                        } else if (rebasingPriceUSD > _rebaseNegativePriceUSD && priceUSD <= _rebaseNegativePriceUSD){

                            _rebaseNextTimestamp = now + _rebaseNextSeconds;
                            _rebaseLastPriceUSD = _rebaseNegativePriceUSD;
                            
                            _resetRebasingPrice();
                        }
                        
                    }
                }
            }
        }
        
        if(sellFeeAmount > 0) {
            
            transferAmount = amount.sub(sellFeeAmount);
            uint256 sellFeeGonValue = sellFeeAmount.mul(_gonsPerFragment);
            
             _gonBalances[_sellFeeAddress] = _gonBalances[_sellFeeAddress].add(sellFeeGonValue);
             emit Transfer(sender, _sellFeeAddress, sellFeeAmount);
        }
        
        
        uint256 amountGonValue = amount.mul(_gonsPerFragment);
        uint256 transferAmountGonValue = transferAmount.mul(_gonsPerFragment);
        
        _gonBalances[sender] = _gonBalances[sender].sub(amountGonValue);
        _gonBalances[recipient] = _gonBalances[recipient].add(transferAmountGonValue);
        
        emit Transfer(sender, recipient, transferAmount);
        
    }
	
	/**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * _msgSender(). This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */

    function approve(address spender, uint256 value)
        public
        override
        returns (bool)
    {
        _allowedFragments[_msgSender()][spender] = value;
        emit Approval(_msgSender(), spender, value);
        return true;
    }
	
	/**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        returns (bool)
    {
        _allowedFragments[_msgSender()][spender] =
            _allowedFragments[_msgSender()][spender].add(addedValue);
        emit Approval(_msgSender(), spender, _allowedFragments[_msgSender()][spender]);
        return true;
    }
	
	/**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[_msgSender()][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[_msgSender()][spender] = 0;
        } else {
            _allowedFragments[_msgSender()][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(_msgSender(), spender, _allowedFragments[_msgSender()][spender]);
        return true;
    }
	
	/**
     * @notice Adds a transaction that gets called for a downstream receiver of rebases
     * @param destination Address of contract destination
     * @param data Transaction data payload
     */
	
    function addTransaction(address destination, bytes memory data)
        external
        onlyOwner
    {
        transactions.push(Transaction({
            enabled: true,
            destination: destination,
            data: data
        }));
    }
	
	/**
     * @param index Index of transaction to remove.
     *              Transaction ordering may have changed since adding.
     */

    function removeTransaction(uint index)
        external
        onlyOwner
    {
        require(index < transactions.length, "index out of bounds");

        if (index < transactions.length - 1) {
            transactions[index] = transactions[transactions.length - 1];
        }

        transactions.pop();
    }
	
	/**
     * @param index Index of transaction. Transaction ordering may have changed since adding.
     * @param enabled True for enabled, false for disabled.
     */

    function setTransactionEnabled(uint index, bool enabled)
        external
        onlyOwner
    {
        require(index < transactions.length, "index must be in range of stored tx list");
        transactions[index].enabled = enabled;
    }
	
	/**
     * @return Number of transactions, both enabled and disabled, in transactions list.
     */

    function transactionsSize()
        external
        view
        returns (uint256)
    {
        return transactions.length;
    }
	
	/**
     * @dev wrapper to call the encoded transactions on downstream consumers.
     * @param destination Address of destination contract.
     * @param data The encoded data payload.
     * @return True on success
     */

    function externalCall(address destination, bytes memory data)
        internal
        returns (bool)
    {
        bool result;
        assembly {  // solhint-disable-line no-inline-assembly
            // "Allocate" memory for output
            // (0x40 is where "free memory" pointer is stored by convention)
            let outputAddress := mload(0x40)

            // First 32 bytes are the padded length of data, so exclude that
            let dataAddress := add(data, 32)

            result := call(
                // 34710 is the value that solidity is currently emitting
                // It includes callGas (700) + callVeryLow (3, to pay for SUB)
                // + callValueTransferGas (9000) + callNewAccountGas
                // (25000, in case the destination address does not exist and needs creating)
                sub(gas(), 34710),


                destination,
                0, // transfer value in wei
                dataAddress,
                mload(data),  // Size of the input, in bytes. Stored in position 0 of the array.
                outputAddress,
                0  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }
    
	/**
     * refund any ERC20 tokens sent to contract by mistake
     */
    function transferERC20(IERC20 token, uint256 amount, address to) public onlyOwner returns (bool) {
        require(token.balanceOf(address(this)) >= amount,"Insufficent balance to transfer token amount.");
        return token.transfer(to, amount);
    }
}
