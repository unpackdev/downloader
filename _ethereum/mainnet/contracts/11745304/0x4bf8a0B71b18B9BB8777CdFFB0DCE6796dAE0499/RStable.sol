// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin\contracts\math\SafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin\contracts\utils\Address.sol



pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// File: node_modules\@openzeppelin\contracts\GSN\Context.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin\contracts\access\Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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

// File: contracts\external\IUniswapV2Factory.sol

pragma solidity >=0.6.2;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: contracts\external\IUniswapV2Router01.sol

pragma solidity >=0.6.2;

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

// File: contracts\external\IUniswapV2Router02.sol

pragma solidity >=0.6.2;


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

// File: contracts\external\IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint256);
}

// File: contracts\Constants.sol



pragma solidity ^0.6.12;
// pragma experimental ABIEncoderV2;

library Constants {
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _launchSupply = 164000 * 10**9;
    uint256 private constant _largeTotal = (MAX - (MAX % _launchSupply));


    // uint256 private constant _baseExpansionFactor = 100;
    // uint256 private constant _baseContractionFactor = 100;
    uint256 private constant _baseUtilityFee = 50; // 0.5%
    // uint256 private constant _baseContractionCap = 1000;

    uint256 private constant _stabilizerFee = 50; // 0.5%
    // uint256 private constant _stabilizationLowerBound = 50;
    // uint256 private constant _stabilizationLowerReset = 75;
    // uint256 private constant _stabilizationUpperBound = 150;
    // uint256 private constant _stabilizationUpperReset = 125;
    // uint256 private constant _stabilizePercent = 10;

    uint256 private constant _treasuryFee = 100; // 1%

    // uint256 private constant _presaleIndividualCap = 1 ether;
    // uint256 private constant _presaleCap = 1 * 10**5 * 10**18;
    // uint256 private constant _maxPresaleGas = 200000000000;

    uint256 private constant _epochLength = 4 hours;

    uint256 private constant _liquidityReward = 25 * 10**9;
    uint256 private constant _minForLiquidity = 500 * 10**9;
    uint256 private constant _minForCallerLiquidity = 500 * 10**9;

    address private constant _treasuryAddress = 0xf7FBdEA9b0e7aF8034f9Fc99D7d95B4D4a52B948;

    string private constant _name = "RSTABLE";
    string private constant _symbol = "RST";
    uint8 private constant _decimals = 9;
    uint256 public constant twoYearSec = 63072000;

    uint256 private constant _addLiquidRate = 64000/80;

    /****** Getters *******/
    function getAddLiquidRate() internal pure returns (uint256){
        return _addLiquidRate;
    }
    function getLaunchSupply() internal pure returns (uint256) {
        return _launchSupply;
    }
    function getLargeTotal() internal pure returns (uint256) {
        return _largeTotal;
    }

   
    function getBaseUtilityFee() internal pure returns (uint256) {
        return _baseUtilityFee;
    }
    function getStabilizerFee() internal pure returns (uint256) {
        return _stabilizerFee;
    }
    
    function getTreasuryFee() internal pure returns (uint256) {
        return _treasuryFee;
    }
    function getEpochLength() internal pure returns (uint256) {
        return _epochLength;
    }
    function getLiquidityReward() internal pure returns (uint256) {
        return _liquidityReward;
    }
    function getMinForLiquidity() internal pure returns (uint256) {
        return _minForLiquidity;
    }
    function getMinForCallerLiquidity() internal pure returns (uint256) {
        return _minForCallerLiquidity;
    }

    
    function getTreasuryAdd() internal pure returns (address) {
        return _treasuryAddress;
    }
    function getName() internal pure returns (string memory)  {
        return _name;
    }
    function getSymbol() internal pure returns (string memory) {
        return _symbol;
    }
    function getDecimals() internal pure returns (uint8) {
        return _decimals;
    }
}

// File: contracts\State.sol



pragma solidity ^0.6.12;

contract State {

    mapping (address => uint256) _largeBalances;
    mapping (address => mapping (address => uint256)) _allowances;

    // Supported pools and data for measuring mint & burn factors
    struct PoolCounter {
        address pairToken;
        uint256 tokenBalance;
        uint256 pairTokenBalance;
        uint256 lpBalance;
        uint256 startTokenBalance;
        uint256 startPairTokenBalance;
    }
    address[] _supportedPools;
    mapping (address => PoolCounter) _poolCounters;
    mapping (address => bool) _isSupportedPool;
    address _mainPool;

    uint256 public _currentEpoch;
 
    uint256 _largeTotal;
    uint256 _totalSupply;

    address _liquidityReserve = 0xa0DA83FcB4d921E966C67E747cDd66c4D60bB074;
    address _stabilizer = 0xa0DA83FcB4d921E966C67E747cDd66c4D60bB074;
    address uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address uniswapFac = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    bool _taxLess;
    bool _presaleDone;
    address public presaleAdd;
    address public pol;

    uint256 public advanceMinThreshold = 512; // random range [0:1023], if number is >=511, < 512, advance.
    uint256 public advanceMaxThreshold = 513; 
    uint256 public advanceLotteryBits = 10; // 1024
    uint256 public maxEpochLength = 4 hours;
    uint256 public lastCalculatedBlock;
    uint256 public txNum;
    /*
        Based on assumption of 1 txes every 15secs, over 1hour, there are 240 txes
        There is 23% of trigger within the first hour
        There is 46% of trigger within the first 2 hours
        There is 70% of trigger within the first 3 hours
        There is 93% of trigger within the first 4 hours
    */
    // all sacled by 100,000
    uint256 public minBurnRate = 1000; //1%
    uint256 public maxBurnRate = 10000; //10%
    uint256 public minMintRate = 1000; //1%
    uint256 public maxMintRate = 8000; //8%

    bool public isBootstrap = true;
    uint256 public numEpochs = 0;
    uint256 public bootstrapEnd = 30;

    uint256 public mintRateOffset = 0;
    uint256 public burnRateOffset = 0;
    uint256 public lastMintRate;

    mapping(address=>bool) _isTaxlessSetter;
}

// File: contracts\Getters.sol



pragma solidity ^0.6.12;
// pragma experimental ABIEncoderV2;

// import "./SafeMathUpgradeable.sol";

// import "./AddressUpgradeable.sol";






contract Getters is State {
    using SafeMath for uint256;
    using Address for address;

    function getLargeBalances(address account) public view returns (uint256) {
        return _largeBalances[account];
    }
    function getAllowances(address account, address spender) public view returns (uint256) {
        return _allowances[account][spender];
    } 
    function getSupportedPools(uint256 index) public view returns (address) {
        return _supportedPools[index];
    }
    function getPoolCounters(address pool) public view returns (address, uint256, uint256, uint256, uint256, uint256) {
        PoolCounter memory pc = _poolCounters[pool];
        return (pc.pairToken, pc.tokenBalance, pc.pairTokenBalance, pc.lpBalance, pc.startTokenBalance, pc.startPairTokenBalance);
    }
    function isSupportedPool(address pool) public view returns (bool) {
        return _isSupportedPool[pool];
    }
    function mainPool() public view returns (address) {
        return _mainPool;
    }
    function getCurrentEpoch() public view returns (uint256) {
        return _currentEpoch;
    }
    
    function getLargeTotal() public view returns (uint256) {
        return _largeTotal;
    }
    function getTotalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function getLiquidityReserve() public view returns (address) {
        return _liquidityReserve;
    }
    function getPol() public view returns (address) {
        return pol;
    }
    function getStabilizer() public view returns (address) {
        return _stabilizer;
    }
    function isPresaleDone() public view returns (bool) {
        return _presaleDone;
    }
    // function getPresaleAddress() public view returns (address) {
    //     return _presaleCon;
    // }
   
    function isTaxLess() public view returns (bool) {
        return _taxLess;
    }
    function isTaxlessSetter(address account) public view returns (bool) {
        return _isTaxlessSetter[account];
    }
    function getUniswapRouter() public view returns (IUniswapV2Router02) {
        return IUniswapV2Router02(uniswapRouter);
    }
    function getUniswapFactory() public view returns (IUniswapV2Factory) {
        return IUniswapV2Factory(uniswapFac);
    }
    function getFactor() public view returns(uint256) {
        if (_presaleDone) {
            return _largeTotal.div(_totalSupply);
        } else {
            return _largeTotal.div(Constants.getLaunchSupply());
        }
    }
    function getUpdatedPoolCounters(address pool, address pairToken) public view returns (uint256, uint256, uint256) {
        uint256 lpBalance = IERC20(pool).totalSupply();
        uint256 tokenBalance = IERC20(address(this)).balanceOf(pool);
        uint256 pairTokenBalance = IERC20(address(pairToken)).balanceOf(pool);
        return (tokenBalance, pairTokenBalance, lpBalance);
    }
    function getExpansionRate(address poolAdd) public view returns (uint256) {
        uint256 expansionR = (_poolCounters[poolAdd].pairTokenBalance).mul(_poolCounters[poolAdd].startTokenBalance).mul(100000).div(_poolCounters[poolAdd].startPairTokenBalance).div(_poolCounters[poolAdd].tokenBalance);
        
        if (expansionR > 100000){ // more than 100percent
            expansionR = expansionR.mul(expansionR).div(100000);
            uint256 delta = expansionR - 100000;
            delta = delta + mintRateOffset;

            return (delta > maxMintRate) ? maxMintRate : delta;
           
        }else{
            return minMintRate;
        }
    }
    function getContractionRate(address poolAdd) public view returns (uint256) {
        uint256 contractionR = (_poolCounters[poolAdd].tokenBalance).mul(_poolCounters[poolAdd].startPairTokenBalance).mul(100000).div(_poolCounters[poolAdd].pairTokenBalance).div(_poolCounters[poolAdd].startTokenBalance);
        
        if (contractionR > 100000){ // more than 100percent
            contractionR = contractionR.mul(contractionR).div(100000);
            uint256 delta = contractionR - 100000;
            delta = delta + burnRateOffset;

            uint256 maxBurn = _getMaxBurnRate();
            return (delta > maxBurn) ? maxBurn : delta;
           
        }else{
            return minBurnRate;
        }
    }
    function getMintValue(address sender, uint256 amount) internal view returns(uint256, uint256, uint256, uint256) {
        uint256 expansionR = getExpansionRate(sender); // e.g. 14000 = 14%
        uint256 mintAmount = amount.mul(expansionR).div(100000);
        
        return (expansionR, mintAmount.mul(Constants.getStabilizerFee()).div(10000),mintAmount.mul(Constants.getTreasuryFee()).div(10000),mintAmount);
    }

    function getBurnValues(address recipient, uint256 amount) internal view returns(uint256, uint256) {
        uint256 currentFactor = getFactor();
        uint256 contractionR = getContractionRate(isSupportedPool(recipient) ? recipient : _mainPool); 
        // e.g. 14000 = 14%
        uint256 burnAmount = amount.mul(contractionR).div(100000);
        return (burnAmount, burnAmount.mul(currentFactor));
    }

    function getUtilityFee(uint256 amount) internal view returns(uint256, uint256) {
        uint256 currentFactor = getFactor();
        uint256 utilityFee = amount.mul(Constants.getBaseUtilityFee()).div(10000);
        return (utilityFee, utilityFee.mul(currentFactor));
    }
    // function getMintRate(address pool) external view returns (uint256) {
    //     uint256 expansionR = (_poolCounters[pool].pairTokenBalance).mul(_poolCounters[pool].startTokenBalance).mul(100).div(_poolCounters[pool].startPairTokenBalance).div(_poolCounters[pool].tokenBalance);
    //     if (expansionR > (Constants.getBaseExpansionFactor()).add(10000).div(100)) {
    //         uint256 mintFactor = expansionR.mul(expansionR);
    //         return mintFactor.sub(10000);
    //     } else {
    //         return Constants.getBaseExpansionFactor();
    //     }
    // }
    // function getBurnRate(address pool) external view returns (uint256) {
    //     uint256 contractionR = (_poolCounters[pool].tokenBalance).mul(_poolCounters[pool].startPairTokenBalance).mul(100).div(_poolCounters[pool].pairTokenBalance).div(_poolCounters[pool].startTokenBalance);
    //     uint256 burnRate;
    //     if (contractionR > (Constants.getBaseContractionFactor().add(10000)).div(100)) {
    //         uint256 burnFactor = contractionR.mul(contractionR);
    //         burnRate = burnFactor.sub(10000);
    //         if (burnRate > Constants.getBaseContractionCap()) {
    //             return Constants.getBaseContractionCap();
    //         }
    //         return burnRate;

    //     } else {
    //         return Constants.getBaseContractionFactor();
    //     }
    // }
    function _getMaxBurnRate() internal view returns (uint256) {
        if (isBootstrap) {
            return maxMintRate - 1;
        } else {
            return maxBurnRate;
        }
    }



}

// File: contracts\Setters.sol



pragma solidity ^0.6.12;
// pragma experimental ABIEncoderV2;




contract Setters is State, Getters {
    // function updatePresaleAddress(address presaleAddress) internal {
    //     _presaleCon = presaleAddress;
    // }
    event NewEpoch(uint256 timestamp, uint256 burnOffset, uint256 mintOffset);

    function setAllowances(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
    }
    function addToAccount(address account, uint256 amount) internal {
        uint256 currentFactor = getFactor();
        uint256 largeAmount = amount.mul(currentFactor);
        _largeBalances[account] = _largeBalances[account].add(largeAmount);
        _totalSupply = _totalSupply.add(amount);
    }
    function addToAll(uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
    }
    function initializeEpoch() internal {
        _currentEpoch = now;
    }
    function updateEpoch(uint256 seed) internal {
        initializeEpoch();
        for (uint256 i=0; i<_supportedPools.length; i++) {
            _poolCounters[_supportedPools[i]].startTokenBalance = _poolCounters[_supportedPools[i]].tokenBalance;
            _poolCounters[_supportedPools[i]].startPairTokenBalance = _poolCounters[_supportedPools[i]].pairTokenBalance;
        }
        numEpochs += 1;
        if (numEpochs == bootstrapEnd){
            isBootstrap = false;
        }

        if (seed == 0){
            seed = getNewSeed();
        }
        // random mint/burn rate
        (seed, mintRateOffset) = getRandom(seed, minMintRate,maxMintRate.div(2));
        (, burnRateOffset) = getRandom(seed, minBurnRate,maxBurnRate.div(2));
        emit NewEpoch(now, mintRateOffset, burnRateOffset);
    }
    
    function getNewSeed() internal view returns (uint256){
        return uint256(keccak256(abi.encodePacked(blockhash(block.number-1), txNum)));
    }
    function getRandom(uint256 seed, uint256 min, uint256 max) internal pure returns (uint256, uint256) {
        uint256 r = uint256(keccak256(abi.encodePacked(seed))) % (max.sub(min));
        return (r, min + r);
    }

    function initializeLargeTotal() internal {
        _largeTotal = Constants.getLargeTotal();
    }
    function syncPair(address pool) internal returns(bool) {
        (uint256 tokenBalance, uint256 pairTokenBalance, uint256 lpBalance) = getUpdatedPoolCounters(pool, _poolCounters[pool].pairToken);
        bool lpBurn = lpBalance < _poolCounters[pool].lpBalance;
        _poolCounters[pool].lpBalance = lpBalance;
        _poolCounters[pool].tokenBalance = tokenBalance;
        _poolCounters[pool].pairTokenBalance = pairTokenBalance;
        return (lpBurn);
    }
    function silentSyncPair(address pool) public {
        (uint256 tokenBalance, uint256 pairTokenBalance, uint256 lpBalance) = getUpdatedPoolCounters(pool, _poolCounters[pool].pairToken);
        _poolCounters[pool].lpBalance = lpBalance;
        _poolCounters[pool].tokenBalance = tokenBalance;
        _poolCounters[pool].pairTokenBalance = pairTokenBalance;
    }
    function addSupportedPool(address pool, address pairToken) internal {
        require(!isSupportedPool(pool),"This pool is already supported");
        _isSupportedPool[pool] = true;
        _supportedPools.push(pool);
        (uint256 tokenBalance, uint256 pairTokenBalance, uint256 lpBalance) = getUpdatedPoolCounters(pool, pairToken);
        _poolCounters[pool] = PoolCounter(pairToken, tokenBalance, pairTokenBalance, lpBalance, tokenBalance, pairTokenBalance);
    }
    function removeSupportedPool(address pool) internal {
        require(isSupportedPool(pool), "This pool is currently not supported");
        for (uint256 i = 0; i < _supportedPools.length; i++) {
            if (_supportedPools[i] == pool) {
                _supportedPools[i] = _supportedPools[_supportedPools.length - 1];
                _isSupportedPool[pool] = false;
                delete _poolCounters[pool];
                _supportedPools.pop();
                break;
            }
        }
    }

  
}

// File: contracts\IUnicrypt.sol

pragma solidity >=0.6.0;

interface IUnicrypt {
    function depositToken(address token, uint256 amount, uint256 unlock_date) external payable;
    function withdrawToken(address token, uint256 amount) external;

    function getTokenReleaseAtIndex (address token, uint index) external view returns (uint256, uint256);
    function getUserTokenInfo (address token, address user) external view returns (uint256, uint256, uint256);
    function getUserVestingAtIndex (address token, address user, uint index) external view returns (uint256, uint256);
}

// File: contracts\RST.sol



pragma solidity ^0.6.12;
// pragma experimental ABIEncoderV2;











contract RStable is Setters, Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    modifier onlyTaxlessSetter {
        require(isTaxlessSetter(_msgSender()),"not taxless");
        _;
    }
    modifier taxlessTx {
        _taxLess = true;
        _;
        _taxLess = false;
    }

    constructor() public Ownable(){
        // uniswapRouterV2 = IUniswapV2Router02(Constants.getRouterAdd());
        // uniswapFactory = IUniswapV2Factory(Constants.getFactoryAdd());
        updateEpoch(0);
        initializeLargeTotal();

        // if platform that require sending coins
        // initSaleWithBalance();
        
        // start with no tax during sale. taxlessly create pool first.
        //  _taxLess = true;
    }
    // function initSaleWithBalance() internal {
    //     // mint to myself.
    //     uint256 toMint = Constants.getLaunchSupply().sub(totalSupply());
    //     addToAccount(owner(),toMint);
    //     emit Transfer(address(0),address(this),toMint);
    // }

    // needed if sale platform mints on the go
    // function setPresaleDone() public payable onlyOwner {
    //     require(totalSupply() <= Constants.getLaunchSupply(), "Total supply is already minted");
    //     _mintRemaining();
    //     _presaleDone = true;
    // }
    


    function name() public pure returns (string memory) {
        return Constants.getName();
    }
    
    function symbol() public pure returns (string memory) {
        return Constants.getSymbol();
    }
    
    function decimals() public pure returns (uint8) {
        return Constants.getDecimals();
    }
    
    function totalSupply() public view override returns (uint256) {
        return getTotalSupply();
    }
    
    function circulatingSupply() public view returns (uint256) {
        return getTotalSupply().sub(balanceOf(address(this))).sub(balanceOf(getStabilizer()));
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        uint256 currentFactor = getFactor();
        return getLargeBalances(account).div(currentFactor);
    }
    

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return getAllowances(owner,spender);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), getAllowances(sender,_msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, getAllowances(_msgSender(),spender).add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, getAllowances(_msgSender(),spender).sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
  
    function setPresaleDone() public payable  {
        // require(_msgSender() == presaleAdd, "no!");
        // require(totalSupply() <= Constants.getLaunchSupply(), "Total supply is already minted");
        _mintRemaining(); // mints the allocation for the LP
        _presaleDone = true;
        _createEthPool();
    }
    function _mintRemaining() private {
        require(!isPresaleDone(), "Cannot mint post presale");
        uint256 toMint = Constants.getLaunchSupply().sub(totalSupply());
        addToAccount(address(this),toMint);
        emit Transfer(address(0),address(this),toMint);
    }
    
    function mint(address to, uint256 amount) external { 
        require(!_presaleDone,"no minting after presale!");
        require(_msgSender() == presaleAdd, "no!");
        addToAccount(to,amount);
        emit Transfer(address(0),to,amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        setAllowances(owner, spender, amount);
        emit Approval(owner, spender, amount);
    }
    function randomAdvanceEpoch(address sender, address recipient, uint256 amount) internal {
        
        // if a new block, then calculate.
        if (now > getCurrentEpoch().add(maxEpochLength)){
            updateEpoch(0);
        } else {
            if (block.number == lastCalculatedBlock){
                return;
            }
            lastCalculatedBlock = block.number;
            (uint256 r, uint256 rMasked) = getRandom3(sender, recipient, amount);
            if (rMasked >= advanceMinThreshold && rMasked < advanceMaxThreshold){
                updateEpoch(r);
            }
        }
    }
    // function getRandom1(address sender, address recipient, uint256 amount) public view returns (uint256) {
    //     uint256 r = uint256(keccak256(abi.encodePacked(txNum, sender, recipient, amount, blockhash(block.number-1))));
    //     return r;
    // }
    // function getRandom2(uint256 r) public view returns (uint256) {
    //     uint256 r1 = r.sub((r >> advanceLotteryBits) << advanceLotteryBits);
    //     return r1;
    // }
    function getRandom3(address sender, address recipient, uint256 amount) public view returns (uint256, uint256) {
        uint256 r = uint256(keccak256(abi.encodePacked(txNum, sender, recipient, amount, blockhash(block.number-1))));
        uint256 r1 = _sliceNumber(r, advanceLotteryBits);
        return (r,r1);
    }
    function _sliceNumber(uint256 _n, uint256 _nbits) private pure returns (uint256) {
        // mask is made by shifting left an offset number of times
        uint256 mask = uint256((2**(_nbits)) - 1);
        // AND n with mask, and trim to max of _nbits bits
        return uint256((_n & mask));
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= balanceOf(sender),"Amount exceeds balance!!");
        // require(isPresaleDone(),"Presale yet to close");
        
        txNum += 1;
        
        uint256 currentFactor = getFactor();
        uint256 largeAmount = amount.mul(currentFactor);
        uint256 txType;
        if (isTaxLess()) {
            txType = 3;
        } else {
            bool lpBurn;
            if (isSupportedPool(sender)) {
                lpBurn = syncPair(sender);
            } else if (isSupportedPool(recipient)){
                silentSyncPair(recipient);
            } else {
                silentSyncPair(_mainPool);
            }
            txType = _getTxType(sender, lpBurn);
        }
        if (txType != 3){
            // random advance epoch
            randomAdvanceEpoch(sender, recipient, amount);
        }
        // Buy Transaction from supported pools - requires mint, no utility fee
        if (txType == 1) {
            (uint256 expansionR, uint256 stabilizerMint, uint256 treasuryMint, uint256 totalMint) = getMintValue(sender, amount);
            // uint256 mintSize = amount.div(100);
            lastMintRate = expansionR;

            _largeBalances[sender] = _largeBalances[sender].sub(largeAmount);
            _largeBalances[recipient] = _largeBalances[recipient].add(largeAmount);
            _largeBalances[getStabilizer()] = _largeBalances[getStabilizer()].add(stabilizerMint.mul(currentFactor));
            _largeBalances[Constants.getTreasuryAdd()] = _largeBalances[Constants.getTreasuryAdd()].add(treasuryMint.mul(currentFactor));
            _totalSupply = _totalSupply.add(totalMint);
            emit Transfer(sender, recipient, amount);
            emit Transfer(address(0),getStabilizer(),stabilizerMint); // stabilizer = dev fees for now.
            emit Transfer(address(0),Constants.getTreasuryAdd(),treasuryMint);
        }
        // Sells to supported pools or unsupported transfer - requires exit burn and utility fee
        else if (txType == 2) {
            (uint256 burnSize, uint256 largeBurnSize) = getBurnValues(recipient, amount);
            (uint256 utilityFee, uint256 largeUtilityFee) = getUtilityFee(amount);
            uint256 actualTransferAmount = amount.sub(burnSize).sub(utilityFee);
            uint256 largeTransferAmount = actualTransferAmount.mul(currentFactor);
            _largeBalances[sender] = _largeBalances[sender].sub(largeAmount);
            _largeBalances[recipient] = _largeBalances[recipient].add(largeTransferAmount);
            _largeBalances[_liquidityReserve] = _largeBalances[_liquidityReserve].add(largeUtilityFee);
            _totalSupply = _totalSupply.sub(burnSize);
            _largeTotal = _largeTotal.sub(largeBurnSize);
            emit Transfer(sender, recipient, actualTransferAmount);
            emit Transfer(sender, address(0), burnSize);
            emit Transfer(sender, _liquidityReserve, utilityFee);
        } 
        // Add Liquidity via interface or Remove Liquidity Transaction to supported pools - no fee of any sort
        else if (txType == 3) {
            _largeBalances[sender] = _largeBalances[sender].sub(largeAmount);
            _largeBalances[recipient] = _largeBalances[recipient].add(largeAmount);
            emit Transfer(sender, recipient, amount);
        }
    }

    function _getTxType(address sender, bool lpBurn) private view returns(uint256) {
        uint256 txType = 2;
        if (isSupportedPool(sender)) {
            if (lpBurn) {
                txType = 3;
            } else {
                txType = 1;
            }
        } else if (sender == uniswapRouter) {
            txType = 3;
        }
        return txType;
    }

    function _createEthPool() private taxlessTx{

        IUniswapV2Router02 uniswapRouterV2 = getUniswapRouter();
        IUniswapV2Factory uniswapFactory = getUniswapFactory();
        address tokenUniswapPair;
        if (uniswapFactory.getPair(address(uniswapRouterV2.WETH()), address(this)) == address(0)) {
            tokenUniswapPair = uniswapFactory.createPair(
            address(uniswapRouterV2.WETH()), address(this));
        } else {
            tokenUniswapPair = uniswapFactory.getPair(address(this),uniswapRouterV2.WETH());
        }
        uint256 amtEth = address(this).balance;
        uint256 amtToken = amtEth.mul(Constants.getAddLiquidRate()).div(10**9);
        if (amtToken > balanceOf(address(this))){
            amtToken = balanceOf(address(this));
        }

        _approve(address(this), address(uniswapRouterV2), amtToken);
   
        uniswapRouterV2.addLiquidityETH{value: amtEth}(address(this),
            amtToken, 0, 0, address(this), block.timestamp); // to lp
      
        addSupportedPool(tokenUniswapPair, address(uniswapRouterV2.WETH()));
        _mainPool = tokenUniswapPair;
        
        // lock
        uint amtLPheld = IERC20(tokenUniswapPair).balanceOf(address(this));      
        IERC20(tokenUniswapPair).approve(pol,amtLPheld);
   
        // lock liquidity
        // if (pol != address(0)){
        IUnicrypt(pol).depositToken(tokenUniswapPair, amtLPheld, block.timestamp.add(Constants.twoYearSec));
        // }
        
    }
    function spareFundsToTreasury(uint256 amt) external taxlessTx onlyOwner{
        _transfer(address(this), Constants.getTreasuryAdd(), amt);
    }
    

    function addNewSupportedPool(address pool, address pairToken) external onlyOwner() {
        addSupportedPool(pool, pairToken);
    }

    function removeOldSupportedPool(address pool) external onlyOwner() {
        removeSupportedPool(pool);
    }

    function setTaxlessSetter(address cont) external onlyOwner() {
        require(!isTaxlessSetter(cont),"already setter");
        _isTaxlessSetter[cont] = true;
    }

    function setTaxless(bool flag) public onlyTaxlessSetter {
        _taxLess = flag;
    }

    function removeTaxlessSetter(address cont) external onlyOwner() {
        require(isTaxlessSetter(cont),"not setter");
        _isTaxlessSetter[cont] = false;
    }

    function setLiquidityReserve(address reserve) external onlyOwner() {
        _isTaxlessSetter[_liquidityReserve] = false;
        uint256 oldBalance = balanceOf(_liquidityReserve);
        if (oldBalance > 0) {
            _transfer(_liquidityReserve, reserve, oldBalance);
            emit Transfer(_liquidityReserve, reserve, oldBalance);
        }
        _liquidityReserve = reserve;
        _isTaxlessSetter[reserve] = true;
    }

    function setStabilizer(address reserve) external onlyOwner() taxlessTx {
        _isTaxlessSetter[_stabilizer] = false;
        uint256 oldBalance = balanceOf(_stabilizer);
        if (oldBalance > 0) {
            _transfer(_stabilizer, reserve, oldBalance);
            emit Transfer(_stabilizer, reserve, oldBalance);
        }
        _stabilizer = reserve;
        _isTaxlessSetter[reserve] = true;
    }
    function setRouterAdd(address a) external onlyOwner {
        uniswapRouter = a;
    }
    function setFactoryAdd(address a) external onlyOwner{
        uniswapFac = a;
    }
    function setMaxEpochLength(uint256 secs) external onlyOwner {
        maxEpochLength = secs;
    }
    function setAdvance(uint256 min, uint256 max, uint256 bits) external onlyOwner {
        advanceMinThreshold = min;
        advanceMaxThreshold = max;
        advanceLotteryBits = bits;
    }
    function setRates(uint256 minBurn, uint256 maxBurn, uint256 minMint, uint256 maxMint) external onlyOwner {
        minBurnRate = minBurn;
        maxBurnRate = maxBurn;
        minMintRate = minMint;
        maxMintRate = maxMint;
    }
    function setIsBootstrap(bool b) external onlyOwner {
        isBootstrap = b;
    }
    function setNumEpochs(uint256 e) external onlyOwner {
        numEpochs = e;
    }
    function setBootstrapEnd(uint256 n) external onlyOwner {
        bootstrapEnd = n;
    }
    function setPresaleAdd(address a) external onlyOwner {
        presaleAdd = a;
    }
    function setPolAdd(address a) external onlyOwner {
        pol = a;
    }
}