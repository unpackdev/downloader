// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/math/SafeMath.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


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
        assembly {size := extcodesize(account)}
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
        (bool success,) = recipient.call{value : amount}("");
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
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


pragma solidity ^0.6.0;




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
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/utils/EnumerableSet.sol


pragma solidity ^0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {// Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1;
            // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.6.0;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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
    constructor (string memory name, string memory symbol) public {
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
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
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
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// File: contracts/token/MyERC20Token.sol

pragma solidity ^0.6.0;


contract MyERC20Token is ERC20, Ownable {

    address public minter;
    address public burner;

    constructor (string memory name, string memory symbol, address _minter, address _burner) public ERC20(name, symbol) {
        minter = _minter;
        burner = _burner;
    }

    function setBurner(address _newBurner) external onlyOwner {
        burner = _newBurner;
    }

    function mint(address _to, uint256 _amount) public {
        require(msg.sender == minter, "Only minter can mint this token");
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) public {
        require(msg.sender == burner, "Only burner can burn this token");
        _burn(msg.sender, _amount);
    }

}

// File: contracts/token/IronToken.sol

pragma solidity >=0.5.0;


contract IronToken is MyERC20Token {
    constructor (address _minter, address _burner) public MyERC20Token("Dungeon Iron", "IRON", _minter, _burner) {}
}

// File: contracts/token/KnightToken.sol

pragma solidity >=0.5.0;


contract KnightToken is MyERC20Token {
    constructor (address _minter, address _burner) public MyERC20Token("Dungeon Knight", "KNIGHT", _minter, _burner) {}
}

// File: contracts/DungeonMaster.sol

pragma solidity >=0.5.0;


contract DungeonMaster is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ------------- normal pool variables and structs ----------------------

    struct NormalUserInfo {
        uint256 amountStaked;
        uint256 debt;
    }

    // Info of each pool.
    struct NormalPoolInfo {
        IERC20 stakeToken;
        MyERC20Token receiveToken;
        uint256 stakedSupply;
        uint256 uncollectedAmount;
        uint256 rewardPerBlock;
        uint256 stakeChestAmount;
        uint256 receiveChestAmount;
        uint256 lastUpdateBlock;
        uint256 accumulatedRewardPerStake; // is in 1e12 to allow for cases where stake supply is more than block reward
    }

    // Info of each normal pool.
    NormalPoolInfo[] public normalPoolInfo;
    // Info of each user that stakes tokens in normal pool
    mapping(uint256 => mapping(address => NormalUserInfo)) public normalUserInfo;

    // ------------- burn pool variables and structs ----------------------

    struct BurnUserInfo {
        uint256 amountStaked;
        uint256 startBlock;

        // reward is calculated by (currentBlock - startBlock) / blockrate * rewardRate
        // burn is calculated by (currentBlock - startBlock) / blockrate * burnRate
        // if all stake burned reward is amountStaked / burnRate * rewardRate (which would be the maximum reward possible
        // and is useful for pending function)
    }

    // Info of each pool.
    struct BurnPoolInfo {
        MyERC20Token burningStakeToken;
        MyERC20Token receiveToken;
        uint256 blockRate; // reward is created every x blocks
        uint256 rewardRate; // reward distributed per blockrate
        uint256 burnRate; // token burned per blockrate
        uint256 stakeChestAmount;
        uint256 receiveChestAmount;
    }

    // Info of each burn pool.
    BurnPoolInfo[] public burnPoolInfo;
    // Info of each user that stakes and burns tokens in burn pool
    mapping(uint256 => mapping(address => BurnUserInfo)) public burnUserInfo;

    // ------------- multi burn pool variables and structs ----------------------

    struct MultiBurnUserInfo {
        uint256 amountStakedOfEach;
        uint256 startBlock;

        // reward is calculated by (currentBlock - startBlock) / blockrate * rewardRate
        // burn is calculated by (currentBlock - startBlock) / blockrate * burnRate
        // if all stake burned reward is amountStaked / burnRate * rewardRate (which would be the maximum reward possible
        // and is useful for pending function)
    }

    // Info of each pool.
    struct MultiBurnPoolInfo {
        MyERC20Token[] burningStakeTokens;
        MyERC20Token receiveToken;
        uint256 blockRate; // reward is created every x blocks
        uint256 rewardRate; // reward distributed per blockrate
        uint256 burnRate; // token burned per blockrate
        uint256 stakeChestAmount;
    }

    // Info of each burn pool.
    MultiBurnPoolInfo[] public multiBurnPoolInfo;
    // Info of each user that stakes and burns tokens in burn pool
    mapping(uint256 => mapping(address => MultiBurnUserInfo)) public multiBurnUserInfo;

    // ------------- raid variables and structs ----------------------

    uint256 public raidBlock;
    uint256 public raidFrequency;
    uint256 public returnIfNotInRaidPercentage = 25; // 25% of knights will return if you miss the raid block
    uint256 public raidWinLootPercentage = 25; // 25% of chest will be rewarded based on knights provided
    uint256 public raidWinPercentage = 5; // 5% of total supplied knights must be in raid to win

    address[] public participatedInRaid;

    mapping(address => uint256)[] public knightsProvidedInRaid;
    mapping(address => uint256) public raidShare;

    // -------------------------------------------------------------------------------------

    bool public votingActive = false;
    uint256 public voted = 0;
    address[] public voters;
    mapping(address => uint256) voteAmount;

    address public devaddr;
    uint public depositChestFee = 25;
    uint public chestRewardPercentage = 500;

    uint256 public startBlock;
    KnightToken public knightToken;

    constructor(
        address _devaddr,
        uint256 _startBlock,
        uint256 _depositChestFee
    ) public {
        devaddr = _devaddr;
        startBlock = _startBlock;
        depositChestFee = _depositChestFee;
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    // Set the percentage of the deposit amount going into the chest; max 1%
    function setDepositChestFee(uint256 _depositChestFee) public onlyOwner {
        require(_depositChestFee <= 100, "deposit chest fee can be max 1%");
        depositChestFee = _depositChestFee;
    }

    // Set the percentage of the collected amount going into the chest is in * 0.01%
    function setChestRewardPercentage(uint256 _chestRewardPercentage) public onlyOwner {
        require(_chestRewardPercentage <= 1000, "chest reward percentage can be max 10%");
        chestRewardPercentage = _chestRewardPercentage;
    }

    function setKnightToken(KnightToken _knight) public onlyOwner {
        knightToken = _knight;
    }

    // Set the percentage of the chest which is distributed to the raid participants; min 10%
    function setRaidWinLootPercentage(uint256 _percentage) public onlyOwner {
        require(_percentage >= 10, "minimum of 10% must be distributed");
        raidWinLootPercentage = _percentage;
    }

    // Set the percentage of the total supply of knights which must take part in the raid to win; max 50%
    function setRaidWinPercentage(uint256 _percentage) public onlyOwner {
        require(_percentage <= 50, "maximum of 50% must take part");
        raidWinPercentage = _percentage;
    }

    function getBlocks(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    function isStarted() public view returns (bool) {
        return startBlock <= block.number;
    }

    //    ---------------- Normal Pool Methods -------------------------------

    function addNormalPool(IERC20 _stakeToken, MyERC20Token _receiveToken, uint256 _rewardPerBlock) public onlyOwner {
        uint256 lastUpdateBlock = block.number > startBlock ? block.number : startBlock;
        normalPoolInfo.push(NormalPoolInfo(_stakeToken, _receiveToken, 0, 0, _rewardPerBlock.mul(1e18), 0, 0, lastUpdateBlock, 0));
    }

    function normalPoolLength() external view returns (uint256) {
        return normalPoolInfo.length;
    }

    function normalPending(uint256 _pid, address _user) external view returns (uint256, IERC20) {
        NormalPoolInfo storage pool = normalPoolInfo[_pid];
        NormalUserInfo storage user = normalUserInfo[_pid][_user];
        uint256 rewardPerStake = pool.accumulatedRewardPerStake;
        if (block.number > pool.lastUpdateBlock && pool.stakedSupply != 0) {
            uint256 blocks = getBlocks(pool.lastUpdateBlock, block.number);
            uint256 reward = pool.rewardPerBlock.mul(blocks);
            rewardPerStake = rewardPerStake.add(reward.mul(1e12).div(pool.stakedSupply));
        }
        return (user.amountStaked.mul(rewardPerStake).div(1e12).sub(user.debt), pool.receiveToken);
    }

    function updateNormalPool(uint256 _pid) public {
        NormalPoolInfo storage pool = normalPoolInfo[_pid];
        if (block.number <= pool.lastUpdateBlock) {
            return;
        }
        if (pool.stakedSupply == 0) {
            pool.lastUpdateBlock = block.number;
            return;
        }
        uint256 blocks = getBlocks(pool.lastUpdateBlock, block.number);
        uint256 reward = blocks.mul(pool.rewardPerBlock);
        // reward * (1 - 0,05 - chestRewardPercentage)
        uint256 poolReward = reward.mul(10000 - 500 - chestRewardPercentage).div(10000);
        pool.receiveToken.mint(address(this), poolReward);
        // 5% goes to dev address
        pool.receiveToken.mint(devaddr, reward.mul(5).div(100));
        pool.receiveChestAmount = pool.receiveChestAmount.add(reward.mul(chestRewardPercentage).div(10000));
        pool.receiveToken.mint(address(this), reward.mul(chestRewardPercentage).div(10000));
        pool.uncollectedAmount = pool.uncollectedAmount.add(poolReward);
        pool.accumulatedRewardPerStake = pool.accumulatedRewardPerStake.add(poolReward.mul(1e12).div(pool.stakedSupply));
        pool.lastUpdateBlock = block.number;
    }

    function depositNormalPool(uint256 _pid, uint256 _amount) public {
        require(startBlock <= block.number, "not yet started.");

        NormalPoolInfo storage pool = normalPoolInfo[_pid];
        NormalUserInfo storage user = normalUserInfo[_pid][msg.sender];
        updateNormalPool(_pid);

        // collect farmed token if user has already staked
        if (user.amountStaked > 0) {
            uint256 pending = user.amountStaked.mul(pool.accumulatedRewardPerStake).div(1e12).sub(user.debt);
            require(pool.uncollectedAmount >= pending, "not enough uncollected tokens anymore");
            pool.receiveToken.transfer(address(msg.sender), pending);
            pool.uncollectedAmount = pool.uncollectedAmount - pending;
        }
        pool.stakeToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint256 chestAmount = _amount.mul(depositChestFee).div(10000);
        user.amountStaked = user.amountStaked.add(_amount).sub(chestAmount);
        pool.stakedSupply = pool.stakedSupply.add(_amount.sub(chestAmount));
        pool.stakeChestAmount = pool.stakeChestAmount.add(chestAmount);
        user.debt = user.amountStaked.mul(pool.accumulatedRewardPerStake).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdrawNormalPool(uint256 _pid, uint256 _amount) public {
        NormalPoolInfo storage pool = normalPoolInfo[_pid];
        NormalUserInfo storage user = normalUserInfo[_pid][msg.sender];
        require(user.amountStaked >= _amount, "withdraw: not good");
        updateNormalPool(_pid);

        // collect farmed token
        uint256 pending = user.amountStaked.mul(pool.accumulatedRewardPerStake).div(1e12).sub(user.debt);
        require(pool.uncollectedAmount >= pending, "not enough uncollected tokens anymore");
        pool.receiveToken.transfer(address(msg.sender), pending);
        pool.uncollectedAmount = pool.uncollectedAmount - pending;

        user.amountStaked = user.amountStaked.sub(_amount);
        user.debt = user.amountStaked.mul(pool.accumulatedRewardPerStake).div(1e12);
        pool.stakeToken.safeTransfer(address(msg.sender), _amount);
        pool.stakedSupply = pool.stakedSupply.sub(_amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function emergencyWithdrawNormalPool(uint256 _pid) public {
        NormalPoolInfo storage pool = normalPoolInfo[_pid];
        NormalUserInfo storage user = normalUserInfo[_pid][msg.sender];
        emit EmergencyWithdraw(msg.sender, _pid, user.amountStaked);
        pool.stakedSupply = pool.stakedSupply.sub(user.amountStaked);
        pool.stakeToken.safeTransfer(address(msg.sender), user.amountStaked);
        user.amountStaked = 0;
    }

    function collectNormalPool(uint256 _pid) public {
        NormalPoolInfo storage pool = normalPoolInfo[_pid];
        NormalUserInfo storage user = normalUserInfo[_pid][msg.sender];
        updateNormalPool(_pid);
        uint256 pending = user.amountStaked.mul(pool.accumulatedRewardPerStake).div(1e12).sub(user.debt);
        require(pool.uncollectedAmount >= pending, "not enough uncollected tokens anymore");
        pool.receiveToken.transfer(address(msg.sender), pending);
        pool.uncollectedAmount = pool.uncollectedAmount.sub(pending);
        user.debt = user.amountStaked.mul(pool.accumulatedRewardPerStake).div(1e12);
    }

    //    ----------------------------- Burn Pool Methods --------------------------------------------

    function addBurnPool(MyERC20Token _stakeToken, MyERC20Token _receiveToken, uint256 _blockRate, uint256 _rewardRate, uint256 _burnRate) public onlyOwner {
        // reward and burn rate is in * 0.001
        burnPoolInfo.push(BurnPoolInfo(_stakeToken, _receiveToken, _blockRate, _rewardRate.mul(1e15), _burnRate.mul(1e15), 0, 0));
    }

    function burnPoolLength() external view returns (uint256) {
        return burnPoolInfo.length;
    }

    function burnPending(uint256 _pid, address _user) external view returns (uint256, uint256, IERC20) {
        BurnPoolInfo storage pool = burnPoolInfo[_pid];
        BurnUserInfo storage user = burnUserInfo[_pid][_user];
        uint256 blocks = getBlocks(user.startBlock, block.number);
        uint256 ticks = blocks.div(pool.blockRate);
        uint256 burned = ticks.mul(pool.burnRate);
        uint256 reward = 0;
        if (burned > user.amountStaked) {
            reward = user.amountStaked.mul(1e5).div(pool.burnRate).mul(pool.rewardRate).div(1e5);
            burned = user.amountStaked;
        }
        else {
            reward = ticks.mul(pool.rewardRate);
        }
        return (reward, burned, pool.receiveToken);
    }

    function depositBurnPool(uint256 _pid, uint256 _amount) public {
        require(startBlock <= block.number, "not yet started.");

        BurnPoolInfo storage pool = burnPoolInfo[_pid];
        BurnUserInfo storage user = burnUserInfo[_pid][msg.sender];

        // collect farmed token if user has already staked
        if (user.amountStaked > 0) {
            collectBurnPool(_pid);
        }
        pool.burningStakeToken.transferFrom(address(msg.sender), address(this), _amount);
        uint256 chestAmount = _amount.mul(depositChestFee).div(10000);
        pool.stakeChestAmount = pool.stakeChestAmount.add(chestAmount);
        user.amountStaked = user.amountStaked.add(_amount).sub(chestAmount);
        user.startBlock = block.number;
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdrawBurnPool(uint256 _pid, uint256 _amount) public {
        BurnPoolInfo storage pool = burnPoolInfo[_pid];
        BurnUserInfo storage user = burnUserInfo[_pid][msg.sender];

        // collect farmed token
        collectBurnPool(_pid);

        if (user.amountStaked < _amount) {
            _amount = user.amountStaked;
            // withdraw all of stake
        }
        user.amountStaked = user.amountStaked.sub(_amount);
        pool.burningStakeToken.transfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function collectBurnPool(uint256 _pid) public returns (uint256) {
        BurnPoolInfo storage pool = burnPoolInfo[_pid];
        BurnUserInfo storage user = burnUserInfo[_pid][msg.sender];
        uint256 blocks = getBlocks(user.startBlock, block.number);
        uint256 ticks = blocks.div(pool.blockRate);
        uint256 burned = ticks.mul(pool.burnRate);
        uint256 reward = 0;
        if (burned > user.amountStaked) {
            reward = user.amountStaked.mul(1e5).div(pool.burnRate).mul(pool.rewardRate).div(1e5);
            burned = user.amountStaked;
            user.amountStaked = 0;
        }
        else {
            reward = ticks.mul(pool.rewardRate);
            user.amountStaked = user.amountStaked.sub(burned);
        }
        // burn token
        pool.burningStakeToken.burn(burned);

        uint256 userAmount = reward.mul(10000 - 500 - chestRewardPercentage).div(10000);
        uint256 chestAmount = reward.mul(chestRewardPercentage).div(10000);
        uint256 devAmount = reward.mul(500).div(10000);
        pool.receiveToken.mint(msg.sender, userAmount);
        pool.receiveToken.mint(address(this), chestAmount);
        pool.receiveToken.mint(devaddr, devAmount);
        pool.receiveChestAmount = pool.receiveChestAmount.add(chestAmount);
        user.startBlock = block.number;
        return (reward);
    }

    //    ----------------------------- Multi Burn Pool Methods --------------------------------------------

    function addMultiBurnPool(MyERC20Token[] memory _stakeTokens, MyERC20Token _receiveToken, uint256 _blockRate, uint256 _rewardRate, uint256 _burnRate) public onlyOwner {
        // reward and burn rate is in * 0.001
        multiBurnPoolInfo.push(MultiBurnPoolInfo(_stakeTokens, _receiveToken, _blockRate, _rewardRate.mul(1e15), _burnRate.mul(1e15), 0));
    }

    function multiBurnPoolLength() external view returns (uint256) {
        return multiBurnPoolInfo.length;
    }

    function multiBurnPending(uint256 _pid, address _user) external view returns (uint256, uint256, IERC20) {
        MultiBurnPoolInfo storage pool = multiBurnPoolInfo[_pid];
        MultiBurnUserInfo storage user = multiBurnUserInfo[_pid][_user];
        uint256 blocks = getBlocks(user.startBlock, block.number);
        uint256 ticks = blocks.div(pool.blockRate);
        uint256 burned = ticks.mul(pool.burnRate);
        uint256 reward = 0;
        if (burned > user.amountStakedOfEach) {
            reward = user.amountStakedOfEach.mul(1e5).div(pool.burnRate).mul(pool.rewardRate).div(1e5);
            burned = user.amountStakedOfEach;
        }
        else {
            reward = ticks.mul(pool.rewardRate);
        }
        return (reward, burned, pool.receiveToken);
    }

    function depositMultiBurnPool(uint256 _pid, uint256 _amount) public {
        require(startBlock <= block.number, "not yet started.");

        MultiBurnPoolInfo storage pool = multiBurnPoolInfo[_pid];
        MultiBurnUserInfo storage user = multiBurnUserInfo[_pid][msg.sender];

        // collect farmed token if user has already staked
        if (user.amountStakedOfEach > 0) {
            collectMultiBurnPool(_pid);
        }
        for (uint i = 0; i < pool.burningStakeTokens.length; i++) {
            MyERC20Token stakeToken = pool.burningStakeTokens[i];
            stakeToken.transferFrom(address(msg.sender), address(this), _amount);
        }
        uint256 chestAmount = _amount.mul(depositChestFee).div(10000);
        pool.stakeChestAmount = pool.stakeChestAmount.add(chestAmount);
        user.amountStakedOfEach = user.amountStakedOfEach.add(_amount).sub(chestAmount);
        user.startBlock = block.number;
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdrawMultiBurnPool(uint256 _pid, uint256 _amount) public {
        MultiBurnPoolInfo storage pool = multiBurnPoolInfo[_pid];
        MultiBurnUserInfo storage user = multiBurnUserInfo[_pid][msg.sender];
        updateNormalPool(_pid);

        // collect farmed token
        collectMultiBurnPool(_pid);

        if (user.amountStakedOfEach < _amount) {
            _amount = user.amountStakedOfEach;
            // withdraw all
        }

        user.amountStakedOfEach = user.amountStakedOfEach.sub(_amount);
        for (uint i = 0; i < pool.burningStakeTokens.length; i++) {
            MyERC20Token stakeToken = pool.burningStakeTokens[i];
            stakeToken.transfer(address(msg.sender), _amount);
        }
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function collectMultiBurnPool(uint256 _pid) public returns (uint256) {
        MultiBurnPoolInfo storage pool = multiBurnPoolInfo[_pid];
        MultiBurnUserInfo storage user = multiBurnUserInfo[_pid][msg.sender];
        uint256 blocks = getBlocks(user.startBlock, block.number);
        uint256 ticks = blocks.div(pool.blockRate);
        uint256 burned = ticks.mul(pool.burnRate);
        uint256 reward = 0;
        if (burned > user.amountStakedOfEach) {
            reward = user.amountStakedOfEach.mul(1e5).div(pool.burnRate).mul(pool.rewardRate).div(1e5);
            burned = user.amountStakedOfEach;
            user.amountStakedOfEach = 0;
        }
        else {
            reward = ticks.mul(pool.rewardRate);
            user.amountStakedOfEach = user.amountStakedOfEach.sub(burned);
        }
        // burn token
        for (uint i = 0; i < pool.burningStakeTokens.length; i++) {
            MyERC20Token token = pool.burningStakeTokens[i];
            token.burn(burned);
        }

        // nothing goes into chest
        uint256 userAmount = reward.mul(100 - 5).div(100);
        uint256 devAmount = reward.mul(5).div(100);
        pool.receiveToken.mint(msg.sender, userAmount);
        pool.receiveToken.mint(devaddr, devAmount);
        user.startBlock = block.number;
        return (reward);
    }

    //    ----------------------------- Raid Methods --------------------------------------------

    function allowRaids(uint256 _raidFrequency) public onlyOwner {
        raidFrequency = _raidFrequency;
        raidBlock = block.number.add(raidFrequency);
        knightsProvidedInRaid.push();
    }

    function joinRaid(uint256 _amount) public returns (bool) {
        require(startBlock <= block.number, "not yet started.");

        knightToken.transferFrom(address(msg.sender), address(this), _amount);
        if (block.number == raidBlock) {
            uint256 currentRaidId = knightsProvidedInRaid.length.sub(1);

            // can only join a raid once
            if (knightsProvidedInRaid[currentRaidId][msg.sender] != 0) {
                return false;
            }
            knightsProvidedInRaid[currentRaidId][msg.sender] = _amount;
            participatedInRaid.push(msg.sender);
            return true;
        }
        else {
            uint256 returnAmount = _amount.mul(returnIfNotInRaidPercentage).div(100);
            uint256 burnAmount = _amount.sub(returnAmount);
            knightToken.burn(burnAmount);
            knightToken.transfer(address(msg.sender), returnAmount);
            return false;
        }
    }

    function checkAndCalculateRaidShares() public {
        require(block.number > raidBlock, "raid not started!");
        uint256 totalKnights = 0;
        uint256 currentRaidId = knightsProvidedInRaid.length.sub(1);
        for (uint i = 0; i < participatedInRaid.length; i++) {
            address user = participatedInRaid[i];
            totalKnights = totalKnights.add(knightsProvidedInRaid[currentRaidId][user]);
        }
        // check if minimum amount of knights were in raid to win
        if (totalKnights < knightToken.totalSupply().div(raidWinPercentage)) {
            // minimum amount of knights not participated
            knightToken.burn(totalKnights);
            delete participatedInRaid;
            knightsProvidedInRaid.push();
            raidBlock = raidBlock.add(raidFrequency);
            return;
        }

        // calculate each users share times 1e12
        for (uint i = 0; i < participatedInRaid.length; i++) {
            address user = participatedInRaid[i];
            uint256 knights = knightsProvidedInRaid[currentRaidId][user];
            uint256 userShare = knights.mul(1e12).div(totalKnights);
            raidShare[user] = userShare;
        }

        // burn provided knights after shares have been calculated
        knightToken.burn(totalKnights);
        delete participatedInRaid;
        knightsProvidedInRaid.push();
        raidBlock = raidBlock.add(raidFrequency);
    }

    function claimRaidRewards() public {
        uint256 userShare = raidShare[msg.sender];
        address user = msg.sender;
        // distribute normal pool rewards
        for (uint j = 0; j < normalPoolInfo.length; j++) {
            NormalPoolInfo storage poolInfo = normalPoolInfo[j];
            uint256 stakeChestShare = poolInfo.stakeChestAmount.mul(userShare).div(1e12).mul(raidWinLootPercentage).div(100);
            uint256 receiveChestShare = poolInfo.receiveChestAmount.mul(userShare).div(1e12).mul(raidWinLootPercentage).div(100);
            poolInfo.stakeToken.transfer(user, stakeChestShare);
            poolInfo.receiveToken.transfer(user, receiveChestShare);
            poolInfo.stakeChestAmount = poolInfo.stakeChestAmount.sub(stakeChestShare);
            poolInfo.receiveChestAmount = poolInfo.receiveChestAmount.sub(receiveChestShare);
        }

        // distribute burn pool rewards
        for (uint j = 0; j < burnPoolInfo.length; j++) {
            BurnPoolInfo storage poolInfo = burnPoolInfo[j];
            uint256 stakeChestShare = poolInfo.stakeChestAmount.mul(userShare).div(1e12).mul(raidWinLootPercentage).div(100);
            uint256 receiveChestShare = poolInfo.receiveChestAmount.mul(userShare).div(1e12).mul(raidWinLootPercentage).div(100);
            poolInfo.burningStakeToken.transfer(user, stakeChestShare);
            poolInfo.receiveToken.transfer(user, receiveChestShare);
            poolInfo.stakeChestAmount = poolInfo.stakeChestAmount.sub(stakeChestShare);
            poolInfo.receiveChestAmount = poolInfo.receiveChestAmount.sub(receiveChestShare);
        }

        // distribute multi burn pool rewards
        for (uint j = 0; j < multiBurnPoolInfo.length; j++) {
            MultiBurnPoolInfo storage poolInfo = multiBurnPoolInfo[j];
            uint256 stakeChestShare = poolInfo.stakeChestAmount.mul(userShare).div(1e12).mul(raidWinLootPercentage).div(100);
            for (uint x = 0; x < poolInfo.burningStakeTokens.length; x++) {
                poolInfo.burningStakeTokens[x].transfer(user, stakeChestShare);
            }
            poolInfo.stakeChestAmount = poolInfo.stakeChestAmount.sub(stakeChestShare);
        }

        raidShare[msg.sender] = 0;
    }

    //    --------------------------------------------------------------------------------------------

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    function activateVoting() public onlyOwner {
        votingActive = true;
    }

    function vote(uint256 _amount) public {
        require(votingActive);
        // only allowed to vote once
        require(voteAmount[msg.sender] == 0);
        knightToken.transferFrom(address(msg.sender), address(this), _amount);
        voted = voted.add(_amount);
        voters.push(msg.sender);
        voteAmount[msg.sender] = _amount;
    }

    // expensive operation
    function drainChest() public onlyOwner {
        require(votingActive);
        // more than 10% of total supply must vote
        require(voted >= knightToken.totalSupply().div(10).mul(100));

        for (uint i = 0; i < voters.length; i++) {
            address user = voters[i];
            uint256 knights = voteAmount[user];
            uint256 userShare = knights.mul(1e12).div(voted);
            // distribute normal pool rewards
            for (uint j = 0; j < normalPoolInfo.length; j++) {
                NormalPoolInfo storage poolInfo = normalPoolInfo[j];
                uint256 stakeChestShare = poolInfo.stakeChestAmount.mul(userShare).div(1e12);
                uint256 receiveChestShare = poolInfo.receiveChestAmount.mul(userShare).div(1e12);
                poolInfo.stakeToken.transfer(user, stakeChestShare);
                poolInfo.receiveToken.transfer(user, receiveChestShare);
                poolInfo.stakeChestAmount = poolInfo.stakeChestAmount.sub(stakeChestShare);
                poolInfo.receiveChestAmount = poolInfo.receiveChestAmount.sub(receiveChestShare);
            }

            // distribute burn pool rewards
            for (uint j = 0; j < burnPoolInfo.length; j++) {
                BurnPoolInfo storage poolInfo = burnPoolInfo[j];
                uint256 stakeChestShare = poolInfo.stakeChestAmount.mul(userShare).div(1e12);
                uint256 receiveChestShare = poolInfo.receiveChestAmount.mul(userShare).div(1e12);
                poolInfo.burningStakeToken.transfer(user, stakeChestShare);
                poolInfo.receiveToken.transfer(user, receiveChestShare);
                poolInfo.stakeChestAmount = poolInfo.stakeChestAmount.sub(stakeChestShare);
                poolInfo.receiveChestAmount = poolInfo.receiveChestAmount.sub(receiveChestShare);
            }

            // distribute multi burn pool rewards
            for (uint j = 0; j < multiBurnPoolInfo.length; j++) {
                MultiBurnPoolInfo storage poolInfo = multiBurnPoolInfo[j];
                uint256 stakeChestShare = poolInfo.stakeChestAmount.mul(userShare).div(1e12);
                for (uint x = 0; x < poolInfo.burningStakeTokens.length; x++) {
                    poolInfo.burningStakeTokens[x].transfer(user, stakeChestShare);
                }
                poolInfo.stakeChestAmount = poolInfo.stakeChestAmount.sub(stakeChestShare);
            }

            // clear voteAmount
            knightToken.transfer(user, voteAmount[user]);
            delete voteAmount[user];
        }


        votingActive = false;
        delete voters;
    }
}