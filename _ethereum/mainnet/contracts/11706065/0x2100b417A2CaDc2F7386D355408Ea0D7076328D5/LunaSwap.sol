// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

// openzeppelin

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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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

// Uniswap V2

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

library UniswapV2Library {
    using SafeMathUniswap for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

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
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
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
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
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
}

// Token interface

interface TokenInterface is IERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
}

// Migrator

interface IMigrator {
    // Perform LP token migration from legacy UniswapV2 to PowerSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // PowerSwap must mint EXACTLY the same amount of PowerSwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token, uint8 poolType) external returns (IERC20);
}

contract Migrator {
    address public lpMining;
    address public oldFactory;
    IUniswapV2Factory public factory;
    uint256 public notBeforeBlock;
    uint256 public desiredLiquidity = uint256(-1);

    constructor(
        address _lpMining,
        address _oldFactory,
        IUniswapV2Factory _factory,
        uint256 _notBeforeBlock
    ) {
        lpMining = _lpMining;
        oldFactory = _oldFactory;
        factory = _factory;
        notBeforeBlock = _notBeforeBlock;
    }

    function migrate(IUniswapV2Pair orig, uint8 poolType) public returns (IUniswapV2Pair) {
        require(poolType == 1, "Only Uniswap poolType supported");
        require(msg.sender == lpMining, "not from lpMining");
        require(block.number >= notBeforeBlock, "too early to migrate");
        require(orig.factory() == oldFactory, "not from old factory");

        address token0 = orig.token0();
        address token1 = orig.token1();

        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token0, token1));
        if (pair == IUniswapV2Pair(address(0))) {
            pair = IUniswapV2Pair(factory.createPair(token0, token1));
        }
        
        uint256 lp = orig.balanceOf(msg.sender);
        if (lp == 0) return pair;

        desiredLiquidity = lp;
        orig.transferFrom(msg.sender, address(orig), lp);
        orig.burn(address(pair));
        pair.mint(msg.sender);
        desiredLiquidity = uint256(-1);

        return pair;
    }
}

// Balancer library

contract BConst  {
    uint public constant BONE              = 10**18;

    uint public constant MIN_BOUND_TOKENS  = 2;
    uint public constant MAX_BOUND_TOKENS  = 8;

    uint public constant MIN_FEE           = BONE / 10**6;
    uint public constant MAX_FEE           = BONE / 10;
    uint public constant EXIT_FEE          = 0;

    uint public constant MIN_WEIGHT        = BONE;
    uint public constant MAX_WEIGHT        = BONE * 50;
    uint public constant MAX_TOTAL_WEIGHT  = BONE * 50;
    uint public constant MIN_BALANCE       = BONE / 10**12;

    uint public constant INIT_POOL_SUPPLY  = BONE * 100;

    uint public constant MIN_BPOW_BASE     = 1 wei;
    uint public constant MAX_BPOW_BASE     = (2 * BONE) - 1 wei;
    uint public constant BPOW_PRECISION    = BONE / 10**10;

    uint public constant MAX_IN_RATIO      = BONE / 2;
    uint public constant MAX_OUT_RATIO     = (BONE / 3) + 1 wei;
}

contract BNum is BConst {

    function btoi(uint a)
        internal pure 
        returns (uint)
    {
        return a / BONE;
    }

    function bfloor(uint a)
        internal pure
        returns (uint)
    {
        return btoi(a) * BONE;
    }

    function badd(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint a, uint b)
        internal pure
        returns (uint)
    {
        (uint c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint a, uint b)
        internal pure
        returns (uint, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function bmul(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint c2 = c1 / BONE;
        return c2;
    }

    function bdiv(uint a, uint b)
        internal pure
        returns (uint)
    {
        require(b != 0, "ERR_DIV_ZERO");
        uint c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint c2 = c1 / b;
        return c2;
    }

    // DSMath.wpow
    function bpowi(uint a, uint n)
        internal pure
        returns (uint)
    {
        uint z = n % 2 != 0 ? a : BONE;

        for (n /= 2; n != 0; n /= 2) {
            a = bmul(a, a);

            if (n % 2 != 0) {
                z = bmul(z, a);
            }
        }
        return z;
    }

    // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
    // Use `bpowi` for `b^e` and `bpowK` for k iterations
    // of approximation of b^0.w
    function bpow(uint base, uint exp)
        internal pure
        returns (uint)
    {
        require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

        uint whole  = bfloor(exp);   
        uint remain = bsub(exp, whole);

        uint wholePow = bpowi(base, btoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint partialResult = bpowApprox(base, remain, BPOW_PRECISION);
        return bmul(wholePow, partialResult);
    }

    function bpowApprox(uint base, uint exp, uint precision)
        internal pure
        returns (uint)
    {
        // term 0:
        uint a     = exp;
        (uint x, bool xneg)  = bsubSign(base, BONE);
        uint term = BONE;
        uint sum   = term;
        bool negative = false;


        // term(k) = numer / denom 
        //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (a-(k-1)) * x / k
        // continue until term is less than precision
        for (uint i = 1; term >= precision; i++) {
            uint bigK = i * BONE;
            (uint c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
            term = bmul(term, bmul(c, x));
            term = bdiv(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = bsub(sum, term);
            } else {
                sum = badd(sum, term);
            }
        }

        return sum;
    }

}

// Balancer pool interface

interface BMathInterface {
    function calcInGivenOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountIn);
}

interface BPoolInterface is IERC20, BMathInterface {
    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;
    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;
    function swapExactAmountIn(
        address,
        uint256,
        address,
        uint256,
        uint256
    ) external returns (uint256, uint256);
    function swapExactAmountOut(
        address,
        uint256,
        address,
        uint256,
        uint256
    ) external returns (uint256, uint256);
    function joinswapExternAmountIn(
        address,
        uint256,
        uint256
    ) external returns (uint256);
    function joinswapPoolAmountOut(
        address,
        uint256,
        uint256
    ) external returns (uint256);
    function exitswapPoolAmountIn(
        address,
        uint256,
        uint256
    ) external returns (uint256);
    function exitswapExternAmountOut(
        address,
        uint256,
        uint256
    ) external returns (uint256);
    function getDenormalizedWeight(address) external view returns (uint256);
    function getBalance(address) external view returns (uint256);
    function getSwapFee() external view returns (uint256);
    function getTotalDenormalizedWeight() external view returns (uint256);
    function isPublicSwap() external view returns (bool);
    function isFinalized() external view returns (bool);
    function isBound(address t) external view returns (bool);
    function getCurrentTokens() external view returns (address[] memory tokens);
    function getFinalTokens() external view returns (address[] memory tokens);
    function setSwapFee(uint256) external;
    function setController(address) external;
    function setPublicSwap(bool) external;
    function finalize() external;
    function bind(
        address,
        uint256,
        uint256
    ) external;
    function rebind(
        address,
        uint256,
        uint256
    ) external;
    function unbind(address) external;
    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);
    function getSpotPriceSansFee(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);
    function gulp(address token) external;
    function getController() external view returns (address);
    function getNumTokens() external view returns (uint256);
}

// Swap contract

contract LunaSwap is Ownable, BNum {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for TokenInterface;
    using SafeERC20 for BPoolInterface;

    // States
    TokenInterface public weth;
    TokenInterface public univ2;
    TokenInterface public twa;
    BPoolInterface public lunaBP;
    IUniswapV2Router02 public uniswapV2Router;

    mapping(address => address) public uniswapEthPairByTokenAddress;
    mapping(address => address) public uniswapEthPairToken0;
    mapping(address => bool) public reApproveTokens;
    uint256 public defaultSlippage;

    struct CalculationStruct {
        uint256 tokenAmount;
        uint256 ethAmount;
        uint256 tokenReserve;
        uint256 ethReserve;
    }

    // Events
    event SetTokenSetting(
        address indexed token,
        bool indexed reApprove,
        address indexed uniswapPair
    );
    event SetDefaultSlippage(uint256 newDefaultSlippage);
    event EthToLunaSwap(
        address indexed user,
        uint256 ethInAmount,
        uint256 poolOutAmount
    );
    event OddEth(address indexed user, uint256 amount);
    event LunaToEthSwap(
        address indexed user,
        uint256 poolInAmount,
        uint256 ethOutForLP
    );
    event BuyTwaAndAddLiquidityToUniswapV2(
        address indexed msgSender,
        uint256 totalAmount,
        uint256 ethAmount,
        uint256 twaAmount
    );
    event Erc20ToLunaSwap(
        address indexed user,
        address indexed swapToken,
        uint256 erc20InAmount,
        uint256 ethInAmount,
        uint256 poolOutAmount
    );
    event LunaToErc20Swap(
        address indexed user,
        address indexed swapToken,
        uint256 poolInAmount,
        uint256 ethOutAmount,
        uint256 erc20OutAmount
    );
    event PayoutTWA(address indexed receiver, uint256 wethAmount, uint256 twaAmount);

    constructor(
        address _weth,
        address _univ2,
        address _twa,
        address _lunaBP
    ) Ownable() {
        weth = TokenInterface(_weth);
        univ2 = TokenInterface(_univ2);
        twa = TokenInterface(_twa);
        lunaBP = BPoolInterface(_lunaBP);
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        defaultSlippage = 0.04 ether;
    }

    receive() external payable {
        if (msg.sender != tx.origin) {
            return;
        }
        swapEthToLuna(defaultSlippage);
    }

    function setTokensSettings(
        address[] memory _tokens,
        address[] memory _pairs,
        bool[] memory _reapprove
    ) external onlyOwner {
        uint256 len = _tokens.length;
        require(len == _pairs.length && len == _reapprove.length, "LENGTHS_NOT_EQUAL");
        for (uint256 i = 0; i < len; i++) {
            _setUniswapSettingAndPrepareToken(_tokens[i], _pairs[i]);
            reApproveTokens[_tokens[i]] = _reapprove[i];
            emit SetTokenSetting(_tokens[i], _reapprove[i], _pairs[i]);
        }
    }

    function fetchUnswapPairsFromFactory(address _factory, address[] calldata _tokens) external onlyOwner {
        uint256 len = _tokens.length;
        for (uint256 i = 0; i < len; i++) {
            _setUniswapSettingAndPrepareToken(_tokens[i], IUniswapV2Factory(_factory).getPair(_tokens[i], address(weth)));
        }
    }
    
    function setDefaultSlippage(uint256 _defaultSlippage) external onlyOwner {
        defaultSlippage = _defaultSlippage;
        emit SetDefaultSlippage(_defaultSlippage);
    }

    // swap eth to luna fund tokens contain eth-twa lp, weth, uni, link, renBTC
    function swapEthToLuna(uint256 _slippage) public payable returns (uint256, uint256) {
        address[] memory tokens = lunaBP.getCurrentTokens();
        (, uint256[] memory ethInUniswap, ) = calcSwapEthToLunaInputs(msg.value, tokens, _slippage);
        uint256 ethForLP = ethInUniswap[0];
        weth.deposit{ value: msg.value }();
        return _swapWethToLunaByPoolOut(msg.value, ethForLP);
    }

    function swapErc20ToLuna(
        address _swapToken,
        uint256 _swapAmount,
        uint256 _slippage
    ) external returns (uint256 poolAmountOut) {
        IERC20(_swapToken).safeTransferFrom(msg.sender, address(this), _swapAmount);
        _swapTokenForWethOut(_swapToken, _swapAmount);
        uint256 ethAmount = weth.balanceOf(address(this));
        address[] memory tokens = lunaBP.getCurrentTokens();
        uint256[] memory ethInUniswap;
        (, ethInUniswap, poolAmountOut) = calcSwapEthToLunaInputs(ethAmount, tokens, _slippage);
        uint256 ethForLp = ethInUniswap[0];
        _swapWethToLunaByPoolOut(ethAmount, ethForLp);

        emit Erc20ToLunaSwap(msg.sender, _swapToken, _swapAmount, ethAmount, poolAmountOut);
    }

    function swapLunaToEth(uint256 _poolAmountIn) external returns (uint256 ethOutAmount) {
        uint256 ethOutForLP = _swapLunaToWeth(_poolAmountIn);
        ethOutAmount = weth.balanceOf(address(this));
        weth.withdraw(ethOutAmount);
        ethOutAmount = badd(ethOutAmount, ethOutForLP);
        msg.sender.transfer(ethOutAmount);
    }

    function swapLunaToErc20(
        address _swapToken,
        uint256 _poolAmountIn
    ) external returns (uint256 erc20Out) {
        uint256 ethOutForLP = _swapLunaToWeth(_poolAmountIn);
        weth.deposit{ value: ethOutForLP }();
        uint256 ethOut = weth.balanceOf(address(this));
        _swapWethForTokenOut(_swapToken, ethOut);
        erc20Out = TokenInterface(_swapToken).balanceOf(address(this));
        IERC20(_swapToken).safeTransfer(msg.sender, erc20Out);

        emit LunaToErc20Swap(msg.sender, _swapToken, _poolAmountIn, ethOut, erc20Out);
    }

    function calcNeedEthToPoolOut(uint256 _poolAmountOut, uint256 _slippage) public view returns (uint256 ethAmountIn) {
        uint256 ratio = bdiv(_poolAmountOut, lunaBP.totalSupply());

        address[] memory tokens = lunaBP.getCurrentTokens();
        uint256 len = tokens.length;
        uint256[] memory tokensInLuna = new uint256[](len);

        uint256 totalEthSwap = 0;
        for (uint256 i = 0; i < len; i++) {
            tokensInLuna[i] = bmul(ratio, lunaBP.getBalance(tokens[i]));
            if (tokens[i] == address(weth)) {
                totalEthSwap = badd(totalEthSwap, tokensInLuna[i]);
            } else {
                if (tokens[i] == address(univ2)) {
                    totalEthSwap = badd(totalEthSwap, calcEthReserveOutByLPIn(address(twa), tokensInLuna[i]));
                } else {
                    totalEthSwap = badd(totalEthSwap, getAmountInForUniswapValue(_uniswapPairFor(tokens[i]), tokensInLuna[i], true));
                }
            }
        }
        uint256 slippageAmount = bmul(_slippage, totalEthSwap);
        ethAmountIn = badd(totalEthSwap, slippageAmount);
    }

    function calcNeedErc20ToPoolOut(
        address _swapToken,
        uint256 _poolAmountOut,
        uint256 _slippage
    ) external view returns (uint256) {
        uint256 resultEth = calcNeedEthToPoolOut(_poolAmountOut, _slippage);
        IUniswapV2Pair tokenPair = _uniswapPairFor(_swapToken);
        (uint256 token1Reserve, uint256 token2Reserve, ) = tokenPair.getReserves();
        if (tokenPair.token0() == address(weth)) {
            return UniswapV2Library.getAmountIn(resultEth.mul(1003).div(1000), token2Reserve, token1Reserve);
        } else {
            return UniswapV2Library.getAmountIn(resultEth.mul(1003).div(1000), token1Reserve, token2Reserve);
        }
    }
    
    // swap eth to eth-twa lp, weth, uni, link, renBTC
    function calcSwapEthToLunaInputs(
        uint256 _ethValue,
        address[] memory _tokens,
        uint256 _slippage
    ) public view returns (uint256[] memory tokensInLuna, uint256[] memory ethInUniswap, uint256 poolOut) {
        uint256 slippageEth = bmul(_ethValue, _slippage);
        uint256 ethValue = bsub(_ethValue, slippageEth);

        // get shares and eth required for each share
        CalculationStruct[] memory calculations = new CalculationStruct[](_tokens.length);
        address firstToken = _tokens[0];
        uint256 firstTokenBalance = lunaBP.getBalance(firstToken);
        uint256 totalEthRequired = 0;
        {
            uint256 poolRatio = bdiv(1 ether, firstTokenBalance);
            for (uint256 i = 0; i < _tokens.length; i++) {
                // token share relatively 1 ether of first token
                address ithToken = _tokens[i];
                calculations[i].tokenAmount = bmul(poolRatio, lunaBP.getBalance(ithToken));

                if (ithToken == address(weth)) {
                    calculations[i].ethAmount = calculations[i].tokenAmount;
                } else {
                    if (ithToken == address(univ2)) {
                        uint256 ethAmountForLPIn = calcEthReserveOutByLPIn(address(twa), calculations[i].tokenAmount);
                        calculations[i].ethAmount = bmul(ethAmountForLPIn, 2 ether);
                    } else {
                        calculations[i].ethAmount = getAmountInForUniswapValue(
                            _uniswapPairFor(_tokens[i]),
                            calculations[i].tokenAmount,
                            true
                        );
                    }
                }
                totalEthRequired = badd(totalEthRequired, calculations[i].ethAmount);
            }
        }

        // calculate eth and tokensIn based on shares and normalize if totalEthRequired more than 100%
        tokensInLuna = new uint256[](_tokens.length);
        ethInUniswap = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 ethRatio = bdiv(calculations[i].ethAmount, totalEthRequired);
            ethInUniswap[i] = bmul(ethValue, ethRatio);
            tokensInLuna[i] = bmul(calculations[i].tokenAmount, bdiv(ethValue, totalEthRequired));
        }
        uint256 ratio = bdiv(tokensInLuna[0], firstTokenBalance);
        poolOut = bmul(ratio, lunaBP.totalSupply());
    }

    function calcSwapErc20ToLunaInputs(
        address _swapToken,
        uint256 _swapAmount,
        address[] memory _tokens,
        uint256 _slippage
    ) external view returns (uint256[] memory tokensInLuna, uint256[] memory ethInUniswap, uint256 poolOut) {
        uint256 ethAmount = getAmountOutForUniswapValue(_uniswapPairFor(_swapToken), _swapAmount, true);
        return calcSwapEthToLunaInputs(ethAmount, _tokens, _slippage);
    }

    function calcSwapLunaToEthInputs(
        uint256 _poolAmountIn,
        address[] memory _tokens
    ) public view returns (uint256[] memory tokensOutLuna, uint256[] memory ethOutUniswap, uint256 totalEthOut) {
        tokensOutLuna = new uint256[](_tokens.length);
        ethOutUniswap = new uint256[](_tokens.length);

        uint256 poolRatio = bdiv(_poolAmountIn, lunaBP.totalSupply());

        totalEthOut = 0;
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokensOutLuna[i] = bmul(poolRatio, lunaBP.getBalance(_tokens[i]));
            if (_tokens[i] == address(weth)) {
                ethOutUniswap[i] = tokensOutLuna[i];
            } else {
                if (_tokens[i] == address(univ2)) {
                    ethOutUniswap[i] = calcEthReserveOutByLPIn(address(twa), tokensOutLuna[i]);
                } else {
                    ethOutUniswap[i] = getAmountOutForUniswapValue(_uniswapPairFor(_tokens[i]), tokensOutLuna[i], true);
                }
            }
            totalEthOut = totalEthOut.add(ethOutUniswap[i]);
        }
    }

    function calcSwapLunaToErc20Inputs(
        address _swapToken,
        uint256 _poolAmountIn,
        address[] memory _tokens
    ) external view returns (uint256[] memory tokensOutLuna, uint256[] memory ethOutUniswap, uint256 totalErc20Out) {
        uint256 totalEthOut;

        (tokensOutLuna, ethOutUniswap, totalEthOut) = calcSwapLunaToEthInputs(_poolAmountIn, _tokens);
        (uint256 tokenReserve, uint256 ethReserve, ) = _uniswapPairFor(_swapToken).getReserves();
        totalErc20Out = UniswapV2Library.getAmountOut(totalEthOut, ethReserve, tokenReserve);
    }

    function calcEthReserveOutByLPIn(address _token, uint256 lpAmountIn) public view returns(uint256) {
        uint256 lpTotalSupply = _uniswapPairFor(_token).totalSupply();
        (, uint256 ethReserve, ) = _uniswapPairFor(_token).getReserves();

        return ethReserve.mul(lpAmountIn).div(lpTotalSupply);
    }

    // swap weth to Luna tokens
    // Odd ether will return back to sender
    function _swapWethToLunaByPoolOut(
        uint256 _wethAmount,
        uint256 _ethForLp
    ) internal returns (uint256, uint256) {
        require(_wethAmount > 0, "ETH_REQUIRED");
        uint256 ethForLp = _ethForLp;

        address[] memory tokens = lunaBP.getCurrentTokens();
        (uint256[] memory tokensInLuna, uint256 totalEthSwap, uint256 poolAmountOut)
            = _prepareTokensForJoin(tokens, ethForLp);

        lunaBP.joinPool(poolAmountOut, tokensInLuna);
        lunaBP.safeTransfer(msg.sender, poolAmountOut);

        uint256 oddEth = weth.balanceOf(address(this));
        weth.withdraw(oddEth);
        msg.sender.transfer(oddEth);
        emit OddEth(msg.sender, oddEth);

        uint256 oddLP = univ2.balanceOf(address(this));

        if (oddLP > 0 ) {
            univ2.transfer(msg.sender, oddLP);
        }

        return (poolAmountOut, totalEthSwap);
    }

    // prepare the joining to balancer pool
    function _prepareTokensForJoin(address[] memory _tokens, uint256 _ethForLp)
        internal
        returns (uint256[] memory tokensInLuna, uint256 totalEthSwap, uint256 poolAmountOut)
    {
        uint256 len = _tokens.length;
        tokensInLuna = new uint256[](len);
        // buy twa and add twa-eth liquidity into Uniswap
        // and get LP token
        require(_tokens[0] == address(univ2), "First token must be TWA-ETH LP token");
        (, uint256 ethAmountIn, uint256 liquidity) = buyTwaAndAddLiquidityToUniswapV2(_ethForLp);
        totalEthSwap = badd(totalEthSwap, ethAmountIn);
        uint256 lunaTotalSupply = lunaBP.totalSupply();
        uint256 ratioLiquidity = liquidity.sub(1e3);
        uint256 poolRatio = bdiv(ratioLiquidity, lunaBP.getBalance(_tokens[0]));

        for (uint256 i = 0; i < len; i++) {
            tokensInLuna[i] = bmul(poolRatio, lunaBP.getBalance(_tokens[i]));

            if (_tokens[i] == address(weth)) {
                totalEthSwap = badd(totalEthSwap, tokensInLuna[i]);
            } else {
                if (_tokens[i] != address(univ2)) {
                    totalEthSwap = badd(totalEthSwap, _swapWethForTokenIn(_tokens[i], tokensInLuna[i]));
                }
            }
            if (reApproveTokens[_tokens[i]]) {
                TokenInterface(_tokens[i]).approve(address(lunaBP), 0);
            }
            TokenInterface(_tokens[i]).approve(address(lunaBP), tokensInLuna[i]);
        }

        poolAmountOut = bmul(poolRatio, lunaTotalSupply);
    }
    
    function _swapLunaToWeth(uint256 _poolAmountIn) internal returns (uint256 ethOutForLP) {
        address[] memory tokens = lunaBP.getCurrentTokens();
        uint256 len = tokens.length;

        (uint256[] memory tokensOutLuna, ,) = calcSwapLunaToEthInputs(_poolAmountIn, tokens);

        lunaBP.safeTransferFrom(msg.sender, address(this), _poolAmountIn);
        lunaBP.approve(address(lunaBP), _poolAmountIn);
        lunaBP.exitPool(_poolAmountIn, tokensOutLuna);

        for (uint256 i = 0; i < len; i++) {
            if (tokens[i] == address(univ2)) {
                tokensOutLuna[i] = univ2.balanceOf(address(this));
                _uniswapPairFor(address(twa)).approve(address(uniswapV2Router), tokensOutLuna[i]);
                ethOutForLP = uniswapV2Router.removeLiquidityETHSupportingFeeOnTransferTokens(
                    address(twa),
                    tokensOutLuna[i],
                    0,
                    0,
                    address(this),
                    block.timestamp
                );
                _swapTokenForWethOut(address(twa), twa.balanceOf(address(this)));
            } else {
                if (tokens[i] != address(weth)) {
                    tokensOutLuna[i] = TokenInterface(tokens[i]).balanceOf(address(this));
                    _swapTokenForWethOut(tokens[i], tokensOutLuna[i]);
                }
            }
        }

        emit LunaToEthSwap(msg.sender, _poolAmountIn, ethOutForLP);
    }

    function buyTwaAndAddLiquidityToUniswapV2(
        uint256 _ethAmountIn
    ) public returns (uint256 tokenAmountOut, uint256 ethAmountOut, uint256 liquidity) {
        uint256 ethAmountForSwap = _ethAmountIn.div(2);

        _swapWethForTokenOut(address(twa), ethAmountForSwap);
        uint256 twaTokenAmount = twa.balanceOf(address(this));

        twa.approve(address(uniswapV2Router), twaTokenAmount);
        uint256 ethAmountForAddLiquidity = getAmountInForUniswapValue(_uniswapPairFor(address(twa)), twaTokenAmount, true);
        weth.withdraw(ethAmountForAddLiquidity);

        // add liquidity to uniswap
        (tokenAmountOut, ethAmountOut, liquidity) = uniswapV2Router.addLiquidityETH{ value: ethAmountForAddLiquidity } (
            address(twa),
            twaTokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
        if (ethAmountForAddLiquidity > ethAmountOut) {
            weth.deposit{ value: bsub(ethAmountForAddLiquidity, ethAmountOut) }();
        }
        ethAmountOut = badd(ethAmountOut, ethAmountForSwap);

        emit BuyTwaAndAddLiquidityToUniswapV2(_msgSender(), _ethAmountIn, ethAmountOut, tokenAmountOut);
    }

    function getAmountInForUniswap(
        IUniswapV2Pair _tokenPair,
        uint256 _swapAmount,
        bool _isEthIn
    ) public view returns (uint256 amountIn, bool isInverse) {
        isInverse = uniswapEthPairToken0[address(_tokenPair)] == address(weth);
        if (_isEthIn ? !isInverse : isInverse) {
            (uint256 ethReserve, uint256 tokenReserve, ) = _tokenPair.getReserves();
            amountIn = UniswapV2Library.getAmountIn(_swapAmount, tokenReserve, ethReserve);
        } else {
            (uint256 tokenReserve, uint256 ethReserve, ) = _tokenPair.getReserves();
            amountIn = UniswapV2Library.getAmountIn(_swapAmount, tokenReserve, ethReserve);
        }
    }

    function getAmountInForUniswapValue(
        IUniswapV2Pair _tokenPair,
        uint256 _swapAmount,
        bool _isEthIn
    ) public view returns (uint256 amountIn) {
        (amountIn, ) = getAmountInForUniswap(_tokenPair, _swapAmount, _isEthIn);
    }

    function getAmountOutForUniswap(
        IUniswapV2Pair _tokenPair,
        uint256 _swapAmount,
        bool _isEthOut
    ) public view returns (uint256 amountOut, bool isInverse) {
        isInverse = uniswapEthPairToken0[address(_tokenPair)] == address(weth);
        if (_isEthOut ? isInverse : !isInverse) {
            (uint256 ethReserve, uint256 tokenReserve, ) = _tokenPair.getReserves();
            amountOut = UniswapV2Library.getAmountOut(_swapAmount, tokenReserve, ethReserve);
        } else {
            (uint256 tokenReserve, uint256 ethReserve, ) = _tokenPair.getReserves();
            amountOut = UniswapV2Library.getAmountOut(_swapAmount, tokenReserve, ethReserve);
        }
    }

    function getAmountOutForUniswapValue(
        IUniswapV2Pair _tokenPair,
        uint256 _swapAmount,
        bool _isEthOut
    ) public view returns (uint256 ethAmount) {
        (ethAmount, ) = getAmountOutForUniswap(_tokenPair, _swapAmount, _isEthOut);
    }

    function _setUniswapSettingAndPrepareToken(address _token, address _pair) internal {
        uniswapEthPairByTokenAddress[_token] = _pair;
        uniswapEthPairToken0[_pair] = IUniswapV2Pair(_pair).token0();
    }

    function _uniswapPairFor(address token) internal view returns (IUniswapV2Pair) {
        return IUniswapV2Pair(uniswapEthPairByTokenAddress[token]);
    }

    function _swapWethForTokenIn(address _erc20, uint256 _erc20Out) internal returns (uint256 ethIn) {
        IUniswapV2Pair tokenPair = _uniswapPairFor(_erc20);
        bool isInverse;
        (ethIn, isInverse) = getAmountInForUniswap(tokenPair, _erc20Out, true);
        weth.safeTransfer(address(tokenPair), ethIn);
        tokenPair.swap(isInverse ? uint256(0) : _erc20Out, isInverse ? _erc20Out : uint256(0), address(this), new bytes(0));
    }

    function _swapWethForTokenOut(address _erc20, uint256 _ethIn) internal returns (uint256 erc20Out) {
        IUniswapV2Pair tokenPair = _uniswapPairFor(_erc20);
        bool isInverse;
        (erc20Out, isInverse) = getAmountOutForUniswap(tokenPair, _ethIn, false);
        weth.safeTransfer(address(tokenPair), _ethIn);
        tokenPair.swap(isInverse ? uint256(0) : erc20Out, isInverse ? erc20Out : uint256(0), address(this), new bytes(0));
    }

    function _swapTokenForWethOut(address _erc20, uint256 _erc20In) internal returns (uint256 ethOut) {
        IUniswapV2Pair tokenPair = _uniswapPairFor(_erc20);
        bool isInverse;
        (ethOut, isInverse) = getAmountOutForUniswap(tokenPair, _erc20In, true);
        IERC20(_erc20).safeTransfer(address(tokenPair), _erc20In);
        tokenPair.swap(isInverse ? ethOut : uint256(0), isInverse ? uint256(0) : ethOut, address(this), new bytes(0));
    }
}