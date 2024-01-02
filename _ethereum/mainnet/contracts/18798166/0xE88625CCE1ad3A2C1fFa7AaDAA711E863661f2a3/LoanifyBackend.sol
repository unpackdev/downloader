/**
 *Submitted for verification at lineascan.build on 2023-08-06


https://loanify.tech
https://twitter.com/LoanifyCoin
https://t.me/LoanifyCoin
https://loanify.gitbook.io/loanify/overview/introduction


 */



// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/* --------- Access Control --------- */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Claimable is Ownable {
    bool isclaimable = false;

    function claimToken(
        address tokenAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    function claimETH(uint256 amount) external onlyOwner {
        (bool sent, ) = address(owner()).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface Aggregator {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(
        bytes memory returndata,
        string memory errorMessage
    ) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

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
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

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
    function _contains(
        Set storage set,
        bytes32 value
    ) private view returns (bool) {
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
    function _at(
        Set storage set,
        uint256 index
    ) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
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
    function at(
        Bytes32Set storage set,
        uint256 index
    ) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
    function add(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(
        AddressSet storage set,
        address value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
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
    function at(
        AddressSet storage set,
        uint256 index
    ) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(
        AddressSet storage set
    ) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
    function remove(
        UintSet storage set,
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(
        UintSet storage set,
        uint256 value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
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
    function at(
        UintSet storage set,
        uint256 index
    ) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
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
    using Address for address;

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(
        address spender,
        uint256 currentAllowance,
        uint256 requestedDecrease
    );

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeCall(token.transferFrom, (from, to, value))
        );
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 requestedDecrease
    ) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(
                    spender,
                    currentAllowance,
                    requestedDecrease
                );
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        bytes memory approvalCall = abi.encodeCall(
            token.approve,
            (spender, value)
        );

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(
                token,
                abi.encodeCall(token.approve, (spender, 0))
            );
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(
        IERC20 token,
        bytes memory data
    ) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success &&
            (returndata.length == 0 || abi.decode(returndata, (bool))) &&
            address(token).code.length > 0;
    }
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
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
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);

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

contract Loanify is Claimable {
    using SafeMath for uint256;
    using Address for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;

    // Manage user info on contract
    struct UserInfo {
        address accountAddress; //Account Address
        uint256 lastInterest; //last timestamp that calcuate interest
        mapping(address => uint256) tokenDepositAmount; //deposit amount for token
        mapping(address => uint256) tokenBorrowAmount; //borrow amount for token
        mapping(address => uint256) tokenRewardAmount; //reward amount for token
        mapping(address => uint256) tokenInterestAmount; //interest amount for token
        uint256 ethRewardAmount; //deposit amount for token
    }

    // Send result to frontend with this style
    struct UserInfoForDisplay {
        uint256[] depositAmount;
        uint256[] borrowAmount;
        uint256[] rewardAmount;
        uint256[] interestAmount;
        uint256[] depositTotalInUsdt;
        uint256[] borrowTotalInUsdt;
        uint256 totalCollateralInUsdt;
        uint256 totalDebtInUsdt;
        uint256 ethRewardAmount;
        address accountAddress;
        bool isLiquidatable;
    }

    // show pool info
    struct PoolInfo {
        uint256 LTV;
        uint256 depositApy;
        uint256 borrowApy;
        uint256 totalAmount;
        uint256 borrowAmount;
    }

    // dynamic apy initial values
    // if  U < Uₒₚₜᵢₘₐₗ :     Rₜ = R₀ + Uₜ/Uₒₚₜᵢₘₐₗ * Rₛₗₒₚₑ₁
    // if U ≥  Uₒₚₜᵢₘₐₗ :    Rₜ = R₀ + Rₛₗₒₚₑ₁ + (Uₜ-Uₒₚₜᵢₘₐₗ)/(1-Uₒₚₜᵢₘₐₗ) *Rₛₗₒₚₑ₂
    struct APYInfo {
        uint256 r0;
        uint256 uOption;
        uint256 slope1;
        uint256 slope2;
    }

    // Supply apy initial value
    APYInfo public supplyAPY;
    // Deposit apy inital value
    APYInfo public borrowAPY;

    // Save pools info
    mapping(address => PoolInfo) public poolInfos;

    // Save user info
    uint256 public maxUserIndex;
    mapping(uint256 => UserInfo) public userInfos;
    mapping(address => uint256) public userInfoIndex;

    mapping(address => address) public pairAddress;

    // Initial token addrewss (eth address means weth address)
    //0:weth, 1: usdt: 2: usdc
    address[] public tokensInfo;
    // withdraw fee is 0.5%
    // when user withdraw and liquidate, 0.5 fee goes to owner wallet.
    uint256 public withdrawFee = 50;
    // liquidate limit percent , normally it is 90% but for the testing I set 90%
    uint256 public liquidationThreshhold = 90;
    // I am using this decimal when calcuate reward
    uint256 decimal = 1e14;

    // decimal/(31,536,000 *100) = 31709
    // Because there is not decimal we show 1% as 100,so 1% APY = 317 second apy
    uint256 secondApy = 317;

    address aggregatorInterface = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    struct DailyInfo {
        uint256 lastDateNumber;
        uint256[] depositAmount;
        uint256[] withdrawAmount;
        uint256[] borrowAmount;
        uint256[] repayAmount;
    }

    DailyInfo public dailyInfo;

    constructor() {
        //weth 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2
        addToken(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, address(0));
        //usdt
        addToken(0xdAC17F958D2ee523a2206206994597C13D831ec7, address(0));
        //usdc
        addToken(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, address(0));

        //pepe
        addToken(
            0x6982508145454Ce325dDbE47a25d4ec3d2311933,
            0xA43fe16908251ee70EF74718545e4FE6C5cCEc9f
        );
        // HarryPotterObamaSonic10Inu ($BITCOIN)
        addToken(
            0x72e4f9F808C49A2a61dE9C5896298920Dc4EEEa9,
            0x2cC846fFf0b08FB3bFfaD71f53a60B4b6E6d6482
        );
        //mog
        addToken(
            0xaaeE1A9723aaDB7afA2810263653A34bA2C21C7a,
            0xc2eaB7d33d3cB97692eCB231A5D0e4A649Cb539d
        );
        //spx
        addToken(
            0xE0f63A424a4439cBE457D80E4f4b51aD25b2c56C,
            0x52c77b0CB827aFbAD022E6d6CAF2C44452eDbc39
        );
        //joe
        addToken(
            0x76e222b07C53D28b89b0bAc18602810Fc22B49A8,
            0x704aD8d95C12D7FEA531738faA94402725acB035
        );
        //grok
        addToken(
            0x8390a1DA07E376ef7aDd4Be859BA74Fb83aA02D5,
            0x69c66BeAfB06674Db41b22CFC50c34A93b8d82a2
        );
        //kekec
        addToken(
            0x8C7AC134ED985367EADC6F727d79E8295E11435c,
            0xc6e40537215C1E041616478D8cFe312b1847b997
        );
        //Real Smurf Cat
        addToken(
            0xfF836A5821E69066c87E268bC51b849FaB94240C,
            0x977C5fcf7a552d38ADCDE4F41025956855497C6D
        );
        setBorrowApy(200, 70, 2000, 3800);
        setSupplyApy(0, 70, 1000, 1000);
    }

    function addToken(address _token, address _pair) public onlyOwner {
        tokensInfo.push(_token);
        pairAddress[_token] = _pair;
        // 10 *decimal/(31,536,000 *100) = 30 so 1% = 317, 1% meaning 100 so decimal  = 1e14
        // 10 *decimal/(31,536,000 *100)
        addPool(_token, 80, 100, 200, 0, 0);
        dailyInfo.depositAmount.push(0);
        dailyInfo.withdrawAmount.push(0);
        dailyInfo.borrowAmount.push(0);
        dailyInfo.repayAmount.push(0);
    }

    function setTokenPair(address _token, address _pair) public onlyOwner {
        pairAddress[_token] = _pair;
    }

    // Liquidate max percent normally 90%
    function setLiquidationThreshhold(uint256 limit) public onlyOwner {
        liquidationThreshhold = limit;
    }

    function addPool(
        address _tokenAddress,
        uint256 _LTV,
        uint256 _depositApy,
        uint256 _borrowApy,
        uint256 _totalAmount,
        uint256 _borrowAmount
    ) private {
        PoolInfo storage newPoolInfo = poolInfos[_tokenAddress];
        newPoolInfo.LTV = _LTV;
        // 10 *decimal/(31,536,000 *100) = 3170 so 1%=317
        newPoolInfo.depositApy = _depositApy * secondApy;
        newPoolInfo.borrowApy = _borrowApy * secondApy;
        newPoolInfo.totalAmount = _totalAmount;
        newPoolInfo.borrowAmount = _borrowAmount;
    }

    function setPoolInfo(
        address _tokenAddress,
        uint256 _LTV,
        uint256 _depositApy,
        uint256 _borrowApy
    ) external {
        PoolInfo storage newPoolInfo = poolInfos[_tokenAddress];
        newPoolInfo.LTV = _LTV;
        // 10 *decimal/(31,536,000 *100) = 3170 so 1%=317
        newPoolInfo.depositApy = _depositApy * secondApy;
        newPoolInfo.borrowApy = _borrowApy * secondApy;
    }

    // calcuate to usdt amout. So if eth price is 1000 and _amount is 1e18 the the result is 1000 * 1000000 (usdc decimal is 6)
    function calcTokenPrice(
        address _tokenAddress,
        uint256 _amount
    ) public view returns (uint256) {
        uint256 ethPrice = getEthValue();
        if (_tokenAddress == tokensInfo[0]) {
            return (ethPrice * _amount).div(10 ** 30);
        } else if (
            _tokenAddress == tokensInfo[1] || _tokenAddress == tokensInfo[2]
        ) {
            return _amount;
        } else {
            address pair = pairAddress[_tokenAddress];
            IUniswapV2Pair tokenPool = IUniswapV2Pair(pair);

            address otherToken = tokenPool.token1() == _tokenAddress
                ? tokenPool.token0()
                : tokenPool.token1();
            uint256 otherTokenBal = IERC20(otherToken).balanceOf(pair);
            uint256 tokenBal = IERC20(_tokenAddress).balanceOf(pair);
            if (tokenBal == 0) {
                return 0;
            }
            if (otherToken == tokensInfo[0]) {
                //weth
                return ((otherTokenBal * (_amount * ethPrice).div(10 ** 30)) /
                    tokenBal);
            } else {
                //usdt
                return (otherTokenBal * _amount) / tokenBal;
            }
        }
    }

    // calculate to eth amount. so
    function calcEthForToken(
        address _tokenAddress,
        uint256 _amount
    ) public view returns (uint256) {
        uint256 ethPrice = getEthValue();
        if (_tokenAddress == tokensInfo[0]) {
            return _amount;
        } else if (
            _tokenAddress == tokensInfo[1] || _tokenAddress == tokensInfo[2]
        ) {
            return (_amount * 10 ** 30) / ethPrice;
        } else {
            address pair = pairAddress[_tokenAddress];
            IUniswapV2Pair tokenPool = IUniswapV2Pair(pair);
            address otherToken = tokenPool.token1() == _tokenAddress
                ? tokenPool.token0()
                : tokenPool.token1();
            uint256 otherTokenBal = IERC20(otherToken).balanceOf(pair);
            uint256 tokenBal = IERC20(_tokenAddress).balanceOf(pair);
            if (tokenBal == 0) {
                return 0;
            }
            if (tokenPool.token1() == tokensInfo[0]) {
                //weth
                return (otherTokenBal * _amount) / tokenBal;
            } else {
                //usdt
                return ((otherTokenBal * ((_amount * 10 ** 30) / ethPrice)) /
                    tokenBal);
            }
        }
    }

    //eth price in 10**18 decimals
    function getEthValue() public view returns (uint256) {
        (, int256 ethPrice, , , ) = Aggregator(aggregatorInterface)
            .latestRoundData();
        ethPrice = (ethPrice * (10 ** 10));
        return uint256(ethPrice);
    }

    function setAggregatorInterface(
        address _interfaceInterface
    ) public onlyOwner {
        aggregatorInterface = _interfaceInterface;
    }

    function setBasicTokenAddresses(
        address _ethAddress,
        address _usdtAddress,
        address _usdcAddress
    ) public onlyOwner {
        tokensInfo[0] = _ethAddress;
        tokensInfo[1] = _usdtAddress;
        tokensInfo[2] = _usdcAddress;
    }

    function setSupplyApy(
        uint256 _r0,
        uint256 _uOption,
        uint256 _rSlope1,
        uint256 _rSlope2
    ) public onlyOwner {
        supplyAPY.r0 = _r0;
        supplyAPY.uOption = _uOption;
        supplyAPY.slope1 = _rSlope1;
        supplyAPY.slope2 = _rSlope2;
    }

    function setBorrowApy(
        uint256 _r0,
        uint256 _uOption,
        uint256 _rSlope1,
        uint256 _rSlope2
    ) public onlyOwner {
        borrowAPY.r0 = _r0;
        borrowAPY.uOption = _uOption;
        borrowAPY.slope1 = _rSlope1;
        borrowAPY.slope2 = _rSlope2;
    }

    // Calculate apy from market size and borrow amount
    // if  U < Uₒₚₜᵢₘₐₗ :     Rₜ = R₀ + Uₜ/Uₒₚₜᵢₘₐₗ * Rₛₗₒₚₑ₁
    // if U ≥  Uₒₚₜᵢₘₐₗ :    Rₜ = R₀ + Rₛₗₒₚₑ₁ + (Uₜ-Uₒₚₜᵢₘₐₗ)/(1-Uₒₚₜᵢₘₐₗ) *Rₛₗₒₚₑ₂
    function calculateAPY(
        address _tokenAddress
    ) private view returns (uint256, uint256) {
        uint256 totalAmount;
        uint256 borrowAmount;
        PoolInfo memory poolInfo = getPoolInfo(_tokenAddress);
        totalAmount = poolInfo.totalAmount;
        borrowAmount = poolInfo.borrowAmount;
        uint256 rt = 0;
        uint256 st = 0;
        if (totalAmount > 0) {
            uint256 Ut = (borrowAmount * 100).div(totalAmount);

            if (borrowAPY.uOption > Ut) {
                rt =
                    borrowAPY.r0 +
                    (Ut * borrowAPY.slope1).div(borrowAPY.uOption);
            } else {
                rt =
                    borrowAPY.r0 +
                    borrowAPY.slope1 +
                    ((Ut - borrowAPY.uOption) * borrowAPY.slope2).div(
                        100 - borrowAPY.uOption
                    );
            }

            if (supplyAPY.uOption > Ut) {
                st =
                    supplyAPY.r0 +
                    (Ut * supplyAPY.slope1).div(supplyAPY.uOption);
            } else {
                st =
                    supplyAPY.r0 +
                    supplyAPY.slope1 +
                    ((Ut - supplyAPY.uOption) * supplyAPY.slope2).div(
                        100 - supplyAPY.uOption
                    );
            }
            st = st * secondApy;
            rt = rt * secondApy;
        } else {
            st = supplyAPY.r0 * secondApy;
            rt = borrowAPY.r0 * secondApy;
        }
        return (st, rt);
    }

    // calcuate interest and reward for user.
    function calculateUser(address _account) private {
        // if  U < Uₒₚₜᵢₘₐₗ :     Rₜ = R₀ + Uₜ/Uₒₚₜᵢₘₐₗ * Rₛₗₒₚₑ₁
        // if U ≥  Uₒₚₜᵢₘₐₗ :    Rₜ = R₀ + Rₛₗₒₚₑ₁ + (Uₜ-Uₒₚₜᵢₘₐₗ)/(1-Uₒₚₜᵢₘₐₗ) *Rₛₗₒₚₑ₂
        // R₀ = 0, Uₒₚₜᵢₘₐₗ = 70%,Rₛₗₒₚₑ₁ = 2% Rₛₗₒₚₑ₂ = 60%
        // S₀ = 0, Uₒₚₜᵢₘₐₗ = 70%,Sₛₗₒₚₑ₁ = 0% Sₛₗₒₚₑ₂ = 20%

        require(userInfoIndex[_account] > 0, "User should deposit before");
        UserInfo storage currentUserInfo = userInfos[userInfoIndex[_account]];
        UserInfoForDisplay memory userInfoDisplay = fetchUserInfo(
            userInfoIndex[_account]
        );

        currentUserInfo.ethRewardAmount = userInfoDisplay.ethRewardAmount;

        for (uint256 index = 0; index < tokensInfo.length; index++) {
            address token = tokensInfo[index];
            currentUserInfo.tokenRewardAmount[token] = userInfoDisplay
                .rewardAmount[index];
            currentUserInfo.tokenInterestAmount[token] = userInfoDisplay
                .interestAmount[index];
            (
                poolInfos[token].depositApy,
                poolInfos[token].borrowApy
            ) = calculateAPY(token);
        }
        currentUserInfo.lastInterest = block.timestamp;
    }

    function clearUser(address _account) private {
        require(userInfoIndex[_account] > 0, "User should deposit before");
        UserInfo storage currentUserInfo = userInfos[userInfoIndex[_account]];
        for (uint256 index = 0; index < tokensInfo.length; index++) {
            address token = tokensInfo[index];
            currentUserInfo.tokenDepositAmount[token] = 0;
            currentUserInfo.tokenBorrowAmount[token] = 0;
            currentUserInfo.tokenRewardAmount[token] = 0;
            currentUserInfo.tokenInterestAmount[token] = 0;
        }

        currentUserInfo.ethRewardAmount = 0;
    }

    function deposit(address _tokenAddress, uint256 _amount) public payable {
        require(_amount > 0, "can't deposit 0");
        uint256 userIndex = 0;
        if (userInfoIndex[msg.sender] == 0) {
            maxUserIndex += 1;
            userIndex = maxUserIndex;
            userInfoIndex[msg.sender] = userIndex;
        } else {
            userIndex = userInfoIndex[msg.sender];
            calculateUser(msg.sender);
        }
        UserInfo storage currentUserInfo = userInfos[userIndex];
        currentUserInfo.accountAddress = msg.sender;
        currentUserInfo.lastInterest = block.timestamp;

        currentUserInfo.tokenDepositAmount[_tokenAddress] += _amount;
        if (_tokenAddress != tokensInfo[0]) {
            require(
                IERC20(_tokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    _amount
                ),
                "deposit failed"
            );
        } else {
            require(msg.value >= _amount, "You did not pay as amount");
            //refund eth if exceeds
            if (msg.value > _amount) {
                payable(msg.sender).sendValue(msg.value - _amount);
            }
        }
        poolInfos[_tokenAddress].totalAmount += _amount;
        calculateUser(msg.sender);

        //update daily info
        updateDailyInfo(_tokenAddress, _amount, 0);
    }

    //_type 0: deposit 1: withdraw 2: borrow 3: repay
    function updateDailyInfo(
        address _tokenAddress,
        uint256 _amount,
        uint256 _type
    ) internal {
        uint256 dateNumber = block.timestamp / 86400;
        if (dateNumber != dailyInfo.lastDateNumber) {
            for (uint256 index = 0; index < tokensInfo.length; index++) {
                dailyInfo.depositAmount[index] = 0;
                dailyInfo.withdrawAmount[index] = 0;
                dailyInfo.borrowAmount[index] = 0;
                dailyInfo.repayAmount[index] = 0;
            }
            dailyInfo.lastDateNumber = dateNumber;
        }

        for (uint256 index = 0; index < tokensInfo.length; index++) {
            address token = tokensInfo[index];
            if (token == _tokenAddress) {
                if (_type == 0) {
                    dailyInfo.depositAmount[index] += _amount;
                }
                if (_type == 1) {
                    dailyInfo.withdrawAmount[index] += _amount;
                }
                if (_type == 2) {
                    dailyInfo.borrowAmount[index] += _amount;
                }
                if (_type == 3) {
                    dailyInfo.repayAmount[index] += _amount;
                }
            }
        }
    }

    function getDailyInfo() external view returns (DailyInfo memory) {
        uint256 dateNumber = block.timestamp / 86400;
        if (dailyInfo.lastDateNumber == dateNumber) {
            return dailyInfo;
        } else {
            DailyInfo memory todayInfo;
            todayInfo.depositAmount = new uint256[](tokensInfo.length);
            todayInfo.withdrawAmount = new uint256[](tokensInfo.length);
            todayInfo.borrowAmount = new uint256[](tokensInfo.length);
            todayInfo.repayAmount = new uint256[](tokensInfo.length);
            for (uint256 index = 0; index < tokensInfo.length; index++) {
                todayInfo.depositAmount[index] = 0;
                todayInfo.withdrawAmount[index] = 0;
                todayInfo.borrowAmount[index] = 0;
                todayInfo.repayAmount[index] = 0;
            }
            todayInfo.lastDateNumber = dateNumber;
            return todayInfo;
        }
    }

    // calc collateral in usd
    function collateral(address _account) public returns (uint256) {
        calculateUser(_account);
        UserInfo storage currentUserInfo = userInfos[userInfoIndex[_account]];
        uint256 total;
        for (uint256 index = 0; index < tokensInfo.length; index++) {
            address token = tokensInfo[index];
            total += calcTokenPrice(
                token,
                currentUserInfo.tokenRewardAmount[token] +
                    currentUserInfo.tokenDepositAmount[token]
            );
        }
        return total;
    }

    // calc borrow in usd
    function debt(address _account) public returns (uint256) {
        calculateUser(_account);
        UserInfo storage currentUserInfo = userInfos[userInfoIndex[_account]];

        uint256 total;
        for (uint256 index = 0; index < tokensInfo.length; index++) {
            address token = tokensInfo[index];
            total += calcTokenPrice(
                token,
                currentUserInfo.tokenInterestAmount[token] +
                    currentUserInfo.tokenBorrowAmount[token]
            );
        }
        return total;
    }

    // borrow
    function borrow(address _tokenAddress, uint256 _amount) public {
        require(_amount > 0, "can't borrow 0");
        require(
            poolInfos[_tokenAddress].totalAmount >=
                poolInfos[_tokenAddress].borrowAmount + _amount,
            "pool does not have enough amount to lend"
        );
        uint256 userIndex = userInfoIndex[msg.sender];
        require(userIndex > 0, "User index should be bigger than 0.");
        UserInfo storage currentUserInfo = userInfos[userIndex];

        uint256 accountCollateral = collateral(msg.sender);
        uint256 accountDebt = debt(msg.sender);
        require(
            accountCollateral >= accountDebt,
            "You do not have any collateral."
        );

        uint256 borrowAmount = calcTokenPrice(_tokenAddress, _amount);
        uint256 LTV = poolInfos[_tokenAddress].LTV;
        require(
            (accountCollateral * LTV) / 100 >= borrowAmount + accountDebt,
            "Please deposit more."
        );

        currentUserInfo.tokenBorrowAmount[_tokenAddress] += _amount;
        calculateUser(msg.sender);

        if (_tokenAddress == tokensInfo[0]) {
            payable(msg.sender).sendValue(_amount);
            poolInfos[_tokenAddress].borrowAmount += _amount;
        } else {
            IERC20(_tokenAddress).transfer(msg.sender, _amount);
            poolInfos[_tokenAddress].borrowAmount += _amount;
        }
        calculateUser(msg.sender);
        //update daily info
        updateDailyInfo(_tokenAddress, _amount, 2);
    }

    function repay(address _tokenAddress, uint256 _amount) public payable {
        calculateUser(msg.sender);
        require(_amount > 0, "can't repay 0");
        uint256 userIndex = userInfoIndex[msg.sender];
        require(userIndex > 0, "User index should be bigger than 0.");
        UserInfo storage currentUserInfo = userInfos[userIndex];
        uint256 repayAmount = 0;

        if (currentUserInfo.tokenInterestAmount[_tokenAddress] > _amount) {
            currentUserInfo.tokenInterestAmount[_tokenAddress] -= _amount;
            poolInfos[_tokenAddress].totalAmount += _amount;
        } else {
            if (
                _amount >
                currentUserInfo.tokenInterestAmount[_tokenAddress] +
                    currentUserInfo.tokenBorrowAmount[_tokenAddress]
            ) {
                repayAmount = currentUserInfo.tokenBorrowAmount[_tokenAddress];
            } else {
                repayAmount = (_amount -
                    currentUserInfo.tokenInterestAmount[_tokenAddress]);
            }
            currentUserInfo.tokenBorrowAmount[_tokenAddress] -= repayAmount;
            currentUserInfo.tokenInterestAmount[_tokenAddress] = 0;

            poolInfos[_tokenAddress].totalAmount += (_amount - repayAmount);
            poolInfos[_tokenAddress].borrowAmount -= repayAmount;
        }
        if (_tokenAddress != tokensInfo[0]) {
            require(
                IERC20(_tokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    _amount
                ),
                "Repay failed"
            );
        } else {
            require(msg.value >= _amount, "Please pay more.");
            if (msg.value > _amount) {
                payable(msg.sender).sendValue(msg.value - _amount);
            }
        }
        calculateUser(msg.sender);
        //update daily info
        updateDailyInfo(_tokenAddress, _amount, 3);
    }

    function withdraw(address _tokenAddress, uint256 _amount) public {
        require(_amount > 0, "can't withdraw 0");
        uint256 userIndex = userInfoIndex[msg.sender];
        require(userIndex > 0, "User index should be bigger than 0.");
        UserInfo storage currentUserInfo = userInfos[userIndex];
        calculateUser(msg.sender);

        uint256 accountCollateral = collateral(msg.sender);
        uint256 accountDebt = debt(msg.sender);
        require(
            (accountCollateral * poolInfos[_tokenAddress].LTV) >=
                accountDebt + calcTokenPrice(_tokenAddress, _amount),
            "Withdraw failed.You donot have any collateral."
        );
        if (currentUserInfo.tokenRewardAmount[_tokenAddress] > _amount) {
            poolInfos[_tokenAddress].totalAmount -= _amount;
            currentUserInfo.tokenRewardAmount[_tokenAddress] -= _amount;
        } else {
            uint256 withdrawAmount = (_amount -
                currentUserInfo.tokenRewardAmount[_tokenAddress]);
            if (
                currentUserInfo.tokenDepositAmount[_tokenAddress] >=
                withdrawAmount
            ) {
                currentUserInfo.tokenDepositAmount[
                    _tokenAddress
                ] -= withdrawAmount;
            } else {
                currentUserInfo.tokenDepositAmount[_tokenAddress] = 0;
            }
            currentUserInfo.tokenRewardAmount[_tokenAddress] = 0;
            poolInfos[_tokenAddress].totalAmount -= _amount;
        }

        if (_tokenAddress == tokensInfo[0]) {
            payable(msg.sender).sendValue(
                (_amount * (10000 - withdrawFee)).div(10000)
            );
            payable(owner()).sendValue((_amount * withdrawFee).div(10000));
        } else {
            IERC20(_tokenAddress).transfer(
                msg.sender,
                (_amount * (10000 - withdrawFee)).div(10000)
            );
            IERC20(_tokenAddress).transfer(
                owner(),
                (_amount * withdrawFee).div(10000)
            );
        }

        calculateUser(msg.sender);
        //update daily info
        updateDailyInfo(_tokenAddress, _amount, 1);
    }

    function liquidate(address _account) public {
        uint256 userIndex = userInfoIndex[_account];
        require(userIndex > 0, "User index should be bigger than 0.");
        UserInfo storage currentUserInfo = userInfos[userIndex];

        uint256 accountCollateral = collateral(_account);
        uint256 accountDebt = debt(_account);
        require(
            accountDebt * 100 > accountCollateral * liquidationThreshhold,
            "This is not enabled liquidation"
        );

        //depost usdt to liquidate
        IERC20(tokensInfo[1]).transferFrom(
            msg.sender,
            address(this),
            accountDebt
        );
        for (uint256 index = 0; index < tokensInfo.length; index++) {
            address token = tokensInfo[index];
            uint256 supplyAmount = currentUserInfo.tokenDepositAmount[token] +
                currentUserInfo.tokenRewardAmount[token];
            uint256 borrowAmount = currentUserInfo.tokenBorrowAmount[token] +
                currentUserInfo.tokenInterestAmount[token];

            if (index == 1) {
                poolInfos[token].totalAmount += accountDebt;
            }

            poolInfos[token].totalAmount -= supplyAmount;

            poolInfos[token].borrowAmount -= currentUserInfo.tokenBorrowAmount[
                token
            ];
            if (index == 0) {
                if (supplyAmount > 0) {
                    payable(msg.sender).sendValue(
                        (supplyAmount * (10000 - withdrawFee)) / 10000
                    );
                    payable(owner()).sendValue(
                        (supplyAmount * withdrawFee) / 10000
                    );
                }
            } else {
                if (supplyAmount > 0) {
                    IERC20(token).transfer(
                        msg.sender,
                        (supplyAmount * (10000 - withdrawFee)).div(10000)
                    );
                    IERC20(token).transfer(
                        owner(),
                        (supplyAmount * withdrawFee).div(10000)
                    );
                }
            }
        }

        payable(msg.sender).sendValue(currentUserInfo.ethRewardAmount);

        clearUser(_account);
        calculateUser(msg.sender);
    }

    // user claim reward token
    function claimEthReward() public {
        uint256 userIndex = userInfoIndex[msg.sender];
        require(userIndex > 0, "User index should be bigger than 0.");
        UserInfo storage currentUserInfo = userInfos[userIndex];
        calculateUser(msg.sender);
        uint256 rewardAmount = currentUserInfo.ethRewardAmount;
        currentUserInfo.ethRewardAmount = 0;
        payable(msg.sender).sendValue(rewardAmount);
    }

    function fetchUserInfo(
        uint256 _userindex
    ) private view returns (UserInfoForDisplay memory) {
        UserInfoForDisplay memory currentUserInfoForDisplay;
        currentUserInfoForDisplay.depositAmount = new uint256[](
            tokensInfo.length
        );
        currentUserInfoForDisplay.borrowAmount = new uint256[](
            tokensInfo.length
        );
        currentUserInfoForDisplay.rewardAmount = new uint256[](
            tokensInfo.length
        );
        currentUserInfoForDisplay.interestAmount = new uint256[](
            tokensInfo.length
        );
        currentUserInfoForDisplay.depositTotalInUsdt = new uint256[](
            tokensInfo.length
        );
        currentUserInfoForDisplay.borrowTotalInUsdt = new uint256[](
            tokensInfo.length
        );
        if (_userindex > 0) {
            UserInfo storage currentUserInfo = userInfos[_userindex];

            uint256 lastTimestamp = currentUserInfo.lastInterest;
            uint256 timeDelta = block.timestamp - lastTimestamp;

            //start
            uint256 ethRewardAmount = currentUserInfo.ethRewardAmount;
            for (uint256 index = 0; index < tokensInfo.length; index++) {
                address token = tokensInfo[index];
                ethRewardAmount += calcEthForToken(
                    token,
                    (currentUserInfo.tokenDepositAmount[token] *
                        poolInfos[token].depositApy *
                        timeDelta) / decimal
                );
                uint256 interestAmount = currentUserInfo.tokenInterestAmount[
                    token
                ] +
                    (currentUserInfo.tokenBorrowAmount[token] *
                        poolInfos[token].borrowApy *
                        timeDelta) /
                    decimal;
                uint256 rewardAmount = currentUserInfo.tokenRewardAmount[
                    token
                ] +
                    (currentUserInfo.tokenDepositAmount[token] *
                        poolInfos[token].depositApy *
                        timeDelta) /
                    decimal;
                currentUserInfoForDisplay.depositAmount[index] = (
                    currentUserInfo.tokenDepositAmount[token]
                );
                currentUserInfoForDisplay.borrowAmount[index] = (
                    currentUserInfo.tokenBorrowAmount[token]
                );
                currentUserInfoForDisplay.interestAmount[index] = (
                    interestAmount
                );
                currentUserInfoForDisplay.rewardAmount[index] = (rewardAmount);
                currentUserInfoForDisplay.depositTotalInUsdt[index] = (
                    calcTokenPrice(
                        token,
                        currentUserInfo.tokenDepositAmount[token] + rewardAmount
                    )
                );
                currentUserInfoForDisplay.borrowTotalInUsdt[index] = (
                    calcTokenPrice(
                        token,
                        currentUserInfo.tokenBorrowAmount[token] +
                            interestAmount
                    )
                );

                currentUserInfoForDisplay
                    .totalCollateralInUsdt += calcTokenPrice(
                    token,
                    currentUserInfoForDisplay.rewardAmount[index] +
                        currentUserInfoForDisplay.depositAmount[index]
                );
                currentUserInfoForDisplay.totalDebtInUsdt += calcTokenPrice(
                    token,
                    currentUserInfoForDisplay.interestAmount[index] +
                        currentUserInfoForDisplay.borrowAmount[index]
                );
            }
            currentUserInfoForDisplay.ethRewardAmount = ethRewardAmount;
            currentUserInfoForDisplay.accountAddress = currentUserInfo
                .accountAddress;
            currentUserInfoForDisplay.isLiquidatable =
                (currentUserInfoForDisplay.totalDebtInUsdt * 100) >
                (currentUserInfoForDisplay.totalCollateralInUsdt *
                    liquidationThreshhold);
            //end
        } else {
            currentUserInfoForDisplay.accountAddress = msg.sender;
        }

        return currentUserInfoForDisplay;
    }

    function getUserInfo(
        address _account
    ) public view returns (UserInfoForDisplay memory) {
        uint256 userIndex = userInfoIndex[_account];
        UserInfoForDisplay memory userInfoDisplay = fetchUserInfo(userIndex);
        return userInfoDisplay;
    }

    function getMemberNumber() public view returns (uint256) {
        return maxUserIndex;
    }

    function listUserInfo(
        uint256 page
    ) public view returns (UserInfoForDisplay[] memory) {
        uint limit = 100;
        if (maxUserIndex >= page * limit) {
            uint256 destValue = 0;
            if (maxUserIndex >= (page + 1) * limit)
                destValue = (page + 1) * limit;
            else destValue = maxUserIndex;
            UserInfoForDisplay[] memory userList = new UserInfoForDisplay[](
                destValue - page * limit
            );
            for (uint i = page * limit + 1; i < destValue + 1; i++) {
                userList[i - 1 - page * limit] = (fetchUserInfo(i));
            }
            return userList;
        }
        return new UserInfoForDisplay[](0);
    }

    function liquidatableUsers()
        external
        view
        returns (UserInfoForDisplay[] memory)
    {
        uint256 count;
        for (uint256 index = 1; index <= maxUserIndex; index++) {
            UserInfoForDisplay memory info = fetchUserInfo(index);
            if (info.isLiquidatable) {
                count++;
            }
        }
        if (count > 0) {
            uint256 ii;
            UserInfoForDisplay[] memory userList = new UserInfoForDisplay[](
                count
            );
            for (uint256 index = 1; index <= maxUserIndex; index++) {
                UserInfoForDisplay memory info = fetchUserInfo(index);
                if (info.isLiquidatable) {
                    userList[ii] = info;
                    ii++;
                    if (ii == count) {
                        break;
                    }
                }
            }
            return userList;
        }
        return new UserInfoForDisplay[](0);
    }

    function getMarketInfo() public view returns (uint256, uint256) {
        uint256 totalAmount;
        uint256 totalBorrowAmount;
        for (uint256 index = 0; index < tokensInfo.length; index++) {
            address token = tokensInfo[index];
            PoolInfo storage pool = poolInfos[token];
            totalAmount += calcTokenPrice(token, pool.totalAmount);
            totalBorrowAmount += calcTokenPrice(token, pool.borrowAmount);
        }
        return (totalAmount, totalBorrowAmount);
    }

    function getPoolInfo(
        address _poolAddress
    ) public view returns (PoolInfo memory) {
        PoolInfo memory currentPool = poolInfos[_poolAddress];
        currentPool.depositApy = currentPool.depositApy.div(secondApy);
        currentPool.borrowApy = currentPool.borrowApy.div(secondApy);
        return currentPool;
    }

    function listPools() public view returns (PoolInfo[] memory) {
        PoolInfo[] memory poolList = new PoolInfo[](tokensInfo.length);
        for (uint256 index = 0; index < tokensInfo.length; index++) {
            address token = tokensInfo[index];
            PoolInfo memory pool = poolInfos[token];
            pool.depositApy = pool.depositApy.div(secondApy);
            pool.borrowApy = pool.borrowApy.div(secondApy);
            poolList[index] = pool;
        }
        return poolList;
    }

    receive() external payable {}

    fallback() external payable {}
}
