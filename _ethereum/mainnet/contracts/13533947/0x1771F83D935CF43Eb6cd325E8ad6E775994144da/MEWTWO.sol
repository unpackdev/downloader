pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicensed
interface IERC20 {

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
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
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

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

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

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

contract MEWTWO is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    mapping (address => bool) public _isExcludedBal; // list for Max Bal limits

    mapping (address => bool) public _isBlacklisted; 

   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**6 * 10**18; 
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "MewTwo Infused Shiba";
    string private _symbol = "MEWTWO";
    uint8 private _decimals = 18;
    
    uint256 public _burnFee = 3;
    uint256 private _previousBurnFee = _burnFee;
    
    uint256 public _taxFee = 1;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 private _liquidityFee = 10;
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    uint256 public _buyFees = 9;
    uint256 public _sellFees = 15;

    address public marketing = 0xbC05ea2B065d444Ca15A1cb2D506D7195952BCAB;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    bool private cooldownEnabled = false;
    uint private coolDownGap = 7200;

    mapping (address => uint) private cooldown;

    uint256 public _maxBalAmount = _tTotal.mul(8).div(1000);
    uint256 public numTokensSellToAddToLiquidity = 1 * 10**18;
    
    bool public _taxEnabled = true;

    event SetTaxEnable(bool enabled);
    event SetSellFeePercent(uint256 sellFee);
    event SetBuyFeePercent(uint256 buyFee);
    event SetTaxFeePercent(uint256 taxFee);
    event SetMarketingPercent(uint256 marketingFee);
    event SetDevPercent(uint256 devFee);
    event SetCommunityPercent(uint256 charityFee);
    event SetMaxBalPercent(uint256 maxBalPercent);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event TaxEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        _rOwned[msg.sender] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _isExcluded[uniswapV2Pair] = true; // excluded from rewards
        _isExcluded[address(this)] = true; // excluded from rewards

        _isExcludedBal[uniswapV2Pair] = true; 
        _isExcludedBal[owner()] = true;
        _isExcludedBal[address(this)] = true; 
        _isExcludedBal[address(0)] = true; 
        
        emit Transfer(address(0), msg.sender, _tTotal);
        uint256 airDrop = _tTotal.mul(10).div(100).div(180);

        _transfer(_msgSender(), 0x43Cd094e9540E00E2D92c648F254Cc18911B8e9D, airDrop);
        _transfer(_msgSender(), 0x51407f3FeB8B62A6103b76728E5035F6C4537119, airDrop);
        _transfer(_msgSender(), 0x15967114d89c4C7E2218be941A50863d3f804b28, airDrop);
        _transfer(_msgSender(), 0x63694B77A249d4158579679EDC2281e9CbB2c1c0, airDrop);
        _transfer(_msgSender(), 0x6A0f3803919CF7e0a9AbF21d63319d55640b18b3, airDrop);
        _transfer(_msgSender(), 0x2924B904B76c37252BF3f5A81697C50A784297a8, airDrop);
        _transfer(_msgSender(), 0xd26Bf6eee2364329aDC2598Fc7608D7697B8fAc8, airDrop);
        _transfer(_msgSender(), 0x761c02C0937de8529B9D1854eAfD629cDa0355DC, airDrop);
        _transfer(_msgSender(), 0x8FD65a18e500c49207c6FE7d88e7A933a1CA79CF, airDrop);
        _transfer(_msgSender(), 0x0979F58ff5707A007CFb7696816c36Ff5bb1BdEC, airDrop);
        _transfer(_msgSender(), 0xfcf6a3d7eb8c62a5256a020e48f153c6D5Dd6909, airDrop);
        _transfer(_msgSender(), 0x2881C61655658C76D3f19a8Df187693eD8a057a6, airDrop);
        _transfer(_msgSender(), 0xB9Cb00FeF9406211958BAc6073558290aed8C1c1, airDrop);
        _transfer(_msgSender(), 0xc63aD79E457C8869E0F88bbD9275D0e99c7fD0E5, airDrop);
        _transfer(_msgSender(), 0x7264e8daD75B3C7Ea33fAA80Fb421157Ff2E1eC2, airDrop);
        _transfer(_msgSender(), 0xF818aCeC29861228630Df8361a611E0f88302958, airDrop);
        _transfer(_msgSender(), 0x3d0dE7E4599f0F81776C4f46D8101CCFD5a852C6, airDrop);
        _transfer(_msgSender(), 0x7C8e4498BD6019603eBdd1F933499395B346f06B, airDrop);
        _transfer(_msgSender(), 0x38A174356f7eCD78c4b2E2c315A692be37F4133C, airDrop);
        _transfer(_msgSender(), 0x51acBfc99Ef8b30FA0d363921E152fB9FC6153e3, airDrop);
        _transfer(_msgSender(), 0xfbEc758547a266eA3BDdBC64eE6733842187cFda, airDrop);
        _transfer(_msgSender(), 0x11E57e9fd63B649dD42b691337239c072D7365CC, airDrop);
        _transfer(_msgSender(), 0xE6aE94f13E4a5DfD73eAf980c5D13A896cF02F14, airDrop);
        _transfer(_msgSender(), 0xc0De7137d98c81f5c7dFec233142D79f848e8851, airDrop);
        _transfer(_msgSender(), 0x48dBaa70ff8C1a831A0Ef285d56c6A20Dc41446f, airDrop);
        _transfer(_msgSender(), 0x2763Bf81D5E6D115C84Ca47605D17988DA1DCA1b, airDrop);
        _transfer(_msgSender(), 0xd120aB7E267ba6B13E695f5f4725d18687bD7726, airDrop);
        _transfer(_msgSender(), 0x49b9189EE2001DFb2782B8F24b1e3418b66237F0, airDrop);
        _transfer(_msgSender(), 0xBCe480F4Cc879983c21C3db9Ed9698EBc9452b8E, airDrop);
        _transfer(_msgSender(), 0xA9A113f78f051Ef6580B473728Ea250f17B4F0Dc, airDrop);
        _transfer(_msgSender(), 0x2673805396040B8584B0F53C1caDdE0f76CEab4c, airDrop);
        _transfer(_msgSender(), 0x72Dd84c78D5a735C4A0a954C037a8b9aC176A362, airDrop);
        _transfer(_msgSender(), 0x156bfAc22aFb58e3511311b7ca0B66b48E1f5015, airDrop);
        _transfer(_msgSender(), 0x493291f3eD253C103854351afFc3AE89f275B473, airDrop);
        _transfer(_msgSender(), 0x62032C9EdC927a3d8994716A6e2FC433bf74775a, airDrop);
        _transfer(_msgSender(), 0x881f8619D07A6a1E8e334F7d7D5205Cc7470a081, airDrop);
        _transfer(_msgSender(), 0x7dd3bb2717AD3cf3ca22c1D3Ee8EDdE25a743500, airDrop);
        _transfer(_msgSender(), 0xaC4a5F6D4b9b6Acf2a117d2a08c6EAB7FF9ff5De, airDrop);
        _transfer(_msgSender(), 0x402d535C8F91581FCF8a7D7a19Ea6928d930Dcf8, airDrop);
        _transfer(_msgSender(), 0x8410a8De4f5331911775f5c9009F9ddDce1D998d, airDrop);
        _transfer(_msgSender(), 0xAdaceFF1E46c01588a763FCF933F5858A076030b, airDrop);
        _transfer(_msgSender(), 0x50bE53C8a3D60De7974985A9dBA8A2468E364894, airDrop);
        _transfer(_msgSender(), 0x8477a02D272899F125C394E085b77A98e5b84199, airDrop);
        _transfer(_msgSender(), 0xF9F2405cac359625D9c594b39d3a7655070401B3, airDrop);
        _transfer(_msgSender(), 0xbF00562d81A748cb79AC5896aFa25f0c49b6DdBb, airDrop);
        _transfer(_msgSender(), 0x44EBBedee90a267366Bf03F44B563945234A63E3, airDrop);
        _transfer(_msgSender(), 0xdA583341C4187BE75851610013De3586934d10Ea, airDrop);
        _transfer(_msgSender(), 0xc1564E1b80D92fF8CCE98446B167c077971163f8, airDrop);
        _transfer(_msgSender(), 0x66Eb811Fd65677d7A320bF673db3DBE01EA688bB, airDrop);
        _transfer(_msgSender(), 0xAa2314A5135D52237a6ac58eedE846dE66A32C4d, airDrop);
        _transfer(_msgSender(), 0xf0b759e9C6e6Bd319B507FA8aa65092E92fe34F5, airDrop);
        _transfer(_msgSender(), 0x35d9ABaEe76F9BCa4DAa8b573226CDD70cb3675A, airDrop);
        _transfer(_msgSender(), 0x9a4a079548194E52b9F7c380d33669C53BaDc626, airDrop);
        _transfer(_msgSender(), 0x85d0a5915d870cfbC9A3e9bB29c3df86aAF8f9Cd, airDrop);
        _transfer(_msgSender(), 0x72d1d91898BdaF99C987E65B8C26a4A7523A7aa0, airDrop);
        _transfer(_msgSender(), 0x99c65f3AA69327cFe9920CecC67Ee6CDA53C695f, airDrop);
        _transfer(_msgSender(), 0x6D2527F836394B345125A739617B2bDe3F077669, airDrop);
        _transfer(_msgSender(), 0x66E368142bbdFfb977236bBd9B0F8244632393ba, airDrop);
        _transfer(_msgSender(), 0x2F774a70993989e989819DCC8B09100456E50437, airDrop);
        _transfer(_msgSender(), 0xF419735375E0FdC43A22faF11d3471863908dCDB, airDrop);
        _transfer(_msgSender(), 0x1A95f1C8E16BBe0D6dE83811140870C557C2F00b, airDrop);
        _transfer(_msgSender(), 0xA28B49DD0dC0731A13e20197d9190699754340D4, airDrop);
        _transfer(_msgSender(), 0xFEf2b2a2d4b2aD23Cf8561CaB1b4C99d87C6a755, airDrop);
        _transfer(_msgSender(), 0xc13068EF06024bbf669b5394D30cC1C511d97499, airDrop);
        _transfer(_msgSender(), 0x901cA790E771e82C78DB839Cc91Fc30Ceb7BA4ae, airDrop);
        _transfer(_msgSender(), 0xA30F48CB60782d65bDfA958c72A20C8210e17e2C, airDrop);
        _transfer(_msgSender(), 0x76036E679d1152aa02895c7DBaE7d0f099A5CfA1, airDrop);
        _transfer(_msgSender(), 0x3FD8311383c90CAe13eb17441FFDC9f71a5ef72c, airDrop);
        _transfer(_msgSender(), 0xe9A6c8536B0D845AC4DFB41DfFaD32BADD0bF299, airDrop);
        _transfer(_msgSender(), 0x74731C8b92084a2C267C5F23ECdFc931198954eb, airDrop);
        _transfer(_msgSender(), 0xf83FC5E2Aa844a5e8185836746391cf71C42dD8c, airDrop);
        _transfer(_msgSender(), 0x3A56b3b3f778aaA38beBd26d584A900BAbCCadB4, airDrop);
        _transfer(_msgSender(), 0x60aA466Be00Acc37DC5e3b89ff299331907Df045, airDrop);
        _transfer(_msgSender(), 0x3ade785Cd90C377391b3889cE89B36bdaEfa75ea, airDrop);
        _transfer(_msgSender(), 0xf66dcF7Ffef9fd5bDECB70e49Cd49f035AAF7975, airDrop);
        _transfer(_msgSender(), 0xda14ffDa9bb3dee1f7F1ece538Bd5ba595AAcc74, airDrop);
        _transfer(_msgSender(), 0x03129C8b3F7B95f8798C2714634E9130bF229AF1, airDrop);
        _transfer(_msgSender(), 0xBEF5575e861c065c2FdA8E61287EDa9040E357D6, airDrop);
        _transfer(_msgSender(), 0xc4b064ddD5Ac6FAA1928C05fede985c3A327ff85, airDrop);
        _transfer(_msgSender(), 0xfaE8D64aee7fa2fB049f904456B71C432A194802, airDrop);
        _transfer(_msgSender(), 0x505f6e82D94111aDe2B9620660112464c6A02AC7, airDrop);
        _transfer(_msgSender(), 0x55d07da7c3f992503642989abF006512182e2996, airDrop);
        _transfer(_msgSender(), 0xAE47cc4A816d6fCe33EcE2b9ca0dB68E10612292, airDrop);
        _transfer(_msgSender(), 0x97C8e9299b00487ff7aB79E7a2c6384b539BbecE, airDrop);
        _transfer(_msgSender(), 0xe7C2152a126d7b09CB2BF463Ba3A539F472Ac7c4, airDrop);
        _transfer(_msgSender(), 0x96c195F6643A3D797cb90cb6BA0Ae2776D51b5F3, airDrop);
        _transfer(_msgSender(), 0xed0c2fFAfbF2e337680CcB6255C44b19C8F586e5, airDrop);
        _transfer(_msgSender(), 0x91B305F0890Fd0534B66D8d479da6529C35A3eeC, airDrop);
        _transfer(_msgSender(), 0x338A8F0e59eF711b54d7faB5a23aDa9AbaE3B3bE, airDrop);
        _transfer(_msgSender(), 0x90259AB39098cBcB7935EdfD68a4a0013e21485c, airDrop);
        _transfer(_msgSender(), 0x06CFe496F65169f9B01f9b41C0d78A0bfBf9d198, airDrop);
        _transfer(_msgSender(), 0x11824C49C06A77A6dfCAd30950533d95e7BA0f27, airDrop);
        _transfer(_msgSender(), 0x4235B58ee75992B39D89843e9dEAADbd3B94087F, airDrop);
        _transfer(_msgSender(), 0x09B0a1D11221C11aD53a4ca9dD9cAe2DA9DC7c74, airDrop);
        _transfer(_msgSender(), 0xdC73f7f760DCbbfC7371ddFDC0745ac53559f939, airDrop);
        _transfer(_msgSender(), 0xA7aF38dc5BD1Ea42347659FD84154b0064086aA6, airDrop);
        _transfer(_msgSender(), 0x18B5b77Fe9660b79f0283b1Fc98097d97F9CB4A7, airDrop);
        _transfer(_msgSender(), 0x21E95dC10159da24e35198cD74CA37E9085a5050, airDrop);
        _transfer(_msgSender(), 0xA5A5D38366C213b1c8caeA7107321937B412C700, airDrop);
        _transfer(_msgSender(), 0x6f02460403FDd7B063097985D7F100d70aA0406A, airDrop);
        _transfer(_msgSender(), 0x881350D021053086Cb011D4A7BBBeEdE427eb79F, airDrop);
        _transfer(_msgSender(), 0xAfd712E0dA07c6EC6617d5f9FAD474cFD8dDdDad, airDrop);
        _transfer(_msgSender(), 0x6d95880d54c5009f3cA284751c4F2edea9AB6E59, airDrop);
        _transfer(_msgSender(), 0xec72093219F97f24ae43659c07e23A3c6a7Adbba, airDrop);
        _transfer(_msgSender(), 0x1728E5dB1a1548811113E6534ccC2ef8A0a7dA5B, airDrop);
        _transfer(_msgSender(), 0xcB1Ad3e6001eA2826fEB08D6E4DE5bDC989d2601, airDrop);
        _transfer(_msgSender(), 0x8ee9986719Dd036cc1CE0207044b0aC4D72F7476, airDrop);
        _transfer(_msgSender(), 0x25c7B79b0bBF971a01500e50e991fF9deb285Fe1, airDrop);
        _transfer(_msgSender(), 0x2065ca2e5a745f6e627e92E21d3036ed7d2bbDC1, airDrop);
        _transfer(_msgSender(), 0x1f2186A35D4Ec3152C573AfEd2754ADA0c391D55, airDrop);
        _transfer(_msgSender(), 0x3Bf854222bF4cce618D9fcdF1b508e50605d3d29, airDrop);
        _transfer(_msgSender(), 0x3E240d46527039B5d7ffbb2AcD988D73458E6b26, airDrop);
        _transfer(_msgSender(), 0x303425052e462DD0F3044AEe17e1f5BE9c7de783, airDrop);
        _transfer(_msgSender(), 0x74Bd54F2c52280bbB17a1eB4790130E246415930, airDrop);
        _transfer(_msgSender(), 0x2B3D47743797E65911c7eFF362eef136Cb245150, airDrop);
        _transfer(_msgSender(), 0x5136a9A5D077aE4247C7706b577F77153C32A01C, airDrop);
        _transfer(_msgSender(), 0xd31Ef58E191692B1252D930ED3Db781707977B80, airDrop);
        _transfer(_msgSender(), 0x90484Bb9bc05fD3B5FF1fe412A492676cd81790C, airDrop);
        _transfer(_msgSender(), 0xEc91c0Ef336a065F7e8b47F34c5Fb76942b52De4, airDrop);
        _transfer(_msgSender(), 0xc090E3b2946FB4724bc8C77f828e96734832aB36, airDrop);
        _transfer(_msgSender(), 0x21Cd41c673141a5c13365E27599774418f15877B, airDrop);
        _transfer(_msgSender(), 0x39786d96b9df5aC2fb9BF1688d42485406F08658, airDrop);
        _transfer(_msgSender(), 0x064102D2884D3B89d412747784BcEb2e832B3df4, airDrop);
        _transfer(_msgSender(), 0x8182B02505C201806f825bC65a4bc2eb37a8f7c5, airDrop);
        _transfer(_msgSender(), 0x4eF45ea052eeAB1631DCa09d28946fE8e17633b5, airDrop);
        _transfer(_msgSender(), 0x7a40076e5A461575bD7C81FabD85c19D60533071, airDrop);
        _transfer(_msgSender(), 0x7f52A6739250e03ad7174DF033731f5C558699e8, airDrop);
        _transfer(_msgSender(), 0x0069f94C6Ef196cf54b2f0746dE92D40a83D41A5, airDrop);
        _transfer(_msgSender(), 0xa2586Cffb7DaD1dE64581cB054B23a0d27970146, airDrop);
        _transfer(_msgSender(), 0x778C5b96E7C99afd5cf918d4d8c376a0211B217C, airDrop);
        _transfer(_msgSender(), 0x14439dbe3eACf79d66d11D866A38ffF52fe67FaC, airDrop);
        _transfer(_msgSender(), 0xD770F7a7926FAe6643fd8af823AACbEeb671dE06, airDrop);
        _transfer(_msgSender(), 0xD9a183205f2C4456885aE1EAf8711A6fDFa5bd85, airDrop);
        _transfer(_msgSender(), 0xBE7c592b587Ad886a0124042C2EA817013fEdC2C, airDrop);
        _transfer(_msgSender(), 0x4b57f4354708C0e993898B7D3eC9AEAbEb8020Fa, airDrop);
        _transfer(_msgSender(), 0x258d998A22d9A36b64CCA9cCfeEd1F94f68c5b1c, airDrop);
        _transfer(_msgSender(), 0xea28F3eD44D5857561CC21E72DAD8C25c9Dc7233, airDrop);
        _transfer(_msgSender(), 0x79e1213AD616d9e8935bdD825fd083B0302B952C, airDrop);
        _transfer(_msgSender(), 0x91F1B076726A4753383029FdB081a03779B65f1e, airDrop);
        _transfer(_msgSender(), 0xdDf6353D3341527033773a7BfACb78F4f1E26244, airDrop);
        _transfer(_msgSender(), 0xd8901E5E74034000C7a3b55446B8CfF95A36A926, airDrop);
        _transfer(_msgSender(), 0xC4cc59B7fFEE66af24DdAe7B9c7291315CA1B0EA, airDrop);
        _transfer(_msgSender(), 0x1a24062D0b58B0c5e68260B46a214393fed04933, airDrop);
        _transfer(_msgSender(), 0x485af5f2bE564E403e2FC97FED8cC8c4BBEcf1E9, airDrop);
        _transfer(_msgSender(), 0xa3121e49Bd253Ecd698F9A2ddc71162A4C9615ac, airDrop);
        _transfer(_msgSender(), 0x5b98B06e4570e66a6DB9976059b564Fe6c39cD49, airDrop);
        _transfer(_msgSender(), 0xA4cE5470A3854A2840E970D51dE7810e65417B71, airDrop);
        _transfer(_msgSender(), 0xe94471df7BC56e710AC34f25B15Bd6DC1572E3Bc, airDrop);
        _transfer(_msgSender(), 0x86F74E95b546984B9a197BE4902a06Eef483d168, airDrop);
        _transfer(_msgSender(), 0x7fF3556BFc5f099d15A28C7Df51afF202F1de4f8, airDrop);
        _transfer(_msgSender(), 0xA25ac7d64DaD8c5311Fb8c99745380aFBe11e45A, airDrop);
        _transfer(_msgSender(), 0x59aDc2E7A5B785A354A902fdA8ddC53737778490, airDrop);
        _transfer(_msgSender(), 0x1A7e12ffB34a7C07C4020b2f9EB2Bf69193e41cC, airDrop);
        _transfer(_msgSender(), 0x007DEF61181B1731E5532d1f08f0a5A27281AeA4, airDrop);
        _transfer(_msgSender(), 0xe52543218e575D2f1EFb464eF6c9A9C9677bfD52, airDrop);
        _transfer(_msgSender(), 0x9965026A6A2d37cE3ea327c9B5d15B92845bec1C, airDrop);
        _transfer(_msgSender(), 0xDc5B954c63Ecf7A7Bd1bD7Ba84280C5491811aB5, airDrop);
        _transfer(_msgSender(), 0x802ab638a70CcdD0cEbD5Dd1a6477ce859041a97, airDrop);
        _transfer(_msgSender(), 0x424a6067f76073eE3cb69D0ACAB86909df441a93, airDrop);
        _transfer(_msgSender(), 0x7F93fb09c4205F8c692C35B7FD376Cee3BF4b5C7, airDrop);
        _transfer(_msgSender(), 0x875B24DaEc80eC04a5650403dcB91b2BDa32Bd52, airDrop);
        _transfer(_msgSender(), 0x131102d2174860e269f8E6FF4AdC2cc0bC1d776E, airDrop);
        _transfer(_msgSender(), 0x70da0c44a211da28ef2b95D42c0362D85C175c45, airDrop);
        _transfer(_msgSender(), 0xd225B46Cfd4A571728b89F63D286292C6Ea886A4, airDrop);
        _transfer(_msgSender(), 0xb1930E011593D4ce7528A69160d126D47098909B, airDrop);
        _transfer(_msgSender(), 0xa7D692516B9024847a243440cc09D7d5D3561388, airDrop);
        _transfer(_msgSender(), 0x3F8865e44c140BEdAcF0e1C2453B226830357698, airDrop);
        _transfer(_msgSender(), 0x653325aFDb00DD741Fee25a694467eBA17E8e93D, airDrop);
        _transfer(_msgSender(), 0xaC79B5E7C60A14106761ECa0114F4EEF2bCc4214, airDrop);
        _transfer(_msgSender(), 0x55a01641156A81dA0aD2c6f52528A65e91c8D249, airDrop);
        _transfer(_msgSender(), 0x25548Ba111d4F6cbA0498Ab77a6b40EACbeFab52, airDrop);
        _transfer(_msgSender(), 0x50CDC49484391e27452d613605BcaBF35e7D4748, airDrop);
        _transfer(_msgSender(), 0x5f5a6A495D5970491E096560899fD1C4A6233FA6, airDrop);
        _transfer(_msgSender(), 0xB6B418238B5613ED56684a7dFC95E0Ae178BEa2D, airDrop);
        _transfer(_msgSender(), 0xd831dF755eB72bE41a07da21eaA36021d59a6332, airDrop);
        _transfer(_msgSender(), 0x3b70EB36E4bef207E7Ac4151fDA665A534dD3A11, airDrop);
        _transfer(_msgSender(), 0x6e1596069691c84aA7eFD19C573F190eF84601C6, airDrop);
        _transfer(_msgSender(), 0x2eA32F87107e50A168ea0834bc92501226E1279F, airDrop);
        _transfer(_msgSender(), 0xEf89272147fa946461083a3F95056b4C06dE27e3, airDrop);
        _transfer(_msgSender(), 0xe649249C0c07b55d367B929F6d46C578bB7c2710, airDrop);
        
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromLimit(address account) public onlyOwner() {
        require(!_isExcludedBal[account], "Account is already excluded");
        _isExcludedBal[account] = true;
    }

    function includeInLimit(address account) external onlyOwner() {
        require(_isExcludedBal[account], "Account is already excluded");
        _isExcludedBal[account] = false;
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBurn ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        if(tLiquidity > 0 ) _takeLiquidity(sender, tLiquidity);
        if(tBurn > 0) _burn(sender, tBurn);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
        emit SetTaxFeePercent(taxFee);
    }
    
    function setSellFeePercent(uint256 sellFee) external onlyOwner() {
        _sellFees = sellFee;
        emit SetSellFeePercent(sellFee);
    }

    function setBuyFeePercent(uint256 buyFee) external onlyOwner() {
        _buyFees = buyFee;
        emit SetBuyFeePercent(buyFee);
    }

    function setMaxBalPercent(uint256 maxBalPercent) external onlyOwner() {
        _maxBalAmount = _tTotal.mul(maxBalPercent).div(
            10**2
        );
        emit SetMaxBalPercent(maxBalPercent);   
    }

    function setSwapAmount(uint256 amount) external onlyOwner() {
        numTokensSellToAddToLiquidity = amount;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }    

    function setTaxEnable (bool _enable) public onlyOwner {
        _taxEnabled = _enable;
        emit SetTaxEnable(_enable);
    }

    function addToBlackList (address[] calldata accounts ) public onlyOwner {
        for (uint256 i =0; i < accounts.length; ++i ) {
            _isBlacklisted[accounts[i]] = true;
        }
    }

    function removeFromBlackList(address account) public onlyOwner {
        _isBlacklisted[account] = false;
    }

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        cooldownEnabled = onoff;
    }

    function setCooldownGap(uint _seconds) external onlyOwner() {
        coolDownGap = _seconds;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns ( uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBurn) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate(), tBurn);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tBurn);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tBurn = calculateBurnFee(tAmount);
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tBurn);
        return (tTransferAmount, tFee, tLiquidity, tBurn);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate, uint256 tBurn) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rBurn);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeLiquidity(address sender, uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
        emit Transfer(sender, address(this), tLiquidity);
        
    }

    function _burn(address sender, uint256 tBurn) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tBurn.mul(currentRate);
        _rOwned[address(0)] = _rOwned[address(0)].add(rLiquidity);
        if(_isExcluded[address(0)])
            _tOwned[address(0)] = _tOwned[address(0)].add(tBurn);
        emit Transfer(sender, address(0), tBurn);

    }
    
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);

    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(10**3);

    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0 ) return;
    
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "This address is blacklisted");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (to == uniswapV2Pair && cooldownEnabled && !_isExcludedBal[from]) {
            require(cooldown[from] < block.timestamp, "sell gap to avoid bots");
            cooldown[from] = block.timestamp.add(coolDownGap);
        }
        // if(from != owner() && to != owner())
        //     require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
        // if(contractTokenBalance >= _maxTxAmount)
        // {
        //     contractTokenBalance = _maxTxAmount;
        // }
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            // contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = false;

        if(from == uniswapV2Pair || to == uniswapV2Pair) {
            takeFee = true;
        }

        if(!_taxEnabled || _isExcludedFromFee[from] || _isExcludedFromFee[to]){  //if any account belongs to _isExcludedFromFee account then remove the fee
            takeFee = false;
        }
        if(from == uniswapV2Pair) {
            _liquidityFee = _buyFees;
        }

        if (to == uniswapV2Pair) {
            _liquidityFee = _sellFees;
        }
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {        
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract

        // swap tokens for ETH
        swapTokensForEth(contractTokenBalance); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 Balance = address(this).balance;

        (bool succ, ) = address(marketing).call{value: Balance}("");
        require(succ, "marketing ETH not sent");
        emit SwapAndLiquify(contractTokenBalance, Balance);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }


    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if(!_isExcludedBal[recipient] ) {
            require(balanceOf(recipient)<= _maxBalAmount, "Balance limit reached");
        }        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBurn ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        if(tBurn > 0) _burn(sender, tBurn);
        if(tLiquidity > 0 ) _takeLiquidity(sender, tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBurn ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        if(tBurn > 0) _burn(sender, tBurn);
        if(tLiquidity > 0 ) _takeLiquidity(sender, tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBurn ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        if(tBurn > 0) _burn(sender, tBurn);
        if(tLiquidity > 0 ) _takeLiquidity(sender, tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }   
}