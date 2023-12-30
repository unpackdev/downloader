/*
 * Crypto stamp 2 Achievements
 * Awarding Achievements for collecting digital-physical collectible postage stamps
 *
 * Developed by Capacity Blockchain Solutions GmbH <capacity.at>
 * for Österreichische Post AG <post.at>
 */

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/introspection/IERC165.sol

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

pragma solidity ^0.6.2;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transfered from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from`, `to` cannot be zero.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from`, `to` cannot be zero.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from`, `to` cannot be zero.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Metadata.sol

pragma solidity ^0.6.2;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol

pragma solidity ^0.6.2;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

pragma solidity ^0.6.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
abstract contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public virtual returns (bytes4);
}

// File: @openzeppelin/contracts/introspection/ERC165.sol

pragma solidity ^0.6.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
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

// File: contracts/EnumerableMapSimple.sol

pragma solidity ^0.6.0;

library EnumerableMapSimple {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Map {
        // Storage of map keys and values
        bytes32[] _entries;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        uint256 uintKey = uint256(key);
        require(uintKey <= map._entries.length, "Cannot add entry that is not connected to existing IDs");

        if (uintKey == map._entries.length) { // add new entry
            map._entries.push(value);
            return true;
        } else {
            map._entries[uintKey] = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage /*map*/, bytes32 /*key*/) private pure returns (bool) {
        revert("No removal supported");
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return uint256(key) < map._entries.length;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");
        return (bytes32(index), map._entries[index]);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 uintKey = uint256(key);
        require(map._entries.length > uintKey, errorMessage); // Equivalent to contains(map, key)
        return map._entries[uintKey];
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol

pragma solidity ^0.6.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// File: contracts/OZ_Clone/ERC721_simplemaps.sol

pragma solidity ^0.6.0;

// Clone of OpenZeppelin 3.0.0 token/ERC721/ERC721.sol with just imports adapted and EnumerableMap exchanged for EnumerableMapSimple.












/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMapSimple for EnumerableMapSimple.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMapSimple.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the URI for a given token ID. May return an empty string.
     *
     * If a base URI is set (via {_setBaseURI}), it is added as a prefix to the
     * token's own URI (via {_setTokenURI}).
     *
     * If there is a base URI but no token URI, the token's ID will be used as
     * its URI when appending it to the base URI. This pattern for autogenerated
     * token URIs can lead to large gas savings.
     *
     * .Examples
     * |===
     * |`_setBaseURI()` |`_setTokenURI()` |`tokenURI()`
     * | ""
     * | ""
     * | ""
     * | ""
     * | "token.uri/123"
     * | "token.uri/123"
     * | "token.uri/"
     * | "123"
     * | "token.uri/123"
     * | "token.uri/"
     * | ""
     * | "token.uri/<tokenId>"
     * |===
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner.
     * @param owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * Reverts if the index is greater or equal to the total number of tokens.
     * @param index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param operator operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether the specified token exists.
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     *
     * Reverts if the token ID does not exist.
     *
     * TIP: If all token IDs share a prefix (for example, if your URIs look like
     * `https://api.myproject.com/token/<id>`), use {_setBaseURI} to store
     * it and save gas.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ));
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _ERC721_RECEIVED);
        }
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - when `from` is zero, `tokenId` will be minted for `to`.
     * - when `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// File: contracts/ERC721SimpleMapsURI.sol

pragma solidity ^0.6.0;


/**
 * @title ERC721 With a nicer simple token URI
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721SimpleMapsURI is ERC721 {

    // Similar to ERC1155 URI() event, but without a token ID.
    event BaseURI(string value);

    constructor (string memory name, string memory symbol, string memory baseURI)
    ERC721(name, symbol)
    public
    {
        _setBaseURI(baseURI);
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI}.
     */
    function _setBaseURI(string memory baseURI_) internal override virtual {
        super._setBaseURI(baseURI_);
        emit BaseURI(baseURI());
    }

}

// File: contracts/ENSReverseRegistrarI.sol

/*
 * Interfaces for ENS Reverse Registrar
 * See https://github.com/ensdomains/ens/blob/master/contracts/ReverseRegistrar.sol for full impl
 * Also see https://github.com/wealdtech/wealdtech-solidity/blob/master/contracts/ens/ENSReverseRegister.sol
 *
 * Use this as follows (registryAddress is the address of the ENS registry to use):
 * -----
 * // This hex value is caclulated by namehash('addr.reverse')
 * bytes32 public constant ENS_ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;
 * function registerReverseENS(address registryAddress, string memory calldata) external {
 *     require(registryAddress != address(0), "need a valid registry");
 *     address reverseRegistrarAddress = ENSRegistryOwnerI(registryAddress).owner(ENS_ADDR_REVERSE_NODE)
 *     require(reverseRegistrarAddress != address(0), "need a valid reverse registrar");
 *     ENSReverseRegistrarI(reverseRegistrarAddress).setName(name);
 * }
 * -----
 * or
 * -----
 * function registerReverseENS(address reverseRegistrarAddress, string memory calldata) external {
 *    require(reverseRegistrarAddress != address(0), "need a valid reverse registrar");
 *     ENSReverseRegistrarI(reverseRegistrarAddress).setName(name);
 * }
 * -----
 * ENS deployments can be found at https://docs.ens.domains/ens-deployments
 * E.g. Etherscan can be used to look up that owner on those contracts.
 * namehash.hash("addr.reverse") == "0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2"
 * Ropsten: ens.owner(namehash.hash("addr.reverse")) == "0x6F628b68b30Dc3c17f345c9dbBb1E483c2b7aE5c"
 * Mainnet: ens.owner(namehash.hash("addr.reverse")) == "0x084b1c3C81545d370f3634392De611CaaBFf8148"
 */
pragma solidity ^0.6.0;

interface ENSRegistryOwnerI {
    function owner(bytes32 node) external view returns (address);
}

interface ENSReverseRegistrarI {
    function setName(string calldata name) external returns (bytes32 node);
}

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

// File: contracts/CollectionNotificationI.sol

/*
Interface for Collection notification contracts.
*/
pragma solidity ^0.6.0;


interface CollectionNotificationI is IERC165 {
    /*
     *     Calculate the interface ID for ERC 165:
     *
     *     bytes4(keccak256('onContractAdded(bool)')) == 0xdaf96bfb
     *     bytes4(keccak256('onContractRemoved()')) == 0x4664c35c
     *     bytes4(keccak256('onAssetAdded(address,uint256,uint8)')) == 0x60dec1cc
     *     bytes4(keccak256('onAssetRemoved(address,uint256,uint8)')) == 0xb5ed6ea2
     *
     *     => 0xdaf96bfb ^ 0x4664c35c ^ 0x60dec1cc ^ 0xb5ed6ea2 == 0x49ae07c9
     */

    enum TokenType {
        ERC721,
        ERC1155
    }

    /**
     * @notice Notify about being added as a notification contract on the Collection
     * @dev The Collection smart contract calls this function when adding this contract
     * as a notification contract. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onContractAdded.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the Collection contract address is always the message sender.
     * @param initial This is being called in the initial constructor of the Collection
     * @return bytes4 `bytes4(keccak256("onContractAdded(bool)"))`
     */
    function onContractAdded(bool initial)
    external returns (bytes4);

    /**
     * @notice Notify about being removed as a notification contract on the Collection
     * @dev The Collection smart contract calls this function when removing this contract
     * as a notification contract. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onContractRemoved.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the Collection contract address is always the message sender.
     * @return bytes4 `bytes4(keccak256("onContractRemoved()"))`
     */
    function onContractRemoved()
    external returns (bytes4);

    /**
     * @notice Notify about adding an asset to the Collection
     * @dev The Collection smart contract calls this function when adding any asset to
     * its internal tracking of assets. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onAssetAdded.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the Collection contract address is always the message sender.
     * @param tokenAddress The address of the token contract
     * @param tokenId The token identifier which is being transferred
     * @param tokenType The type of token this asset represents (can be ERC721 or ERC1155)
     * @return bytes4 `bytes4(keccak256("onAssetAdded(address,uint256,uint8)"))`
     */
    function onAssetAdded(address tokenAddress, uint256 tokenId, TokenType tokenType)
    external returns (bytes4);

    /**
     * @notice Notify about removing an asset from the Collection
     * @dev The Collection smart contract calls this function when removing any asset from
     * its internal tracking of assets. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onAssetAdded.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the Collection contract address is always the message sender.
     * @param tokenAddress The address of the token contract
     * @param tokenId The token identifier which is being transferred
     * @param tokenType The type of token this asset represents (can be ERC721 or ERC1155)
     * @return bytes4 `bytes4(keccak256("onAssetRemoved(address,uint256,uint8)"))`
     */
    function onAssetRemoved(address tokenAddress, uint256 tokenId, TokenType tokenType)
    external returns (bytes4);
}

// File: contracts/CS2PropertiesI.sol

/*
Interface for CS2 properties.
*/
pragma solidity ^0.6.0;

interface CS2PropertiesI {

    enum AssetType {
        Honeybadger,
        Llama,
        Panda,
        Doge
    }

    enum Colors {
        Black,
        Green,
        Blue,
        Yellow,
        Red
    }

    function getType(uint256 tokenId) external view returns (AssetType);
    function getColor(uint256 tokenId) external view returns (Colors);

}

// File: contracts/AchievementsUpgradingI.sol

/*
Interface for CS2 color upgrading support by achievements.
*/
pragma solidity ^0.6.0;



interface AchievementsUpgradingI is IERC165 {
    /*
     *     Calculate the interface ID for ERC 165:
     *
     *     bytes4(keccak256('onContractAdded(bool)')) == 0x58cac597
     */

    /**
     * @notice Notify about changing a CS2 color as done by the "upgrading" mechanism
     * @dev The Cryptostamp2 smart contract calls this function when changing the color of any asset,
     * esp. as the result of upgrading. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onCS2ColorChanged.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the Collection contract address is always the message sender.
     * @param tokenId The token identifier which is being changed
     * @param previousColor The previous color held by the token
     * @param newColor The new color assigned to the token, which MUST match the current color at time of this call
     * @return bytes4 `bytes4(keccak256("onCS2ColorChanged(uint256,uint8,uint8)"))`
     */
    function onCS2ColorChanged(uint256 tokenId, CS2PropertiesI.Colors previousColor, CS2PropertiesI.Colors newColor)
    external returns (bytes4);

}

// File: contracts/CS1ColorsI.sol

/*
Color store interface for Crypto stamp 1
*/
pragma solidity ^0.6.0;

interface CS1ColorsI {

    enum Colors {
        Black,
        Green,
        Blue,
        Yellow,
        Red
    }

    // Returns the color of a given token ID
    function getColor(uint256 tokenId) external view returns (Colors);

}

// File: contracts/ERC721ExistsI.sol

pragma solidity ^0.6.0;


/**
 * @dev ERC721 compliant contract with an exists() function.
 */
abstract contract ERC721ExistsI is IERC721 {

    // Returns whether the specified token exists
    function exists(uint256 tokenId) public view virtual returns (bool);

}

// File: contracts/CollectionOwnedI.sol

pragma solidity ^0.6.0;

/**
 * @dev interface for collection exposing a function for a count of owned assets.
 */
abstract contract CollectionOwnedI {

    // Returns number of owned assets.
    function ownedAssetsCount() public view virtual returns (uint256);

}

// File: contracts/Achievements.sol

/*
Implements Collections of ERC 721 tokens, exposed as yet another ERC721 token.
*/
pragma solidity ^0.6.0;












contract Achievements is ERC165, ERC721SimpleMapsURI, CollectionNotificationI, AchievementsUpgradingI {
    using SafeMath for uint256;

    enum AchievementCategory {
        TOTAL,
        COLOR,
        ALLANIMALS,
        ALLCOLORS,
        ALL
    }

    bytes4 private constant _INTERFACE_ID_COLLECTION_NOTIFICATION = 0x49ae07c9;
    bytes4 private constant _INTERFACE_ID_ACHIEVEMENTS_UPGRADING = 0x58cac597;

    address public CS1Address;
    address public CS1ColorsAddress;
    address public CS2Address;
    address public collectionsAddress;
    address public tokenAssignmentControl;

    uint8 public constant totalTypes = 5;
    uint8 public constant totalColors = 5;
    uint public constant confirmationTime = 2 days;
    uint8[5] public colorWeight; // quasi-constant, as array constants are not supported, set in constructor.

    // For every collection, for every token type, for every color, a count.
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public assetCount;
    // For every collection, for every token type, a count.
    mapping(address => mapping(uint256 => uint256)) public assetTypeCount;
    // For every collection, a total count.
    mapping(address => uint256) public assetTotalCount;
    // For every collection, see if achievement of specified code was awarded (pointing to token ID, so you need to reverse-try, esp. for ID 0)
    mapping(address => mapping(uint256 => uint256)) public awardedTokenId;
    // For every collection, note if it has been completely revoked.
    mapping(address => bool) public allAchievementsRevoked;

    // Token properties (for every token ID)
    mapping(uint256 => uint256) public achievementCode;
    mapping(uint256 => uint) public creationTime;

    event AchievementAwarded(address indexed owner, uint256 achievementCode, uint256 tokenId);
    event AchievementRevoked(address indexed owner, uint256 achievementCode, uint256 tokenId);
    event AllAchievementsRevoked(address indexed owner);
    event TokenAssignmentControlTransferred(address indexed previousTokenAssignmentControl, address indexed newTokenAssignmentControl);

    constructor(address _CS1Address, address _CS1ColorsAddress, address _CS2Address, address _collectionsAddress, address _tokenAssignmentControl)
    ERC721SimpleMapsURI("Crypto stamp 2 Achievements", "CS2A", "https://test.crypto.post.at/CS2A/meta/")
    public
    {
        _registerInterface(_INTERFACE_ID_COLLECTION_NOTIFICATION);
        _registerInterface(_INTERFACE_ID_ACHIEVEMENTS_UPGRADING);
        CS1Address = _CS1Address;
        CS1ColorsAddress = _CS1ColorsAddress;
        CS2Address = _CS2Address;
        collectionsAddress = _collectionsAddress;
        tokenAssignmentControl = _tokenAssignmentControl;
        // Set quasi-constant array values: point weights for colors.
        colorWeight = [1, 2, 4, 8, 20];
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == tokenAssignmentControl, "tokenAssignmentControl key required for this function.");
        _;
    }

    /*** Enable adjusting variables after deployment ***/

    function transferTokenAssignmentControl(address _newTokenAssignmentControl)
    public
    onlyTokenAssignmentControl
    {
        require(_newTokenAssignmentControl != address(0), "tokenAssignmentControl cannot be the zero address.");
        emit TokenAssignmentControlTransferred(tokenAssignmentControl, _newTokenAssignmentControl);
        tokenAssignmentControl = _newTokenAssignmentControl;
    }

    // Set new base for the token URI.
    function setBaseURI(string memory _newBaseURI)
    public
    onlyTokenAssignmentControl
    {
        super._setBaseURI(_newBaseURI);
    }

    /*** Handle assets being added and removed on a collection ***/

    // This is being called when a collection adds this one as a notification contract.
    function onContractAdded(bool _initial)
    external override
    returns (bytes4) {
        // Just make sure that this is a valid collection and is empty.
        ERC721ExistsI collections = ERC721ExistsI(collectionsAddress);
        require(collections.exists(uint256(msg.sender)), "Sender needs to be a valid Collection.");
        if (!_initial) {
            // When called from the constructor, we cannot call the contract back, but we know it's empty.
            // When called later, we need to verify that it's empty.
            require(CollectionOwnedI(msg.sender).ownedAssetsCount() == 0, "Collection needs to be empty.");
        }
        return this.onContractAdded.selector;
    }

    // Called when this contract is removed as a notification contract from a collection.
    function onContractRemoved()
    external override
    returns (bytes4) {
        // Revoke all achievements.
        for (uint i = 1; i <= totalTypes; i++) { // 1-based, so use <=
            for (uint j = 0; j < totalColors; j++) {
                assetCount[msg.sender][i][j] = 0;
            }
            assetTypeCount[msg.sender][i] = 0;
        }
        assetTotalCount[msg.sender] = 0;
        allAchievementsRevoked[msg.sender] = true;
        emit AllAchievementsRevoked(msg.sender);
        return this.onContractRemoved.selector;
    }

    // This function is called when an asset is added to a collection's tracked list, either by transfer or by "sync".
    function onAssetAdded(address _tokenAddress, uint256 _tokenId, CollectionNotificationI.TokenType _tokenType)
    external override
    returns (bytes4)
    {
        if (_tokenType == CollectionNotificationI.TokenType.ERC721) {
            // We only look at ERC721 tokens for achievements.
            require(IERC721(_tokenAddress).ownerOf(_tokenId) == msg.sender, "NFT needs to be owned by the caller of this function.");
            uint256 typeNum = getTypeNum(_tokenAddress, _tokenId);
            if (typeNum > 0) {
                // We have a tracked asset.
                ERC721ExistsI collections = ERC721ExistsI(collectionsAddress);
                require(collections.exists(uint256(msg.sender)), "Sender needs to be a valid Collection.");
                uint256 colorNum = getColorNum(_tokenAddress, _tokenId);
                assetCount[msg.sender][typeNum][colorNum] = assetCount[msg.sender][typeNum][colorNum].add(1);
                assetTypeCount[msg.sender][typeNum] = assetTypeCount[msg.sender][typeNum].add(1);
                assetTotalCount[msg.sender] = assetTotalCount[msg.sender].add(1);
                // We maybe need to award new or reactivate existing achievements here.
                _checkAndAwardAchievements(msg.sender, typeNum, colorNum);
            }
        }
        return this.onAssetAdded.selector;
    }

    // This function is called when an asset is removed from a collection's tracked list, either by transfer or by "sync".
    function onAssetRemoved(address _tokenAddress, uint256 _tokenId, CollectionNotificationI.TokenType _tokenType)
    external override
    returns (bytes4)
    {
        if (_tokenType == CollectionNotificationI.TokenType.ERC721) {
            // We only care about ERC721 tokens.
            require(IERC721(_tokenAddress).ownerOf(_tokenId) != msg.sender, "NFT needs not to be owned by the caller of this function.");
            uint256 typeNum = getTypeNum(_tokenAddress, _tokenId);
            if (typeNum > 0) {
                // We have a tracked asset.
                uint256 colorNum = getColorNum(_tokenAddress, _tokenId);
                assetCount[msg.sender][typeNum][colorNum] = assetCount[msg.sender][typeNum][colorNum].sub(1);
                assetTypeCount[msg.sender][typeNum] = assetTypeCount[msg.sender][typeNum].sub(1);
                assetTotalCount[msg.sender] = assetTotalCount[msg.sender].sub(1);
                // We maybe need to disable achievements here.
                _checkAndRevokeAchievements(msg.sender, typeNum, colorNum);
            }
        }
        return this.onAssetRemoved.selector;
    }

    // This function is called when an asset changes its color (see CS2 "upgrading"). Needs to be called by the CS2 contract.
    function onCS2ColorChanged(uint256 _tokenId, CS2PropertiesI.Colors _previousColor, CS2PropertiesI.Colors _newColor)
    external override
    returns (bytes4)
    {
        require(msg.sender == CS2Address, "Needs to be called by CS2 contract.");
        address owner = IERC721(CS2Address).ownerOf(_tokenId);
        uint256 typeNum = getTypeNum(CS2Address, _tokenId);
        uint256 prevColorNum = uint256(_previousColor);
        uint256 newColorNum = uint256(_newColor);

        // Remove this token from previous color count.
        assetCount[owner][typeNum][prevColorNum] = assetCount[owner][typeNum][prevColorNum].sub(1);
        // We maybe need to disable achievements here.
        _checkAndRevokeAchievements(owner, typeNum, prevColorNum);

        // Add this token to new color count.
        assetCount[owner][typeNum][newColorNum] = assetCount[owner][typeNum][newColorNum].add(1);
        // We maybe need to award new or reactivate existing achievements here.
        _checkAndAwardAchievements(owner, typeNum, newColorNum);

        return this.onCS2ColorChanged.selector;
    }

    // Check if any achievements need to be awarded and if that's the case, make it so.
    function _checkAndAwardAchievements(address _collAddr, uint256 _typeNum, uint256 _colorNum)
    internal
    {
        // Determine how many stamps of this color the collection owns.
        uint256 thisColorCount = 0;
        for (uint i = 1; i <= totalTypes; i++) { // 1-based, so use <=
            thisColorCount = thisColorCount.add(assetCount[_collAddr][i][_colorNum]);
        }
        // Check if we need to award new achievements.
        if (assetCount[_collAddr][_typeNum][_colorNum] == 1) {
            // Check for achievements that can be awarded when getting the first stamp of a sort.
            uint256 aCode = getAchievementCode(AchievementCategory.ALLCOLORS, _typeNum, 0, 1);
            if (!hasAchievement(_collAddr, aCode)) {
                bool hasAllColors = true;
                for (uint i = 0; i < totalColors; i++) {
                    if (assetCount[_collAddr][_typeNum][i] < 1) {
                        hasAllColors = false;
                    }
                }
                if (hasAllColors) {
                    _createAchievement(_collAddr, aCode); // ALLCOLORS-{type}

                    // If we get the last of the ALLCOLORS, we may get the overall ALL achievement as well!
                    aCode = getAchievementCode(AchievementCategory.ALL, 0, 0, 1);
                    if (!hasAchievement(_collAddr, aCode)) {
                        bool hasAllTypes = true;
                        for (uint i = 1; i <= totalTypes; i++) { // 1-based, so use <=
                            uint256 aTestCode = getAchievementCode(AchievementCategory.ALLCOLORS, i, 0, 1);
                            if (!hasAchievement(_collAddr, aTestCode)) {
                                hasAllTypes = false;
                            }
                        }
                        if (hasAllTypes) {
                            _createAchievement(_collAddr, aCode); // ALL
                        }
                    }
                }
            }
        }
        if (thisColorCount == 5 ||
            thisColorCount == 10 ||
            (thisColorCount == 50 && _colorNum == uint256(CS2PropertiesI.Colors.Blue))) {
            // Check for achievements that can be awarded when getting to 5, 10, or 50 stamps of that color.
            uint256 aCode = getAchievementCode(AchievementCategory.COLOR, 0, _colorNum, thisColorCount);
            if (!hasAchievement(_collAddr, aCode)) {
                _createAchievement(_collAddr, aCode); // COLOR-{color}-{5,10,50}
            }
        }
        if (assetTypeCount[_collAddr][_typeNum] == 1 ||
            assetTypeCount[_collAddr][_typeNum] == 5 ||
            assetTypeCount[_collAddr][_typeNum] == 10) {
            // Check for achievements that can be awarded when getting to 1,5, or 10 stamps of every type.
            uint256 aCode = getAchievementCode(AchievementCategory.ALLANIMALS, 0, 0, assetTypeCount[_collAddr][_typeNum]);
            if (!hasAchievement(_collAddr, aCode)) {
                bool hasAllTypes = true;
                for (uint i = 1; i <= totalTypes; i++) { // 1-based, so use <=
                    if (assetTypeCount[_collAddr][i] < assetTypeCount[_collAddr][_typeNum]) {
                        hasAllTypes = false;
                    }
                }
                if (hasAllTypes) {
                    _createAchievement(_collAddr, aCode); // ALLANIMALS-{1,5,10}
                }
            }
        }
        if (assetTotalCount[_collAddr] == 1 ||
            assetTotalCount[_collAddr] == 5 ||
            assetTotalCount[_collAddr] == 10) {
            // Check for achievements that can be awarded when getting to 1, 5, or 10 total stamps.
            uint256 aCode = getAchievementCode(AchievementCategory.TOTAL, 0, 0, assetTotalCount[_collAddr]);
            if (!hasAchievement(_collAddr, aCode)) {
                _createAchievement(_collAddr, aCode); // TOTAL-{1,5,10}
            }
        }
    }

    // Check if any achievements need to be revoked and if that's the case, make it so.
    function _checkAndRevokeAchievements(address _collAddr, uint256 _typeNum, uint256 _colorNum)
    internal
    {
        // Determine how many stamps of this color the collection owns.
        uint256 thisColorCount = 0;
        for (uint i = 1; i <= totalTypes; i++) { // 1-based, so use <=
            thisColorCount = thisColorCount.add(assetCount[_collAddr][i][_colorNum]);
        }
        // Check if we need to un-award any achievements.
        if (assetCount[_collAddr][_typeNum][_colorNum] == 0) {
            // Check for achievements that need to be revoked due to removing the last stamp of a sort.
            // We definitely have lost at least one color for this type: ALLCOLORS-{type}
            _disableAchievementIfApplicable(_collAddr, getAchievementCode(AchievementCategory.ALLCOLORS, _typeNum, 0, 1));
            // As we have lost one color/type combination, revoke this as well: ALL
            _disableAchievementIfApplicable(_collAddr, getAchievementCode(AchievementCategory.ALL, 0, 0, 1));
        }
        if (thisColorCount == 4 ||
            thisColorCount == 9 ||
            (thisColorCount == 49 && _colorNum == uint256(CS2PropertiesI.Colors.Blue))) {
            // Check for achievements that were awarded when getting to 5, 10, or 50 stamps of that color: COLOR-{color}-{5,10,50}
            _disableAchievementIfApplicable(_collAddr,
                getAchievementCode(AchievementCategory.COLOR, 0, _colorNum, thisColorCount.add(1)));
        }
        if (assetTypeCount[_collAddr][_typeNum] == 0 ||
            assetTypeCount[_collAddr][_typeNum] == 4 ||
            assetTypeCount[_collAddr][_typeNum] == 9) {
            // Check for achievements that were awarded when getting to 1,5, or 10 stamps of every type: ALLANIMALS-{1,5,10}
            _disableAchievementIfApplicable(_collAddr,
                getAchievementCode(AchievementCategory.ALLANIMALS, 0, 0, assetTypeCount[_collAddr][_typeNum].add(1)));
        }
        if (assetTotalCount[_collAddr] == 0 ||
            assetTotalCount[_collAddr] == 4 ||
            assetTotalCount[_collAddr] == 9) {
            // Check for achievements that were awarded when getting to 1, 5, or 10 total stamps: TOTAL-{1,5,10}
            _disableAchievementIfApplicable(_collAddr,
                getAchievementCode(AchievementCategory.TOTAL, 0, 0, assetTotalCount[_collAddr].add(1)));
        }
    }

    // Create new achievement or reactivate existing one, as needed.
    function _createAchievement(address _newOwner, uint256 _achievementCode)
    internal
    {
        uint256 potentialTokenId = awardedTokenId[_newOwner][_achievementCode];
        if (_exists(potentialTokenId) &&
            achievementCode[potentialTokenId] == _achievementCode &&
            ownerOf(potentialTokenId) == _newOwner) {
            // Achievement token already exists, reactivate it.
            creationTime[potentialTokenId] = now;
            emit AchievementAwarded(_newOwner, _achievementCode, potentialTokenId);
        }
        else {
            // Create new achievement token, current totalSupply() is the new token ID.
            // _safeMint() checks if the recipient can actually receive ERC721 tokens.
            uint256 newTokenId = totalSupply();
            _safeMint(_newOwner, newTokenId);
            achievementCode[newTokenId] = _achievementCode;
            creationTime[newTokenId] = now;
            awardedTokenId[_newOwner][_achievementCode] = newTokenId;
            emit AchievementAwarded(_newOwner, _achievementCode, newTokenId);
        }
    }

    // Deactivate achievement, if the owner actually owns it and it is not confimed.
    function _disableAchievementIfApplicable(address _owner, uint256 _achievementCode)
    internal
    {
        uint256 potentialTokenId = awardedTokenId[_owner][_achievementCode];
        if (hasAchievement(_owner, _achievementCode) && !isConfirmed(potentialTokenId)) {
            creationTime[potentialTokenId] = 0;
            emit AchievementRevoked(_owner, _achievementCode, potentialTokenId);
        }
    }

    //*** Getters for token properties that are not explicit public variables ***

    // Returns whether the specified token exists.
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    // Returns whether the specified achievement has been confirmed.
    // This is the case if creationTime is not 0 but is older than confirmationTime.
    function isConfirmed(uint256 _tokenId) public view returns (bool) {
        // Compare creationTime to now before subtraction to avoid underflow.
        return (creationTime[_tokenId] > 0 && creationTime[_tokenId] < now &&
                (now - creationTime[_tokenId]) > confirmationTime);
    }

    // Returns whether the specified achievement is actually active.
    // This is the case if creationTime is not 0 but equals now or is in the past,
    // AND if either allAchievementsRevoked is false or it's a confirmed achievement.
    function isActive(uint256 _tokenId) public view returns (bool) {
        return (creationTime[_tokenId] > 0 && creationTime[_tokenId] <= now &&
                (allAchievementsRevoked[ownerOf(_tokenId)] == false ||
                 (now - creationTime[_tokenId]) > confirmationTime));
    }

    // Returns the points for the specified achievement.
    function getPoints(uint256 _tokenId) public view returns (uint256) {
        return getPointsByCode(achievementCode[_tokenId]);
    }

    //*** Functions (pure or view) around handling achievement code and points ***

    // Encode achievement code from details.
    function getAchievementCode(AchievementCategory _category, uint256 _typeNum, uint256 _colorNum, uint256 _count)
    internal pure
    returns (uint256)
    {
        return uint256(_category).mul(2 ** 30).add(_typeNum.mul(2 ** 20)).add(_colorNum.mul(2 ** 10)).add(_count);
    }

    // Decode details from achievement code.
    function getDetailsFromCode(uint256 _achievementCode)
    public pure
    returns (AchievementCategory, uint256, uint256, uint256)
    {
        uint256 count = _achievementCode % (2 ** 10);
        uint256 colorNum = (_achievementCode >> 10) % (2 ** 10);
        uint256 typeNum = (_achievementCode >> 20) % (2 ** 10);
        AchievementCategory category = AchievementCategory((_achievementCode >> 30));
        return (category, typeNum, colorNum, count);
    }

    // Determine if a collection actually has a given achievement and it is active.
    function hasAchievement(address _owner, uint256 _achievementCode)
    public view
    returns (bool)
    {
        uint256 potentialTokenId = awardedTokenId[_owner][_achievementCode];
        return (_exists(potentialTokenId) &&
                achievementCode[potentialTokenId] == _achievementCode &&
                ownerOf(potentialTokenId) == _owner &&
                creationTime[potentialTokenId] > 0);
    }

    // Get type number for a given token address and ID.
    // - For non-supported tokens, returns 0.
    // - For CS1 (Unicorn), returns 1.
    // - For CS2, returns 2 for Honeybadger, 3 for Llama, 4 for Panda, 5 for Doge.
    function getTypeNum(address _tokenAddress, uint256 _tokenId)
    public view
    returns (uint256)
    {
        if (_tokenAddress == CS1Address) {
            ERC721ExistsI CS1 = ERC721ExistsI(CS1Address);
            require(CS1.exists(_tokenId), "Token ID needs to exist.");
            return 1;
        }
        else if (_tokenAddress == CS2Address) {
            CS2PropertiesI CS2 = CS2PropertiesI(CS2Address);
            return 2 + uint256(CS2.getType(_tokenId));
        }
        return 0;
    }

    // Get color number for a given token address and ID.
    // returns 0 for black, 1 for green, 2 for blue, 3 for yellow, 4 for red.
    function getColorNum(address _tokenAddress, uint256 _tokenId)
    public view
    returns (uint256)
    {
        if (_tokenAddress == CS1Address) {
            CS1ColorsI CS1 = CS1ColorsI(CS1ColorsAddress);
            return uint256(CS1.getColor(_tokenId));
        }
        else if (_tokenAddress == CS2Address) {
            CS2PropertiesI CS2 = CS2PropertiesI(CS2Address);
            return uint256(CS2.getColor(_tokenId));
        }
        return 0;
    }

    // Get points for a given achievement code.
    function getPointsByCode(uint256 _achievementCode)
    public view
    returns (uint256)
    {
        (AchievementCategory category, uint256 typeNum, uint256 colorNum, uint256 count) = getDetailsFromCode(_achievementCode);
        return getPointsByDetails(category, typeNum, colorNum, count);
    }

    // Get points for a given set of details.
    function getPointsByDetails(AchievementCategory _category, uint256 _typeNum, uint256 _colorNum, uint256 _count)
    public view
    returns (uint256)
    {
        if (_category == AchievementCategory.TOTAL) {
            return _count;
        }
        else if (_category == AchievementCategory.COLOR) {
            return _count * colorWeight[_colorNum];
        }
        else if (_category == AchievementCategory.ALLANIMALS) {
            return _count * 5;
        }
        else if (_category == AchievementCategory.ALLCOLORS) {
            if (_typeNum == 1) {
                return 222;
            }
            else {
                return 200;
            }
        }
        else if (_category == AchievementCategory.ALL) {
            return 1000;
        }
        // This should be unreachable if we handle all possible categories above.
        return 0;
    }

    /*** Block transfers and approvals ***/

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        virtual
        override
        internal
    {
        if (from != address(0) && to != address(0)) {
            revert("Transfer of achievements is not possible.");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function approve(address /*to*/, uint256 /*tokenId*/) public virtual override {
        revert("Transfer of achievements is not possible, so approvals are blocked.");
    }

    function setApprovalForAll(address /*operator*/, bool /*approved*/) public virtual override {
        revert("Transfer of achievements is not possible, so approvals are blocked.");
    }

    /*** Enable reverse ENS registration ***/

    // Call this with the address of the reverse registrar for the respecitve network and the ENS name to register.
    // The reverse registrar can be found as the owner of 'addr.reverse' in the ENS system.
    // See https://docs.ens.domains/ens-deployments for address of ENS deployments, e.g. Etherscan can be used to look up that owner on those.
    // namehash.hash("addr.reverse") == "0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2"
    // Ropsten: ens.owner(namehash.hash("addr.reverse")) == "0x6F628b68b30Dc3c17f345c9dbBb1E483c2b7aE5c"
    // Mainnet: ens.owner(namehash.hash("addr.reverse")) == "0x084b1c3C81545d370f3634392De611CaaBFf8148"
    function registerReverseENS(address _reverseRegistrarAddress, string calldata _name)
    external
    onlyTokenAssignmentControl
    {
       require(_reverseRegistrarAddress != address(0), "need a valid reverse registrar");
       ENSReverseRegistrarI(_reverseRegistrarAddress).setName(_name);
    }

    /*** Make sure currency doesn't get stranded in this contract ***/

    // If this contract gets a balance in some ERC20 contract after it's finished, then we can rescue it.
    function rescueToken(IERC20 _foreignToken, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignToken.transfer(_to, _foreignToken.balanceOf(address(this)));
    }

    // If this contract gets a balance in some ERC721 contract after it's finished, then we can rescue it.
    function approveNFTrescue(IERC721 _foreignNFT, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignNFT.setApprovalForAll(_to, true);
    }

    // Make sure this contract cannot receive ETH.
    receive()
    external payable
    {
        revert("The contract cannot receive ETH payments.");
    }
}