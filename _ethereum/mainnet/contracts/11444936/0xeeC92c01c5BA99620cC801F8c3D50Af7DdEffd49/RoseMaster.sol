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
        if (returndata.length > 0) { // Return data is optional
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
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
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: contracts/RoseToken.sol

pragma solidity 0.6.12;



// RoseToken with Governance.
contract RoseToken is ERC20("RoseToken", "ROSE"), Ownable {
    // @notice Creates `_amount` token to `_to`. Must only be called by the owner (RoseMain).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}

// File: contracts/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

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

// File: contracts/RoseMaster.sol

pragma solidity 0.6.12;








// RoseMaster is the master of Rose. He can make Rose and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once ROSE is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract RoseMaster is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of ROSEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRosePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRosePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo1 {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. ROSEs to distribute per block.
        uint256 lastRewardBlock; // Last block number that ROSEs distribution occurs.
        uint256 accRosePerShare; // Accumulated ROSEs per share, times 1e12. See below.
        // Lock LP, until the end of mining.
        uint256 totalAmount;
    }

    // Info of each pool.
    struct PoolInfo2 {
        uint256 allocPoint; // How many allocation points assigned to this pool. ROSEs to distribute per block.
        uint256 lastRewardBlock; // Last block number that ROSEs distribution occurs.
        uint256 accRosePerShare; // Accumulated ROSEs per share, times 1e12. See below.
        uint256 lastUnlockedBlock; // Last block number that pool to renovate.
        // Lock LP, until the pool update.
        uint256 lockedAmount;
        uint256 freeAmount;
        uint256 maxLockAmount;
        uint256 unlockIntervalBlock;
        uint256 feeAmount;
        uint256 sharedFeeAmount;
    }

    // Info of each period.
    struct PeriodInfo {
        uint256 endBlock;
        uint256 blockReward;
    }

    // The ROSE TOKEN!
    RoseToken public rose;
    // Dev address.
    address public devaddr;
    // Rank address .
    address public rankAddr;
    // Autonomous communities address.
    address public communityAddr;
    // Sunflower address.
    address public sfr;
    // UnisawpV2Pair SFR-ROSE.
    IUniswapV2Pair public sfr2rose;

    // Info of each pool.
    PoolInfo1[] public poolInfo1;
    // Info of each pool.
    PoolInfo2[] public poolInfo2;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo1;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo2;
    // Total allocation points. Must be the sum of all allocation points in all pool1s.
    uint256 public allocPointPool1 = 0;
    // Total allocation points. Must be the sum of all allocation points in all pool2s.
    uint256 public allocPointPool2 = 0;
    // The block number when ROSE mining starts.
    uint256 public startBlock;
    // User address to referrer address.
    mapping(address => address) public referrers;
    mapping(address => address[]) referreds1;
    mapping(address => address[]) referreds2;

    // Mint period info.
    PeriodInfo[] public periodInfo;

    event Deposit1(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw1(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw1(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event Deposit2(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw2(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw2(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        RoseToken _rose,
        address _sfr,
        address _devaddr,
        address _topReferrer,
        uint256 _startBlock,
        uint256 _firstBlockReward,
        uint256 _supplyPeriod,
        uint256 _maxSupply
    ) public {
        rose = _rose;
        sfr = _sfr;
        devaddr = _devaddr;
        startBlock = _startBlock;

        // the block rewards and the block at the end of the period.
        uint256 _supplyPerPeriod = _maxSupply / _supplyPeriod;
        uint256 lastPeriodEndBlock = _startBlock;
        for (uint256 i = 0; i < _supplyPeriod; i++) {
            lastPeriodEndBlock = lastPeriodEndBlock.add(
                _supplyPerPeriod.div(_firstBlockReward) << i
            );
            periodInfo.push(
                PeriodInfo({
                    endBlock: lastPeriodEndBlock,
                    blockReward: _firstBlockReward >> i
                })
            );
        }

        referrers[_topReferrer] = _topReferrer;
    }

    function pool1Length() external view returns (uint256) {
        return poolInfo1.length;
    }

    function pool2Length() external view returns (uint256) {
        return poolInfo2.length;
    }

    function setStartBlock(uint256 _startBlock) public onlyOwner {
        require(block.number < startBlock);
        startBlock = _startBlock;
    }

    function setSfr2rose(address _sfr2rose) external onlyOwner {
        sfr2rose = IUniswapV2Pair(_sfr2rose);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add1(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePool1s();
        }
        uint256 firstBlock = block.number > startBlock
            ? block.number
            : startBlock;
        allocPointPool1 = allocPointPool1.add(_allocPoint);
        poolInfo1.push(
            PoolInfo1({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: firstBlock,
                accRosePerShare: 0,
                totalAmount: 0
            })
        );
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add2(
        uint256 _allocPoint,
        bool _withUpdate,
        uint256 _maxLockAmount,
        uint256 _unlockIntervalBlock
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePool2s();
        }
        uint256 firstBlock = block.number > startBlock
            ? block.number
            : startBlock;
        allocPointPool2 = allocPointPool2.add(_allocPoint);
        poolInfo2.push(
            PoolInfo2({
                allocPoint: _allocPoint,
                lastRewardBlock: firstBlock,
                accRosePerShare: 0,
                lastUnlockedBlock: 0,
                lockedAmount: 0,
                freeAmount: 0,
                maxLockAmount: _maxLockAmount,
                unlockIntervalBlock: _unlockIntervalBlock,
                feeAmount: 0,
                sharedFeeAmount: 0
            })
        );
    }

    // Update the given pool's ROSE allocation point. Can only be called by the owner.
    function set1(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePool1s();
        }
        allocPointPool1 = allocPointPool1.sub(poolInfo1[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo1[_pid].allocPoint = _allocPoint;
    }

    // Update the given pool's ROSE allocation point. Can only be called by the owner.
    function set2(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePool2s();
        }
        allocPointPool2 = allocPointPool2.sub(poolInfo2[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo2[_pid].allocPoint = _allocPoint;
    }

    function setMaxLockAmount(uint256 _pid, uint256 _maxLockAmount)
        external
        onlyOwner
    {
        poolInfo2[_pid].maxLockAmount = _maxLockAmount;
    }

    function setUnlockIntervalBlock(uint256 _pid, uint256 _unlockIntervalBlock)
        external
        onlyOwner
    {
        poolInfo2[_pid].unlockIntervalBlock = _unlockIntervalBlock;
    }

    function getBlockRewardNow() public view returns (uint256) {
        return getBlockRewards(block.number, block.number + 1);
    }

    function getBlockRewards(uint256 from, uint256 to)
        public
        view
        returns (uint256 rewards)
    {
        if (from < startBlock) {
            from = startBlock;
        }
        if (from >= to) {
            return 0;
        }

        for (uint256 i = 0; i < periodInfo.length; i++) {
            if (periodInfo[i].endBlock >= to) {
                return to.sub(from).mul(periodInfo[i].blockReward).add(rewards);
            } else if (periodInfo[i].endBlock <= from) {
                continue;
            } else {
                rewards = rewards.add(
                    periodInfo[i].endBlock.sub(from).mul(
                        periodInfo[i].blockReward
                    )
                );
                from = periodInfo[i].endBlock;
            }
        }
    }

    // View function to see pending ROSEs on frontend.
    function pendingRose1(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        PoolInfo1 storage pool = poolInfo1[_pid];
        UserInfo storage user = userInfo1[_pid][_user];
        uint256 accRosePerShare = pool.accRosePerShare;
        uint256 lpSupply = pool.totalAmount;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 blockRewards = getBlockRewards(
                pool.lastRewardBlock,
                block.number
            );
            // pool1 hold 70% rewards.
            blockRewards = blockRewards.mul(7).div(10);
            uint256 roseReward = blockRewards.mul(pool.allocPoint).div(
                allocPointPool1
            );
            accRosePerShare = accRosePerShare.add(
                roseReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accRosePerShare).div(1e12).sub(user.rewardDebt);
    }

    // View function to see pending ROSEs on frontend.
    function pendingRose2(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        PoolInfo2 storage pool = poolInfo2[_pid];
        UserInfo storage user = userInfo2[_pid][_user];
        uint256 accRosePerShare = pool.accRosePerShare;
        uint256 lpSupply = pool.lockedAmount.add(pool.freeAmount);
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 blockRewards = getBlockRewards(
                pool.lastRewardBlock,
                block.number
            );
            // pool2 hold 30% rewards.
            blockRewards = blockRewards.mul(3).div(10);
            uint256 roseReward = blockRewards.mul(pool.allocPoint).div(
                allocPointPool2
            );
            accRosePerShare = accRosePerShare.add(
                roseReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accRosePerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePool1s() public {
        uint256 length = poolInfo1.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool1(pid);
        }
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePool2s() public {
        uint256 length = poolInfo2.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool2(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool1(uint256 _pid) public {
        PoolInfo1 storage pool = poolInfo1[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.totalAmount;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 blockRewards = getBlockRewards(
            pool.lastRewardBlock,
            block.number
        );
        // pool1 hold 70% rewards.
        blockRewards = blockRewards.mul(7).div(10);
        uint256 roseReward = blockRewards.mul(pool.allocPoint).div(
            allocPointPool1
        );
        rose.mint(devaddr, roseReward.div(10));
        if (rankAddr != address(0)) {
            rose.mint(rankAddr, roseReward.mul(9).div(100));
        }
        if (communityAddr != address(0)) {
            rose.mint(communityAddr, roseReward.div(100));
        }
        rose.mint(address(this), roseReward);
        pool.accRosePerShare = pool.accRosePerShare.add(
            roseReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool2(uint256 _pid) public {
        PoolInfo2 storage pool = poolInfo2[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lockedAmount.add(pool.freeAmount);
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 blockRewards = getBlockRewards(
            pool.lastRewardBlock,
            block.number
        );
        // pool2 hold 30% rewards
        blockRewards = blockRewards.mul(3).div(10);
        uint256 roseReward = blockRewards.mul(pool.allocPoint).div(
            allocPointPool2
        );
        rose.mint(devaddr, roseReward.div(10));
        if (rankAddr != address(0)) {
            rose.mint(rankAddr, roseReward.mul(9).div(100));
        }
        if (communityAddr != address(0)) {
            rose.mint(communityAddr, roseReward.div(100));
        }
        rose.mint(address(this), roseReward);
        pool.accRosePerShare = pool.accRosePerShare.add(
            roseReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to RoseMain for ROSE allocation.
    function deposit1(uint256 _pid, uint256 _amount) public {
        PoolInfo1 storage pool = poolInfo1[_pid];
        UserInfo storage user = userInfo1[_pid][msg.sender];
        updatePool1(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount
                .mul(pool.accRosePerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            if (pending > 0) {
                safeRoseTransfer(msg.sender, pending);
                mintReferralReward(pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
            pool.totalAmount = pool.totalAmount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRosePerShare).div(1e12);
        emit Deposit1(msg.sender, _pid, _amount);
    }

    // Deposit LP tokens to RoseMaster for ROSE allocation.
    function deposit2(uint256 _pid, uint256 _amount) public {
        PoolInfo2 storage pool = poolInfo2[_pid];
        UserInfo storage user = userInfo2[_pid][msg.sender];
        updatePool2(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount
                .mul(pool.accRosePerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            if (pending > 0) {
                safeRoseTransfer(msg.sender, pending);
                mintReferralReward(pending);
            }
        }
        if (_amount > 0) {
            _safeTransferFrom(sfr, address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            pool.lockedAmount = pool.lockedAmount.add(_amount);
        }
        updateLockedAmount(pool);
        user.rewardDebt = user.amount.mul(pool.accRosePerShare).div(1e12);
        emit Deposit2(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from RoseMain.
    function withdraw1(uint256 _pid, uint256 _amount) public {
        PoolInfo1 storage pool = poolInfo1[_pid];
        UserInfo storage user = userInfo1[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool1(_pid);
        uint256 pending = user.amount.mul(pool.accRosePerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (pending > 0) {
            safeRoseTransfer(msg.sender, pending);
            mintReferralReward(pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalAmount = pool.totalAmount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRosePerShare).div(1e12);
        emit Withdraw1(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from RoseMaster.
    function withdraw2(uint256 _pid, uint256 _amount) public {
        UserInfo storage user = userInfo2[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        PoolInfo2 storage pool = poolInfo2[_pid];
        updateLockedAmount(pool);
        require(
            _amount <= pool.freeAmount,
            "withdraw: insufficient free balance in pool"
        );
        updatePool2(_pid);
        uint256 pending = user.amount.mul(pool.accRosePerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (pending > 0) {
            safeRoseTransfer(msg.sender, pending);
            mintReferralReward(pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.freeAmount = pool.freeAmount.sub(_amount);
            // reduce the fee of 0.3%
            uint256 fee = _amount.mul(3).div(1000);
            pool.feeAmount = pool.feeAmount.add(fee);
            _safeTransfer(sfr, address(msg.sender), _amount.sub(fee));
        }
        user.rewardDebt = user.amount.mul(pool.accRosePerShare).div(1e12);
        emit Withdraw2(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw1(uint256 _pid) public {
        PoolInfo1 storage pool = poolInfo1[_pid];
        UserInfo storage user = userInfo1[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw1(msg.sender, _pid, amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw2(uint256 _pid) public {
        PoolInfo2 storage pool = poolInfo2[_pid];
        UserInfo storage user = userInfo2[_pid][msg.sender];
        require(user.amount <= pool.freeAmount);
        _safeTransfer(sfr, address(msg.sender), user.amount);
        emit EmergencyWithdraw2(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe rose transfer function, just in case if rounding error causes pool to not have enough ROSEs.
    function safeRoseTransfer(address _to, uint256 _amount) internal {
        uint256 roseBal = rose.balanceOf(address(this));
        if (_amount > roseBal) {
            rose.transfer(_to, roseBal);
        } else {
            rose.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    // Update dev address by the owner.
    function rank(address _addr) public onlyOwner {
        rankAddr = _addr;
    }

    // Update dev address by the owner.
    function community(address _addr) public onlyOwner {
        communityAddr = _addr;
    }

    // Fill _user in as referrer.
    function refer(address _user) external {
        require(_user != msg.sender && referrers[_user] != address(0));
        // No modification.
        require(referrers[msg.sender] == address(0));
        referrers[msg.sender] = _user;
        // Record two levels of refer relationship。
        referreds1[_user].push(msg.sender);
        address referrer2 = referrers[_user];
        if (_user != referrer2) {
            referreds2[referrer2].push(msg.sender);
        }
    }

    // Query the first referred user.
    function getReferreds1(address addr, uint256 startPos)
        external
        view
        returns (uint256 length, address[] memory data)
    {
        address[] memory referreds = referreds1[addr];
        length = referreds.length;
        data = new address[](length);
        for (uint256 i = 0; i < 5 && i + startPos < length; i++) {
            data[i] = referreds[startPos + i];
        }
    }

    // Query the second referred user.
    function getReferreds2(address addr, uint256 startPos)
        external
        view
        returns (uint256 length, address[] memory data)
    {
        address[] memory referreds = referreds2[addr];
        length = referreds.length;
        data = new address[](length);
        for (uint256 i = 0; i < 5 && i + startPos < length; i++) {
            data[i] = referreds[startPos + i];
        }
    }

    // Query user all rewards
    function allPendingRose(address _user)
        external
        view
        returns (uint256 pending)
    {
        for (uint256 i = 0; i < poolInfo1.length; i++) {
            pending = pending.add(pendingRose1(i, _user));
        }
        for (uint256 i = 0; i < poolInfo2.length; i++) {
            pending = pending.add(pendingRose2(i, _user));
        }
    }

    // Mint for referrers.
    function mintReferralReward(uint256 _amount) internal {
        address referrer = referrers[msg.sender];
        // no referrer.
        if (address(0) == referrer) {
            return;
        }
        // mint for user and the first level referrer.
        rose.mint(msg.sender, _amount.div(100));
        rose.mint(referrer, _amount.mul(2).div(100));

        // only the referrer of the top person is himself.
        if (referrers[referrer] == referrer) {
            return;
        }
        // mint for the second level referrer.
        rose.mint(referrers[referrer], _amount.mul(2).div(100));
    }

    // Update the locked amount that meet the conditions
    function updateLockedAmount(PoolInfo2 storage pool) internal {
        uint256 passedBlock = block.number - pool.lastUnlockedBlock;
        if (passedBlock >= pool.unlockIntervalBlock) {
            // case 2 and more than 2 period have passed.
            pool.lastUnlockedBlock = pool.lastUnlockedBlock.add(
                pool.unlockIntervalBlock.mul(
                    passedBlock.div(pool.unlockIntervalBlock)
                )
            );
            uint256 lockedAmount = pool.lockedAmount;
            pool.lockedAmount = 0;
            pool.freeAmount = pool.freeAmount.add(lockedAmount);
        } else if (pool.lockedAmount >= pool.maxLockAmount) {
            // Free 75% to freeAmont from lockedAmount.
            uint256 freeAmount = pool.lockedAmount.mul(75).div(100);
            pool.lockedAmount = pool.lockedAmount.sub(freeAmount);
            pool.freeAmount = pool.freeAmount.add(freeAmount);
        }
    }

    // Using feeAmount to buy back ROSE and share every holder.
    function convert(uint256 _pid) external {
        PoolInfo2 storage pool = poolInfo2[_pid];
        uint256 lpSupply = pool.freeAmount.add(pool.lockedAmount);
        if (address(sfr2rose) != address(0) && pool.feeAmount > 0) {
            uint256 amountOut = swapSFRForROSE(pool.feeAmount);
            if (amountOut > 0) {
                pool.feeAmount = 0;
                pool.sharedFeeAmount = pool.sharedFeeAmount.add(amountOut);
                pool.accRosePerShare = pool.accRosePerShare.add(
                    amountOut.mul(1e12).div(lpSupply)
                );
            }
        }
    }

    function swapSFRForROSE(uint256 _amount)
        internal
        returns (uint256 amountOut)
    {
        (uint256 reserve0, uint256 reserve1, ) = sfr2rose.getReserves();
        address token0 = sfr2rose.token0();
        (uint256 reserveIn, uint256 reserveOut) = token0 == sfr
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        // Calculate information required to swap
        uint256 amountInWithFee = _amount.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
        if (amountOut == 0) {
            return 0;
        }
        (uint256 amount0Out, uint256 amount1Out) = token0 == sfr
            ? (uint256(0), amountOut)
            : (amountOut, uint256(0));
        _safeTransfer(sfr, address(sfr2rose), _amount);
        sfr2rose.swap(amount0Out, amount1Out, address(this), new bytes(0));
    }

    // Wrapper for safeTransferFrom
    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        IERC20(token).safeTransferFrom(from, to, amount);
    }

    // Wrapper for safeTransfer
    function _safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        IERC20(token).safeTransfer(to, amount);
    }
}