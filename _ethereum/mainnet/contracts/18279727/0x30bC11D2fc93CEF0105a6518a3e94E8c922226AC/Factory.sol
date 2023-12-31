// SPDX-License-Identifier: MIT


pragma solidity >0.8.0;

interface IStartUpLocker {
    function lock(
        bool isLP,
        address token,
        address user,
        uint256 amount,
        uint256 cliff,
        uint256 cliffPercentage,
        uint256 cycle,
        uint256 releasePerCycle,
        string memory description
    ) external returns (uint256 id);
}

// File: contracts/Stealth/interfaces/IUniswapV2Router.sol


pragma solidity >=0.8.0;

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
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountsOut(
        uint256 amountIn,
        address[] memory path
    ) external view returns (uint256[] memory amounts);
}

// File: contracts/Stealth/interfaces/IUniswapV2Factory.sol


pragma solidity >=0.8.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: contracts/Stealth/Factory.sol



pragma solidity ^0.8.0;









interface IERC20Extend {
    function decimals() external view returns (uint8);
}

contract Factory is Context, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    event LPLocked(
        uint256 id,
        address token,
        uint256 amount,
        uint256 lockUpTime,
        address lockOwner
    );

    event PairDeployed(
        uint256 indexed pairID,
        address indexed token,
        uint256 initialLiquidity,
        uint256 tokensAmount,
        uint256 lpLockingPeriod,
        string logo,
        string website,
        string community
    );

    event TreasuryClaimed(
        address indexed user,
        uint256 pairID,
        address indexed pairToken,
        uint256 amountClaimed,
        uint256 distributionIndex
    );

    address public uniswapRouter;

    address public constant deadAddr =
        0x000000000000000000000000000000000000dEaD;

    address public devWallet;

    address public lockAddress;

    address public supToken;

    uint256 public supWhitelistFee;

    uint256 public supTreasuryRequirement;

    uint256 public treasuryFee = 250;

    uint256 public maxTreasuryReceivers = 50;

    uint256 public totalPairs = 1;

    uint256 public totalInitialLiquidity;

    uint256 public totalDistributionsEthValue;

    uint256 public bountyAmnt = 500_000 * 1e8;

    uint256 public maxBountyReceivers = 200;

    struct ScamProjects {
        address bountyReceiver;
        string comment;
    }

    mapping(uint256 => bool) private _scamTokens;
    mapping(uint256 => ScamProjects) private _scamTokensInfo;

    struct Pairs {
        address token;
        uint256 initialLiquidity;
        uint256 tokensAmount;
        uint256 distributionPerSupWallet;
        uint256 distributionIndex;
        uint256 lpLockingPeriod;
        uint256 lockID;
        uint256 launchDate;
        string logo;
        string website;
        string community;
    }

    mapping(uint256 => Pairs) private _pairs;
    mapping(address => uint256) private _pairIds;
    mapping(uint256 => bool) private _treasuryNotClaimablePairs; // pairID => bool
    mapping(uint256 => bool) private _verifiedTokens;
    mapping(address => mapping(uint256 => uint256)) private _claimedBalances; // pairID => _claimedBalances

    mapping(address => bool) private _whitelistedWallets;

    constructor(address _locker) {
        lockAddress = _locker;
        devWallet = msg.sender;

        supTreasuryRequirement = 15000 * 1e8;

        _whitelistedWallets[msg.sender] = true;

        if (block.chainid == 56) {
            uniswapRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        } else if (block.chainid == 97) {
            uniswapRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
        } else if (
            block.chainid == 1 ||
            block.chainid == 4 ||
            block.chainid == 3 ||
            block.chainid == 5
        ) {
            uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
            //Ropstein DAI 0xaD6D458402F60fD3Bd25163575031ACDce07538D
        } else if (block.chainid == 43114) {
            uniswapRouter = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        } else if (block.chainid == 250) {
            uniswapRouter = 0x31F63A33141fFee63D4B26755430a390ACdD8a4d;
        } else if (block.chainid == 42161) {
            uniswapRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
        } else if (block.chainid == 80001) {
            uniswapRouter = 0x8954AfA98594b838bda56FE4C12a09D7739D179b;
        } else {
            revert();
        }
    }

    function setSupToken(address _newSupToken) public onlyOwner {
        require(_newSupToken != address(0), "Invalid address");
        supToken = _newSupToken;
    }

    function setSupTreasuryRequirement(
        uint256 _newRequirement
    ) external onlyOwner {
        supTreasuryRequirement = _newRequirement;
    }

    function setTreasuryFee(uint256 _newFee) public onlyOwner {
        require(_newFee <= 1_000, "Fee cannot exceed the maximum allowed");
        treasuryFee = _newFee;
    }

    function addToNoTreasuryPool(uint256 pairID) public onlyOwner {
        _treasuryNotClaimablePairs[pairID] = true;
    }

    function removeFromNoTreasuryPool(uint256 pairID) public onlyOwner {
        _treasuryNotClaimablePairs[pairID] = false;
    }

    function istreasuryNotClaimable(uint256 pairID) public view returns (bool) {
        return _treasuryNotClaimablePairs[pairID];
    }

    function addToWhitelist(address wallet) public onlyOwner {
        _whitelistedWallets[wallet] = true;
    }

    function removeFromWhitelist(address wallet) public onlyOwner {
        _whitelistedWallets[wallet] = false;
    }

    function isTokenVerified(uint256 pairID) public view returns (bool) {
        return _verifiedTokens[pairID];
    }

    function verifyToken(address tokenAddr) public onlyOwner {
        uint256 pairID = getPairIdByTokenAddress(tokenAddr);
        _verifiedTokens[pairID] = true;
    }

    function removeVerifyToken(address tokenAddr) public onlyOwner {
        uint256 pairID = getPairIdByTokenAddress(tokenAddr);
        _verifiedTokens[pairID] = false;
    }

    function addToScamList(
        address tokenAddr,
        address bountyReceiver,
        string memory comment
    ) public onlyOwner {
        uint256 bountyTreasuryPerWallet = bountyAmnt / maxBountyReceivers;

        if (
            IERC20(supToken).balanceOf(address(this)) >=
            bountyTreasuryPerWallet &&
            !_whitelistedWallets[bountyReceiver]
        ) {
            SafeERC20.safeTransfer(
                IERC20(supToken),
                bountyReceiver,
                bountyTreasuryPerWallet
            );
        }

        uint256 pairID = getPairIdByTokenAddress(tokenAddr);

        ScamProjects memory newScamProject = ScamProjects(
            bountyReceiver,
            comment
        );

        _scamTokensInfo[pairID] = newScamProject;

        _scamTokens[pairID] = true;
    }

    function removeFromScamList(address tokenAddr) public onlyOwner {
        uint256 pairID = getPairIdByTokenAddress(tokenAddr);
        _scamTokens[pairID] = false;
    }

    function getScamProjectInfo(
        uint256 tokenId
    ) external view returns (address, string memory) {
        ScamProjects memory scamProjectInfo = _scamTokensInfo[tokenId];
        return (scamProjectInfo.bountyReceiver, scamProjectInfo.comment);
    }

    function setMaxTreasuryReceivers(uint256 _newMax) external onlyOwner {
        maxTreasuryReceivers = _newMax;
    }

    function isWhitelisted(address wallet) public view returns (bool) {
        return _whitelistedWallets[wallet];
    }

    function isInScamList(uint256 pairId) public view returns (bool) {
        return _scamTokens[pairId];
    }

    function getInitialPairPrice(uint256 pairId) public view returns (uint256) {
        address token = _pairs[pairId].token;
        uint256 tokensAmount = _pairs[pairId].tokensAmount;
        uint256 initialLiquidity = _pairs[pairId].initialLiquidity *
            10 ** IERC20Extend(token).decimals(); //Adjusted

        return initialLiquidity / tokensAmount;
    }

    function getCurrentPairPrice(uint256 pairId) public view returns (uint256) {
        address token = _pairs[pairId].token;
        address pair = getPair(token);

        uint256 totalEth = IERC20(IUniswapV2Router01(uniswapRouter).WETH())
            .balanceOf(pair) * 10 ** IERC20Extend(token).decimals();
        uint256 tokenBalance = IERC20(token).balanceOf(pair);

        return totalEth / tokenBalance;
    }

    function getPairIdByTokenAddress(
        address tokenAddress
    ) public view returns (uint256) {
        return _pairIds[tokenAddress];
    }

    function getPairData(
        uint256 pairID
    )
        public
        view
        returns (
            address token,
            uint256 initialLiquidity,
            uint256 tokensAmount,
            uint256 distributionPerSupWallet,
            uint256 distributionIndex,
            uint256 lpLockingPeriod,
            uint256 lockID,
            uint256 launchDate,
            string memory logo,
            string memory website,
            string memory community
        )
    {
        Pairs memory pair = _pairs[pairID];
        return (
            pair.token,
            pair.initialLiquidity,
            pair.tokensAmount,
            pair.distributionPerSupWallet,
            pair.distributionIndex,
            pair.lpLockingPeriod,
            pair.lockID,
            pair.launchDate,
            pair.logo,
            pair.website,
            pair.community
        );
    }

    function getUserClaimedBalanceById(
        address user,
        uint256 pairID
    ) public view returns (uint256) {
        return _claimedBalances[user][pairID];
    }

    function subscribeToPremium() public {
        require(supToken != address(0), "Token is undefined");
        require(!isWhitelisted(_msgSender()), "Already premium");
        require(supWhitelistFee > 0, "Disabled");
        uint256 supBalance = IERC20(supToken).balanceOf(_msgSender());
        require(supBalance >= supWhitelistFee, "Not enough $SUP");

        addToWhitelist(_msgSender());
        IERC20(supToken).transferFrom(_msgSender(), deadAddr, supWhitelistFee);
    }

    function deployPair(
        address _token,
        uint256 _tokensAmount,
        uint256 lpLockingPeriod,
        string memory _logo,
        string memory _website,
        string memory _community
    ) public payable {
        require(msg.value >= 0.1 ether, "Minimum liquidity is 0.1 ether");
        require(!hasEthLiquidity(_token), "Liquidity already added");

        bool _isWhitelisted = _whitelistedWallets[_msgSender()];

        if (_isWhitelisted) {
            deployPairWhithoutFee(
                _token,
                _tokensAmount,
                lpLockingPeriod,
                _logo,
                _website,
                _community
            );
        } else {
            deployPairWithFee(
                _token,
                _tokensAmount,
                lpLockingPeriod,
                _logo,
                _website,
                _community
            );
        }
    }

    function deployPairWithFee(
        address _token,
        uint256 _tokensAmount,
        uint256 lpLockingPeriod,
        string memory _logo,
        string memory _website,
        string memory _community
    ) internal {
        require(msg.value >= 0.1 ether, "Minimum liquidity is 0.1 ether");
        require(!hasEthLiquidity(_token), "Liquidity already added");

        uint256 supCommunityAlloc = (_tokensAmount * treasuryFee) / 10_000;
        uint256 supCommunityAllocPerWallet = supCommunityAlloc /
            maxTreasuryReceivers;

        Pairs storage newPair = _pairs[totalPairs];
        newPair.token = _token;
        newPair.initialLiquidity = msg.value;
        newPair.tokensAmount = _tokensAmount - supCommunityAlloc;
        newPair.distributionPerSupWallet = supCommunityAllocPerWallet;
        newPair.distributionIndex = 0;
        newPair.lpLockingPeriod = lpLockingPeriod;
        newPair.launchDate = block.timestamp;
        newPair.logo = _logo;
        newPair.website = _website;
        newPair.community = _community;

        _pairIds[_token] = totalPairs;

        totalPairs++;
        totalInitialLiquidity += msg.value;

        IERC20(_token).transferFrom(_msgSender(), address(this), _tokensAmount);

        uint256 tokensAmountAfterDeduction = _tokensAmount - supCommunityAlloc;

        _addLiquidity(_token, tokensAmountAfterDeduction, msg.value);

        //Trasnfer LP fee

        address possibleLP = getPair(_token);
        uint256 lpAmount = IERC20(possibleLP).balanceOf(address(this));
        uint256 _fee = (lpAmount * treasuryFee) / 10_000;

        IERC20(possibleLP).transfer(devWallet, _fee);

        lpAmount -= _fee;

        if (lpLockingPeriod == 0) {
            IERC20(possibleLP).transfer(_msgSender(), lpAmount);
            newPair.lockID = 1e8;
        } else {
            newPair.lockID = _lockLP(_token, lpLockingPeriod, _msgSender());
        }

        emit PairDeployed(
            totalPairs - 1,
            _token,
            msg.value,
            _tokensAmount,
            lpLockingPeriod,
            _logo,
            _website,
            _community
        );
    }

    function deployPairWhithoutFee(
        address _token,
        uint256 _tokensAmount,
        uint256 lpLockingPeriod,
        string memory _logo,
        string memory _website,
        string memory _community
    ) internal {
        Pairs storage newPair = _pairs[totalPairs];
        newPair.token = _token;
        newPair.initialLiquidity = msg.value;
        newPair.tokensAmount = _tokensAmount;
        newPair.distributionPerSupWallet = 0; // No community allocation
        newPair.distributionIndex = 0;
        newPair.lpLockingPeriod = lpLockingPeriod;
        newPair.launchDate = block.timestamp;
        newPair.logo = _logo;
        newPair.website = _website;
        newPair.community = _community;

        _pairIds[_token] = totalPairs;

        _treasuryNotClaimablePairs[totalPairs] = true;
        totalPairs++;
        totalInitialLiquidity += msg.value;

        IERC20(_token).transferFrom(_msgSender(), address(this), _tokensAmount);

        _addLiquidity(_token, _tokensAmount, msg.value);

        address possibleLP = getPair(_token);

        if (lpLockingPeriod == 0) {
            IERC20(possibleLP).transfer(
                _msgSender(),
                IERC20(possibleLP).balanceOf(address(this))
            );
        } else {
            newPair.lockID = _lockLP(_token, lpLockingPeriod, _msgSender());
        }

        emit PairDeployed(
            totalPairs - 1,
            _token,
            msg.value,
            _tokensAmount,
            lpLockingPeriod,
            _logo,
            _website,
            _community
        );
    }

    function _addLiquidity(
        address token,
        uint256 amount,
        uint256 initialLiquidity
    ) internal {
        _approve(token, address(uniswapRouter), amount);

        IUniswapV2Router01(uniswapRouter).addLiquidityETH{
            value: initialLiquidity
        }(
            token,
            amount,
            amount,
            initialLiquidity,
            address(this),
            block.timestamp + 120
        );
    }

    function _lockLP(
        address token,
        uint256 lockUpTime,
        address lockOwner
    ) internal returns (uint256 id) {
        address possibleLP = getPair(token);
        uint256 amount = IERC20(possibleLP).balanceOf(address(this));
        uint256 newLockUpTime = block.timestamp + lockUpTime;
        _approve(address(possibleLP), address(lockAddress), amount);

        id = IStartUpLocker(lockAddress).lock(
            true,
            possibleLP,
            lockOwner,
            amount,
            newLockUpTime,
            0,
            0,
            0,
            "STEALTH LOCK"
        );
        emit LPLocked(id, possibleLP, amount, newLockUpTime, lockOwner);
    }

    function isClaimable(
        address user,
        uint256 pairID
    ) public view returns (bool) {
        uint256 supBalance = IERC20(supToken).balanceOf(user);
        if (
            _pairs[pairID].distributionIndex >= maxTreasuryReceivers ||
            _claimedBalances[user][pairID] > 0 ||
            supBalance < supTreasuryRequirement ||
            isInScamList(pairID) ||
            istreasuryNotClaimable(pairID)
        ) {
            return false;
        } else {
            return true;
        }
    }

    function claimTreasury(uint256 pairID) public nonReentrant {
        require(isClaimable(_msgSender(), pairID), "Tokens are not claimable");
        uint256 pairAllocPerWallet = _pairs[pairID].distributionPerSupWallet;
        address pairToken = _pairs[pairID].token;

        IERC20(pairToken).transfer(_msgSender(), pairAllocPerWallet);

        _pairs[pairID].distributionIndex++;
        _claimedBalances[_msgSender()][pairID] = pairAllocPerWallet;

        uint256 valueInEth = (pairAllocPerWallet * getCurrentPairPrice(pairID));

        totalDistributionsEthValue += valueInEth;

        emit TreasuryClaimed(
            _msgSender(),
            pairID,
            pairToken,
            pairAllocPerWallet,
            _pairs[pairID].distributionIndex
        );
    }

    function getPair(address token) public view returns (address) {
        address pair;
        address factory = IUniswapV2Router01(uniswapRouter).factory();
        address wEth = IUniswapV2Router01(uniswapRouter).WETH();
        pair = IUniswapV2Factory(factory).getPair(token, wEth);
        return pair;
    }

    function _approve(
        address tokenAddr,
        address spender,
        uint256 amount
    ) internal {
        SafeERC20.safeIncreaseAllowance(IERC20(tokenAddr), spender, amount);
    }

    function hasEthLiquidity(address tokenAddress) public view returns (bool) {
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = IUniswapV2Router01(uniswapRouter).WETH();

        try
            IUniswapV2Router01(uniswapRouter).getAmountsOut(0.01 ether, path)
        returns (uint256[] memory amounts) {
            return amounts[1] > 0;
        } catch {
            return false;
        }
    }
}