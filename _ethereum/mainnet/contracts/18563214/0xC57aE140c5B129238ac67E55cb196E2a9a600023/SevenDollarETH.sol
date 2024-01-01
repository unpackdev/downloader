// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
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
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
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
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
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
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
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
    function values(AddressSet storage set) internal view returns (address[] memory) {
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
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
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
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

interface ISevenDollarETH {
    struct Status {
        bool unlocked;
        bool claimed;
        uint120 count;
        uint120 lastJoinedBlock;
    }

    struct Child {
        address left;
        address right;
    }

    struct Node {
        Child child;
        Status status;
    }

    /**
     * @dev Emitted when the system is initialized by the `firstPlayer`.
     */
    event Initialized(address firstPlayer, uint256 timestamp);

    /**
     * @dev Emitted when a new `player` joins at `timestamp` being
     * attached to the `parent` if `asRightChild` is true.
     */
    event Joined(
        address indexed player,
        address parent,
        bool asRightChild,
        uint256 timestamp
    );

    /**
     * @dev Emitted when `account` has claimed rewards bringing the
     * total number of claims up to `count`.
     */
    event Claimed(address indexed account, uint256 count);

    /**
     * @dev Emitted when `account` is removed from the pool of open ends.
     */
    event OpenEndRemoved(address indexed account);

    /**
     * @dev Emitted when `amount` of ETHs gets recovered as unclaimed fees.
     */
    event UnclaimedFeesRecovered(uint256 amount);

    /**
     * @dev Emitted when `amount` of ETHs gets recovered and sent to
     * `recipient`.
     */
    event UnclaimedETHsRecovered(address recipient, uint256 amount);

    /**
     * @dev Initializes the game.
     */
    function initialize() external payable;

    /**
     * @dev Joins the game by providing `parent`'s wallet address.
     */
    function join(address parent) external payable;

    /**
     * @dev Joins to a node with 50% chance being the first node and
     * 50% being a random node other than the first.
     */
    function join2() external payable;

    /**
     * @dev Claims a reward.
     */
    function claim() external;

    /**
     * @dev Claim the fee that is less than the threshold to be automatically
     * transferred to treasury.
     */
    function recoverUnclaimedFees() external;

    /**
     * @dev Recovers the unclaimed ETHs in this contract to Vitalik's wallet.
     */
    function recoverUnclaimedETHs() external;

    /**
     * @dev Returns if a given `account` is an open end.
     */
    function isOpenEnd(address account) external view returns (bool);

    /**
     * @dev Returns the number of children for a given node.
     */
    function getNumOfChildren(address account) external view returns (uint256);

    /**
     * @dev Returns the number of open ends.
     */
    function getNumOfOpenEnds() external view returns (uint256);

    /**
     * @dev Returns the account at the `idx`-th open end.
     */
    function getOpenEndAt(uint256 idx) external view returns (address);

    /**
     * @dev Returns an array of `num` of accounts that are open ends.
     */
    function getOpenEnds(uint256 num) external view returns (address[] memory);

    /**
     * @dev Returns the node struct information of a provided `account`.
     */
    function checkNode(address account) external view returns (Node memory);

    /**
     * @dev Returns the ETH balance of this contract.
     */
    function getETHBalance() external view returns (uint256);

    /**
     * @dev Returns the latest ETH USD price returned from Chainlink Oracle.
     */
    function getETHUSDPrice() external view returns (uint256);
}

interface IOracle {
    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80);
}

contract SevenDollarETH is ISevenDollarETH, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    address public constant VITALIK1 =
        0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045; // Vitalik Buterin wallet (1)
    address public constant VITALIK2 =
        0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B; // Vitalik Buterin wallet (2)
    address public constant ETH_USD_ORACLE =
        0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // Chainlink ETH/USD oracle
    uint256 public constant UNIT_AMOUNT = 1 ether; // 1 ETH
    uint256 public constant AUTO_FEE_FACTOR = 1; // a factor applied for each deployment
    uint256 public constant MAX_COUNT = 100; // each wallet can play at most 100 times
    uint256 public constant FEE_MULTIPLE = 7; // $7 or $1
    uint256 public constant SEVEN_YEARS = 7 * 365 * 24 * 3600; // 7 years
    uint256 public constant MAX_AMOUNT = 7_000_000 * UNIT_AMOUNT; // 7 million ETHs
    uint256 public constant DECIMAL_PRECISIONS = 1 ether; // 1 ETH
    uint256 public constant TARGET_DECIMALS = 8; // 8 decimals
    uint256 public constant DENOMINATOR = 100; // 1 / 100 = 1%
    uint256 public constant NUM = 10; // max length of a returned array

    address public immutable treasury; // treasury address
    address public immutable thisAddr; // this contract address
    uint256 public immutable endTimestamp; // The end timestamp of this game
    IOracle public immutable oracle; // ETH/USD oracle

    uint256 public feeAmount; // fee amount to be collected by the treasury
    bool public endedByVitalik; // whether this game is ended by Vitalik
    bool private _initialized; // whether this game is initialized

    mapping(address => Node) private _tree; // the tree structure
    EnumerableSet.AddressSet private _openEnds; // the set of open ends

    receive() external payable {
        revert("Direct sending ETHs disallowed");
    }

    constructor(address _treasury) {
        require(_treasury != address(0), "Invalid address");
        treasury = _treasury;
        thisAddr = address(this);
        endTimestamp = _getBlockTime() + SEVEN_YEARS; // 7 years
        require(ETH_USD_ORACLE.isContract(), "Invalid oracle address");
        oracle = IOracle(ETH_USD_ORACLE);
    }

    modifier onlyVitalik() {
        require(
            msg.sender == VITALIK1 || msg.sender == VITALIK2,
            "Not Vitalik"
        );
        _;
    }

    modifier onlyOneUnit() {
        require(msg.value == UNIT_AMOUNT, "Incorrect value");
        _;
    }

    modifier onlyNotEndedByVitalik() {
        require(!endedByVitalik, "Ended by Vitalik");
        _;
    }

    modifier onlyValidContext() {
        _requireValidContext();
        _;
    }

    function initialize()
        external
        payable
        override
        onlyOneUnit
        onlyValidContext
    {
        require(!_initialized, "Already initialized");
        _initialized = true;
        address firstPlayer = msg.sender;
        _tree[firstPlayer].status.lastJoinedBlock = _getBlockNum();
        _openEnds.add(firstPlayer);

        emit Initialized(firstPlayer, _getBlockTime());
    }

    function join(
        address _parent
    )
        external
        payable
        override
        nonReentrant
        onlyOneUnit
        onlyNotEndedByVitalik
        onlyValidContext
    {
        address _player = msg.sender;
        _beforeJoin(_parent, _player);
        _join(_parent, _player);
    }

    function join2()
        external
        payable
        override
        nonReentrant
        onlyOneUnit
        onlyNotEndedByVitalik
        onlyValidContext
    {
        address _parent = _getOpenEnd(); // use a random open end as parent
        address _player = msg.sender;
        _beforeJoin(_parent, _player);
        _join(_parent, _player);
    }

    function claim()
        external
        override
        nonReentrant
        onlyNotEndedByVitalik
        onlyValidContext
    {
        address _caller = msg.sender;
        require(_validateClaiming(_caller), "Invalid caller");

        Node storage node = _tree[_caller];
        Status memory newStatus = Status({
            unlocked: false,
            claimed: true,
            count: node.status.count + 1,
            lastJoinedBlock: node.status.lastJoinedBlock
        });
        delete node.child;
        node.status = newStatus;

        _makeTransfer(_caller); // to caller and possibly treasury

        emit Claimed(_caller, newStatus.count);
    }

    function recoverUnclaimedFees()
        external
        override
        nonReentrant
        onlyValidContext
    {
        uint256 unclaimedFeeAmount = feeAmount;
        require(unclaimedFeeAmount > 0, "No fees to recover");
        feeAmount = 0;
        _safeTransferETH(treasury, unclaimedFeeAmount);

        emit UnclaimedFeesRecovered(unclaimedFeeAmount);
    }

    function recoverUnclaimedETHs()
        external
        override
        onlyVitalik
        onlyNotEndedByVitalik
    {
        endedByVitalik = true;
        uint256 amount = _validateRecovering();
        _safeTransferETH(msg.sender, amount);

        emit UnclaimedETHsRecovered(msg.sender, amount);
    }

    function isOpenEnd(address account) external view override returns (bool) {
        return _isOpenEnd(account);
    }

    function getNumOfChildren(
        address account
    ) external view override returns (uint256) {
        Node memory node = _tree[account];
        return _getNumOfChildren(node);
    }

    function getNumOfOpenEnds() public view override returns (uint256) {
        return _openEnds.length();
    }

    function getOpenEndAt(uint256 idx) public view override returns (address) {
        return _openEnds.at(idx);
    }

    function getOpenEnds(
        uint256 num
    ) external view override returns (address[] memory) {
        if (num > NUM) num = NUM;
        uint256 total = getNumOfOpenEnds();
        uint256 n = total > num ? num : total;
        address[] memory _arr = new address[](n);

        for (uint256 i = 0; i < n; i++) {
            _arr[i] = _openEnds.at(i);
        }

        return _arr;
    }

    function checkNode(
        address account
    ) external view override returns (Node memory) {
        return _tree[account];
    }

    function getETHBalance() external view override returns (uint256) {
        return address(this).balance;
    }

    function getETHUSDPrice() external view override returns (uint256) {
        return _getETHUSDPrice();
    }

    function _join(address _parent, address _player) private {
        _tree[_player].status.lastJoinedBlock = _getBlockNum();
        _openEnds.add(_player);

        bool asRightChild; // if joined as the right child of the parent
        Node storage parent = _tree[_parent];

        if (parent.child.left == address(0)) {
            parent.child.left = _player;
        } else {
            if (parent.child.right == address(0)) {
                parent.child.right = _player;
                asRightChild = true;
                Status memory newStatus = Status({
                    unlocked: true,
                    claimed: false,
                    count: parent.status.count,
                    lastJoinedBlock: parent.status.lastJoinedBlock
                });
                parent.status = newStatus;
                _openEnds.remove(_parent);

                emit OpenEndRemoved(_parent);
            } else {
                revert("Invalid parent");
            }
        }

        emit Joined(_player, _parent, asRightChild, _getBlockTime());
    }

    /**
     * @dev Determines a parent address from the `_openEnds` set.
     *
     * There's a 50% chance to return the first address in the set. The first occurrence is FIFO,
     * while subsequent occurrences are LIFO due to the `EnumerableSet.AddressSet` data structure.
     *
     * The other 50% returns a random address from the set, excluding the first one.
     *
     * @return address The selected parent address from the `_openEnds` set.
     */
    function _getOpenEnd() private view returns (address) {
        uint256 numOfOpenEnds = getNumOfOpenEnds();
        if (numOfOpenEnds == 0) return address(0);
        if (numOfOpenEnds == 1) return getOpenEndAt(0);
        bytes32 blockHash = blockhash(block.number - 1);
        bool isFirstOpenEnd = uint256(blockHash) % 2 == 1;
        if (isFirstOpenEnd) {
            return getOpenEndAt(0);
        } else {
            uint256 idx = (uint256(keccak256(abi.encodePacked(blockHash))) %
                (numOfOpenEnds - 1)) + 1; // Skip 0
            return getOpenEndAt(idx);
        }
    }

    function _beforeJoin(address _parent, address _player) private view {
        require(_validateJoining(_parent, _player), "Invalid conditions");
    }

    function _makeTransfer(address account) private {
        uint256 deductedAmount = _getDeductedAmount();
        if (2 * UNIT_AMOUNT <= deductedAmount) deductedAmount = 0;
        uint256 amount = 2 * UNIT_AMOUNT - deductedAmount;
        if (feeAmount + deductedAmount >= AUTO_FEE_FACTOR * UNIT_AMOUNT) {
            uint256 tmpFeeAmount = feeAmount;
            uint256 gasCompensation = deductedAmount / FEE_MULTIPLE; // roughly $1
            amount += gasCompensation;
            deductedAmount -= gasCompensation;
            feeAmount = 0;
            _safeTransferETH(treasury, tmpFeeAmount + deductedAmount);
        } else {
            feeAmount += deductedAmount;
        }

        _safeTransferETH(account, amount);
    }

    function _safeTransferETH(address recipient, uint256 amount) private {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Payment is not successful");
    }

    function _validateJoining(
        address _parent,
        address _player
    ) private view returns (bool flag) {
        bool flag1;
        bool flag2;
        {
            bool cond1 = _parent != address(0);
            bool cond2 = !_parent.isContract();
            bool cond3 = _parent != _player;
            bool cond4 = !_player.isContract();
            flag1 = cond1 && cond2 && cond3 && cond4;
        }

        Node memory parent = _tree[_parent];
        {
            // For clarity and readability, the checking in `cond8` is kept
            // even though it is identical with the checking in `cond7`.
            bool cond5 = parent.status.count < MAX_COUNT;
            bool cond6 = parent.status.lastJoinedBlock > 0;
            bool cond7 = !parent.status.unlocked;
            bool cond8 = _getNumOfChildren(parent) < 2;
            bool cond9 = _isOpenEnd(_parent);
            bool cond10 = _getBlockNum() > parent.status.lastJoinedBlock;
            flag2 = cond5 && cond6 && cond7 && cond8 && cond9 && cond10;
        }

        flag = flag1 && flag2;

        Node memory player = _tree[_player];
        if (player.status.lastJoinedBlock > 0) {
            bool flag3;
            {
                bool cond11 = player.status.count < MAX_COUNT;
                bool cond12 = !player.status.unlocked;
                // each player cannot attach to the tree twice at any time
                bool cond13 = !_isOpenEnd(_player);
                flag3 = cond11 && cond12 && cond13;
            }
            flag = flag && flag3;
        }
    }

    function _validateClaiming(address _caller) private view returns (bool) {
        Node memory node = _tree[_caller];
        bool cond1 = node.status.unlocked;
        bool cond2 = !node.status.claimed;
        bool cond3 = _getBlockNum() > node.status.lastJoinedBlock;
        return cond1 && cond2 && cond3;
    }

    function _validateRecovering() private view returns (uint256 amount) {
        bool cond1 = _getBlockTime() > endTimestamp;
        bool cond2 = thisAddr.balance > MAX_AMOUNT;
        require(cond1 || cond2, "Recovering conditions not met");
        bool cond3 = thisAddr.balance > feeAmount;
        require(cond3, "No ETH to be recovered");
        amount = thisAddr.balance - feeAmount;
    }

    function _isOpenEnd(address account) private view returns (bool) {
        return _openEnds.contains(account);
    }

    function _requireValidContext() private view {
        // solhint-disable-next-line avoid-tx-origin
        bool cond1 = msg.sender == tx.origin; // no delegate call
        bool cond2 = address(this) == thisAddr; // no proxies
        require(cond1 && cond2, "Invalid context");
    }

    function _getNumOfChildren(
        Node memory node
    ) private pure returns (uint256 num) {
        if (node.child.left != address(0)) ++num;
        if (node.child.right != address(0)) ++num;
    }

    function _getDeductedAmount() private view returns (uint256) {
        uint256 price = _getETHUSDPrice();
        if (price > 0) {
            return (FEE_MULTIPLE * DECIMAL_PRECISIONS * 10 ** TARGET_DECIMALS) / price;
        } else {
            // Fix the fee at 1% of UNIT_AMOUNT if oracle is broken
            return UNIT_AMOUNT / DENOMINATOR;
        }
    }

    function _getETHUSDPrice() private view returns (uint256 price) {
        (, int256 price0, , , ) = oracle.latestRoundData();
        if (price0 > 0) price = uint256(price0);
    }

    function _getBlockNum() private view returns (uint120) {
        return uint120(block.number);
    }

    function _getBlockTime() private view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }
}