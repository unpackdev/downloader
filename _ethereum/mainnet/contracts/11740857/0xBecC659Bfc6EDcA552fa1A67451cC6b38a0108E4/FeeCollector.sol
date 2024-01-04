// File: @openzeppelin/contracts/utils/EnumerableSet.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
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

// File: @openzeppelin/contracts/utils/Address.sol

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

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/access/AccessControl.sol

pragma solidity >=0.6.0 <0.8.0;




/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity >=0.6.0 <0.8.0;




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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

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

// File: contracts/interfaces/IFeeCollector.sol

pragma solidity >=0.6.0 <=0.7.5;

interface IFeeCollector {
  function deposit(bool[] calldata _depositTokensEnabled, uint256[] calldata _minTokenOut, uint256 _minPoolAmountOut) external; // called by whitelisted address
  function setSplitAllocation(uint256[] calldata _allocations) external; // allocation of fees sent SmartTreasury vs FeeTreasury
  // function setFeeTreasuryAddress(address _feeTreasuryAddress) external; // called by admin

  function addBeneficiaryAddress(address _newBeneficiary, uint256[] calldata _newAllocation) external;
  function removeBeneficiaryAt(uint256 _index, uint256[] calldata _newAllocation) external;
  function replaceBeneficiaryAt(uint256 _index, address _newBeneficiary, uint256[] calldata _newAllocation) external;
  function setSmartTreasuryAddress(address _smartTreasuryAddress) external; // If for any reason the pool needs to be migrated, call this function. Called by admin

  function addAddressToWhiteList(address _addressToAdd) external; // Whitelist address. Called by admin
  function removeAddressFromWhiteList(address _addressToRemove) external; // Remove from whitelist. Called by admin

  function registerTokenToDepositList(address _tokenAddress) external; // Register a token which can converted to ETH and deposited to smart treasury. Called by admin
  function removeTokenFromDepositList(address _tokenAddress) external; // Unregister a token. Called by admin

   // withdraw arbitrary token to address. Called by admin
  function withdraw(address _token, address _toAddress, uint256 _amount) external;
  // exchange liquidity token for underlying token and withdraw to _toAddress
  function withdrawUnderlying(address _toAddress, uint256 _amount, uint256[] calldata minTokenOut) external;

  function replaceAdmin(address _newAdmin) external; // called by admin
}

// File: contracts/interfaces/BalancerInterface.sol

pragma solidity = 0.6.8;
pragma experimental ABIEncoderV2;

interface BPool {
  event LOG_SWAP(
    address indexed caller,
    address indexed tokenIn,
    address indexed tokenOut,
    uint256         tokenAmountIn,
    uint256         tokenAmountOut
  );

  event LOG_JOIN(
    address indexed caller,
    address indexed tokenIn,
    uint256         tokenAmountIn
  );

  event LOG_EXIT(
    address indexed caller,
    address indexed tokenOut,
    uint256         tokenAmountOut
  );

  event LOG_CALL(
    bytes4  indexed sig,
    address indexed caller,
    bytes           data
  ) anonymous;

  function isPublicSwap() external view returns (bool);
  function isFinalized() external view returns (bool);
  function isBound(address t) external view returns (bool);
  function getNumTokens() external view returns (uint);
  function getCurrentTokens() external view returns (address[] memory tokens);
  function getFinalTokens() external view returns (address[] memory tokens);
  function getDenormalizedWeight(address token) external view returns (uint);
  function getTotalDenormalizedWeight() external view returns (uint);
  function getNormalizedWeight(address token) external view returns (uint);
  function getBalance(address token) external view returns (uint);
  function getSwapFee() external view returns (uint);
  function getController() external view returns (address);

  function setSwapFee(uint swapFee) external;
  function setController(address manager) external;
  function setPublicSwap(bool public_) external;
  function finalize() external;
  function bind(address token, uint balance, uint denorm) external;
  function unbind(address token) external;
  function gulp(address token) external;

  function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint spotPrice);
  function getSpotPriceSansFee(address tokenIn, address tokenOut) external view returns (uint spotPrice);

  function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;   
  function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external;

  function swapExactAmountIn(
    address tokenIn,
    uint tokenAmountIn,
    address tokenOut,
    uint minAmountOut,
    uint maxPrice
  ) external returns (uint tokenAmountOut, uint spotPriceAfter);

  function swapExactAmountOut(
    address tokenIn,
    uint maxAmountIn,
    address tokenOut,
    uint tokenAmountOut,
    uint maxPrice
  ) external returns (uint tokenAmountIn, uint spotPriceAfter);

  function joinswapExternAmountIn(
    address tokenIn,
    uint tokenAmountIn,
    uint minPoolAmountOut
  ) external returns (uint poolAmountOut);

  function joinswapPoolAmountOut(
    address tokenIn,
    uint poolAmountOut,
    uint maxAmountIn
  ) external returns (uint tokenAmountIn);

  function exitswapPoolAmountIn(
    address tokenOut,
    uint poolAmountIn,
    uint minAmountOut
  ) external returns (uint tokenAmountOut);

  function exitswapExternAmountOut(
    address tokenOut,
    uint tokenAmountOut,
    uint maxPoolAmountIn
  ) external returns (uint poolAmountIn);

  function totalSupply() external view returns (uint);
  function balanceOf(address whom) external view returns (uint);
  function allowance(address src, address dst) external view returns (uint);

  function approve(address dst, uint amt) external returns (bool);
  function transfer(address dst, uint amt) external returns (bool);
  function transferFrom(
    address src, address dst, uint amt
  ) external returns (bool);
}

interface ConfigurableRightsPool {
  event LogCall(
    bytes4  indexed sig,
    address indexed caller,
    bytes data
  ) anonymous;

  event LogJoin(
    address indexed caller,
    address indexed tokenIn,
    uint tokenAmountIn
  );

  event LogExit(
    address indexed caller,
    address indexed tokenOut,
    uint tokenAmountOut
  );

  event CapChanged(
    address indexed caller,
    uint oldCap,
    uint newCap
  );
    
  event NewTokenCommitted(
    address indexed token,
    address indexed pool,
    address indexed caller
  );

  function createPool(
    uint initialSupply
    // uint minimumWeightChangeBlockPeriodParam,
    // uint addTokenTimeLockInBlocksParam
  ) external;

  function createPool(
    uint initialSupply,
    uint minimumWeightChangeBlockPeriodParam,
    uint addTokenTimeLockInBlocksParam
  ) external;

  function updateWeightsGradually(
    uint[] calldata newWeights,
    uint startBlock,
    uint endBlock
  ) external;

  function joinswapExternAmountIn(
    address tokenIn,
    uint tokenAmountIn,
    uint minPoolAmountOut
  ) external;
  
  function whitelistLiquidityProvider(address provider) external;
  function removeWhitelistedLiquidityProvider(address provider) external;
  function canProvideLiquidity(address provider) external returns (bool);
  function getController() external view returns (address);
  function setController(address newOwner) external;

  function transfer(address recipient, uint amount) external returns (bool);
  function balanceOf(address account) external returns (uint);
  function totalSupply() external returns (uint);
  function bPool() external view returns (BPool);

  function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external;
}

interface IBFactory {
  event LOG_NEW_POOL(
    address indexed caller,
    address indexed pool
  );

  event LOG_BLABS(
    address indexed caller,
    address indexed blabs
  );

  function isBPool(address b) external view returns (bool);
  function newBPool() external returns (BPool);
}

interface ICRPFactory {
  event LogNewCrp(
    address indexed caller,
    address indexed pool
  );

  struct PoolParams {
    // Balancer Pool Token (representing shares of the pool)
    string poolTokenSymbol;
    string poolTokenName;
    // Tokens inside the Pool
    address[] constituentTokens;
    uint[] tokenBalances;
    uint[] tokenWeights;
    uint swapFee;
  }

  struct Rights {
    bool canPauseSwapping;
    bool canChangeSwapFee;
    bool canChangeWeights;
    bool canAddRemoveTokens;
    bool canWhitelistLPs;
    bool canChangeCap;
  }

  function newCrp(
    address factoryAddress,
    PoolParams calldata poolParams,
    Rights calldata rights
  ) external returns (ConfigurableRightsPool);
}

// File: contracts/FeeCollector.sol

pragma solidity = 0.6.8;









/**
@title Idle finance Fee collector
@author Asaf Silman
@notice Receives fees from idle strategy tokens and routes to fee treasury and smart treasury
 */
contract FeeCollector is IFeeCollector, AccessControl {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IUniswapV2Router02 private constant uniswapRouterV2 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  address private immutable weth;

  // Need to use openzeppelin enumerableset
  EnumerableSet.AddressSet private depositTokens;

  uint256[] private allocations; // 100000 = 100%. allocation sent to beneficiaries
  address[] private beneficiaries; // Who are the beneficiaries of the fees generated from IDLE. The first beneficiary is always going to be the smart treasury

  uint128 public constant MAX_BENEFICIARIES = 5;
  uint128 public constant MIN_BENEFICIARIES = 2;
  uint256 public constant FULL_ALLOC = 100000;

  uint256 public constant MAX_NUM_FEE_TOKENS = 15; // Cap max tokens to 15
  bytes32 public constant WHITELISTED = keccak256("WHITELISTED_ROLE");

  modifier smartTreasurySet {
    require(beneficiaries[0]!=address(0), "Smart Treasury not set");
    _;
  }

  modifier onlyAdmin {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Unauthorised");
    _;
  }

  modifier onlyWhitelisted {
    require(hasRole(WHITELISTED, msg.sender), "Unauthorised");
    _;
  }

  /**
  @author Asaf Silman
  @notice Initialise the FeeCollector contract.
  @dev Sets the smartTreasury, weth address, uniswap router, and fee split allocations.
  @dev Also initialises the sender as admin, and whitelists for calling `deposit()`
  @dev At deploy time the smart treasury will not have been deployed yet.
       setSmartTreasuryAddress should be called after the treasury has been deployed.
  @param _weth The wrapped ethereum address.
  @param _feeTreasuryAddress The address of idle's fee treasury.
  @param _idleRebalancer Idle rebalancer address
  @param _multisig The multisig account to transfer ownership to after contract initialised
  @param _initialDepositTokens The initial tokens to register with the fee deposit
   */
  constructor (
    address _weth,
    address _feeTreasuryAddress,
    address _idleRebalancer,
    address _multisig,
    address[] memory _initialDepositTokens
  ) public {
    require(_weth != address(0), "WETH cannot be the 0 address");
    require(_feeTreasuryAddress != address(0), "Fee Treasury cannot be 0 address");
    require(_idleRebalancer != address(0), "Rebalancer cannot be 0 address");
    require(_multisig != address(0), "Multisig cannot be 0 address");

    require(_initialDepositTokens.length <= MAX_NUM_FEE_TOKENS);
    
    _setupRole(DEFAULT_ADMIN_ROLE, _multisig); // setup multisig as admin
    _setupRole(WHITELISTED, _multisig); // setup multisig as whitelisted address
    _setupRole(WHITELISTED, _idleRebalancer); // setup multisig as whitelisted address

    // configure weth address and ERC20 interface
    weth = _weth;

    allocations = new uint256[](3); // setup fee split ratio
    allocations[0] = 80000;
    allocations[1] = 15000;
    allocations[2] = 5000;

    beneficiaries = new address[](3); // setup beneficiaries
    beneficiaries[1] = _feeTreasuryAddress; // setup fee treasury address
    beneficiaries[2] = _idleRebalancer; // setup fee treasury address

    address _depositToken;
    for (uint256 index = 0; index < _initialDepositTokens.length; index++) {
      _depositToken = _initialDepositTokens[index];
      require(_depositToken != address(0), "Token cannot be 0 address");
      require(_depositToken != _weth, "WETH not supported"); // There is no WETH -> WETH pool in uniswap
      require(depositTokens.contains(_depositToken) == false, "Already exists");

      IERC20(_depositToken).safeIncreaseAllowance(address(uniswapRouterV2), type(uint256).max); // max approval
      depositTokens.add(_depositToken);
    }
  }

  /**
  @author Asaf Silman
  @notice Converts all registered fee tokens to WETH and deposits to
          fee treasury and smart treasury based on split allocations.
  @dev The fees are swaped using Uniswap simple route. E.g. Token -> WETH.
   */
  function deposit(
    bool[] memory _depositTokensEnabled,
    uint256[] memory _minTokenOut,
    uint256 _minPoolAmountOut
  ) public override smartTreasurySet onlyWhitelisted {
    _deposit(_depositTokensEnabled, _minTokenOut, _minPoolAmountOut);
  }

  /**
  @author Asaf Silman
  @dev implements deposit()
   */
  function _deposit(
    bool[] memory _depositTokensEnabled,
    uint256[] memory _minTokenOut,
    uint256 _minPoolAmountOut
  ) internal {
    uint256 counter = depositTokens.length();
    require(_depositTokensEnabled.length == counter, "Invalid length");
    require(_minTokenOut.length == counter, "Invalid length");

    uint256 _currentBalance;
    IERC20 _tokenInterface;

    uint256 wethBalance;

    address[] memory path = new address[](2);
    path[1] = weth; // output will always be weth
    
    // iterate through all registered deposit tokens
    for (uint256 index = 0; index < counter; index++) {
      if (_depositTokensEnabled[index] == false) {continue;}

      _tokenInterface = IERC20(depositTokens.at(index));

      _currentBalance = _tokenInterface.balanceOf(address(this));
      
      // Only swap if balance > 0
      if (_currentBalance > 0) {
        // create simple route; token->WETH
        
        path[0] = address(_tokenInterface);
        
        // swap token
        uniswapRouterV2.swapExactTokensForTokensSupportingFeeOnTransferTokens(
          _currentBalance,
          _minTokenOut[index], 
          path,
          address(this),
          block.timestamp.add(1800)
        );
      }
    }

    // deposit all swapped WETH + the already present weth balance
    // to beneficiaries
    // the beneficiary at index 0 is the smart treasury
    wethBalance = IERC20(weth).balanceOf(address(this));
    if (wethBalance > 0){
      // feeBalances[0] is fee sent to smartTreasury
      uint256[] memory feeBalances = _amountsFromAllocations(allocations, wethBalance);
      uint256 smartTreasuryFee = feeBalances[0];

      if (wethBalance.sub(smartTreasuryFee) > 0){
          // NOTE: allocation starts at 1, NOT 0, since 0 is reserved for smart treasury
          for (uint256 a_index = 1; a_index < allocations.length; a_index++){
            IERC20(weth).safeTransfer(beneficiaries[a_index], feeBalances[a_index]);
          }
        }

      if (smartTreasuryFee > 0) {
        ConfigurableRightsPool crp = ConfigurableRightsPool(beneficiaries[0]); // the smart treasury is at index 0
        crp.joinswapExternAmountIn(weth, smartTreasuryFee, _minPoolAmountOut);
      }
    }
  }

  /**
  @author Asaf Silman
  @notice Sets the split allocations of fees to send to fee beneficiaries
  @dev The split allocations must sum to 100000.
  @dev Before the split allocation is updated internally a call to `deposit()` is made
       such that all fee accrued using the previous allocations.
  @dev smartTreasury must be set for this to be called.
  @param _allocations The updated split ratio.
   */
  function setSplitAllocation(uint256[] calldata _allocations) external override smartTreasurySet onlyAdmin {
    _depositAllTokens();

    _setSplitAllocation(_allocations);
  }

  /**
  @author Asaf Silman
  @notice Internal function to sets the split allocations of fees to send to fee beneficiaries
  @dev The split allocations must sum to 100000.
  @dev smartTreasury must be set for this to be called.
  @param _allocations The updated split ratio.
   */
  function _setSplitAllocation(uint256[] memory _allocations) internal {
    require(_allocations.length == beneficiaries.length, "Invalid length");
    
    uint256 sum=0;
    for (uint256 i=0; i<_allocations.length; i++) {
      sum = sum.add(_allocations[i]);
    }

    require(sum == FULL_ALLOC, "Ratio does not equal 100000");

    allocations = _allocations;
  }

  /**
  @author Andrea @ idle.finance
  @notice Helper function to deposit all tokens
   */
  function _depositAllTokens() internal {
    uint256 numTokens = depositTokens.length();
    bool[] memory depositTokensEnabled = new bool[](numTokens);
    uint256[] memory minTokenOut = new uint256[](numTokens);

    for (uint256 i = 0; i < numTokens; i++) {
      depositTokensEnabled[i] = true;
      minTokenOut[i] = 1;
    }

    _deposit(depositTokensEnabled, minTokenOut, 1);
  }

  /**
  @author Asaf Silman
  @notice Adds an address as a beneficiary to the idle fees
  @dev The new beneficiary will be pushed to the end of the beneficiaries array.
  The new allocations must include the new beneficiary
  @dev There is a maximum of 5 beneficiaries which can be registered with the fee collector
  @param _newBeneficiary The new beneficiary to add
  @param _newAllocation The new allocation of fees including the new beneficiary
   */
  function addBeneficiaryAddress(address _newBeneficiary, uint256[] calldata _newAllocation) external override smartTreasurySet onlyAdmin {
    require(beneficiaries.length < MAX_BENEFICIARIES, "Max beneficiaries");
    require(_newBeneficiary!=address(0), "beneficiary cannot be 0 address");

    for (uint256 i = 0; i < beneficiaries.length; i++) {
      require(beneficiaries[i] != _newBeneficiary, "Duplicate beneficiary");
    }

    _depositAllTokens();

    beneficiaries.push(_newBeneficiary);

    _setSplitAllocation(_newAllocation);
  }

  /**
  @author Asaf Silman
  @notice removes a beneficiary at a given index.
  @notice WARNING: when using this method be very careful to note the new allocations
  The beneficiary at the LAST index, will be replaced with the beneficiary at `_index`.
  The new allocations need to reflect this updated array.

  eg.
  if beneficiaries = [a, b, c, d]
  and removeBeneficiaryAt(1, [...]) is called

  the final beneficiaries array will be
  [a, d, c]
  `_newAllocations` should be based off of this final array.

  @dev Cannot remove beneficiary past MIN_BENEFICIARIES. set to 2
  @dev Cannot replace the smart treasury beneficiary at index 0
  @param _index The index of the beneficiary to remove
  @param _newAllocation The new allocation of fees removing the beneficiary. NOTE !! The order of beneficiaries will change !!
   */
  function removeBeneficiaryAt(uint256 _index, uint256[] calldata _newAllocation) external override smartTreasurySet onlyAdmin {
    require(_index >= 1, "Invalid beneficiary to remove");
    require(_index < beneficiaries.length, "Out of range");
    require(beneficiaries.length > MIN_BENEFICIARIES, "Min beneficiaries");
    
    _depositAllTokens();

    // replace beneficiary with index with final beneficiary, and call pop
    beneficiaries[_index] = beneficiaries[beneficiaries.length-1];
    beneficiaries.pop();
    
    // NOTE THE ORDER OF ALLOCATIONS
    _setSplitAllocation(_newAllocation);
  }

  /**
  @author Asaf Silman
  @notice replaces a beneficiary at a given index with a new one
  @notice a new allocation must be passed for this method
  @dev Cannot replace the smart treasury beneficiary at index 0
  @param _index The index of the beneficiary to replace
  @param _newBeneficiary The new beneficiary address
  @param _newAllocation The new allocation of fees
  */
  function replaceBeneficiaryAt(uint256 _index, address _newBeneficiary, uint256[] calldata _newAllocation) external override smartTreasurySet onlyAdmin {
    require(_index >= 1, "Invalid beneficiary to remove");
    require(_newBeneficiary!=address(0), "Beneficiary cannot be 0 address");

    for (uint256 i = 0; i < beneficiaries.length; i++) {
      require(beneficiaries[i] != _newBeneficiary, "Duplicate beneficiary");
    }

    _depositAllTokens();
    
    beneficiaries[_index] = _newBeneficiary;

    _setSplitAllocation(_newAllocation);
  }
  
  /**
  @author Asaf Silman
  @notice Sets the smart treasury address.
  @dev This needs to be called atleast once to properly initialise the contract
  @dev Sets maximum approval for WETH to the new smart Treasury
  @dev The smart treasury address cannot be the 0 address.
  @param _smartTreasuryAddress The new smart treasury address
   */
  function setSmartTreasuryAddress(address _smartTreasuryAddress) external override onlyAdmin {
    require(_smartTreasuryAddress!=address(0), "Smart treasury cannot be 0 address");

    // When contract is initialised, the smart treasury address is not yet set
    // Only call change allowance to 0 if previous smartTreasury was not the 0 address.
    if (beneficiaries[0] != address(0)) {
      IERC20(weth).safeApprove(beneficiaries[0], 0); // set approval for previous fee address to 0
    }
    // max approval for new smartTreasuryAddress
    IERC20(weth).safeIncreaseAllowance(_smartTreasuryAddress, type(uint256).max);
    beneficiaries[0] = _smartTreasuryAddress;
  }

  /**
  @author Asaf Silman
  @notice Gives an address the WHITELISTED role. Used for calling `deposit()`.
  @dev Can only be called by admin.
  @param _addressToAdd The address to grant the role.
   */
  function addAddressToWhiteList(address _addressToAdd) external override onlyAdmin{
    grantRole(WHITELISTED, _addressToAdd);
  }

  /**
  @author Asaf Silman
  @notice Removed an address from whitelist.
  @dev Can only be called by admin
  @param _addressToRemove The address to revoke the WHITELISTED role.
   */
  function removeAddressFromWhiteList(address _addressToRemove) external override onlyAdmin {
    revokeRole(WHITELISTED, _addressToRemove);
  }
    
  /**
  @author Asaf Silman
  @notice Registers a fee token to the fee collecter
  @dev There is a maximum of 15 fee tokens than can be registered.
  @dev WETH cannot be accepted as a fee token.
  @dev The token must be a complient ERC20 token.
  @dev The fee token is approved for the uniswap router
  @param _tokenAddress The token address to register
   */
  function registerTokenToDepositList(address _tokenAddress) external override onlyAdmin {
    require(depositTokens.length() < MAX_NUM_FEE_TOKENS, "Too many tokens");
    require(_tokenAddress != address(0), "Token cannot be 0 address");
    require(_tokenAddress != weth, "WETH not supported"); // There is no WETH -> WETH pool in uniswap
    require(depositTokens.contains(_tokenAddress) == false, "Already exists");

    IERC20(_tokenAddress).safeIncreaseAllowance(address(uniswapRouterV2), type(uint256).max); // max approval
    depositTokens.add(_tokenAddress);
  }

  /**
  @author Asaf Silman
  @notice Removed a fee token from the fee collector.
  @dev Resets uniswap approval to 0.
  @param _tokenAddress The fee token address to remove.
   */
  function removeTokenFromDepositList(address _tokenAddress) external override onlyAdmin {
    IERC20(_tokenAddress).safeApprove(address(uniswapRouterV2), 0); // 0 approval for uniswap
    depositTokens.remove(_tokenAddress);
  }

  /**
  @author Asaf Silman
  @notice Withdraws a arbitrarty ERC20 token from feeCollector to an arbitrary address.
  @param _token The ERC20 token address.
  @param _toAddress The destination address.
  @param _amount The amount to transfer.
   */
  function withdraw(address _token, address _toAddress, uint256 _amount) external override onlyAdmin {
    IERC20(_token).safeTransfer(_toAddress, _amount);
  }

  /**
   * Copied from idle.finance IdleTokenGovernance.sol
   *
   * Calculate amounts from percentage allocations (100000 => 100%)
   * @author idle.finance
   * @param _allocations : token allocations percentages
   * @param total : total amount
   * @return newAmounts : array with amounts
   */
  function _amountsFromAllocations(uint256[] memory _allocations, uint256 total) internal pure returns (uint256[] memory newAmounts) {
    newAmounts = new uint256[](_allocations.length);
    uint256 currBalance;
    uint256 allocatedBalance;

    for (uint256 i = 0; i < _allocations.length; i++) {
      if (i == _allocations.length - 1) {
        newAmounts[i] = total.sub(allocatedBalance);
      } else {
        currBalance = total.mul(_allocations[i]).div(FULL_ALLOC);
        allocatedBalance = allocatedBalance.add(currBalance);
        newAmounts[i] = currBalance;
      }
    }
    return newAmounts;
  }

  /**
  @author Asaf Silman
  @notice Exchanges balancer pool token for the underlying assets and withdraws
  @param _toAddress The address to send the underlying tokens to
  @param _amount The underlying amount of balancer pool tokens to exchange
  */
  function withdrawUnderlying(address _toAddress, uint256 _amount, uint256[] calldata minTokenOut) external override smartTreasurySet onlyAdmin{
    ConfigurableRightsPool crp = ConfigurableRightsPool(beneficiaries[0]);
    BPool smartTreasuryBPool = crp.bPool();

    uint256 numTokensInPool = smartTreasuryBPool.getNumTokens();
    require(minTokenOut.length == numTokensInPool, "Invalid length");


    address[] memory poolTokens = smartTreasuryBPool.getCurrentTokens();
    uint256[] memory feeCollectorTokenBalances = new uint256[](numTokensInPool);

    for (uint256 i=0; i<poolTokens.length; i++) {
      // get the balance of a poolToken of the fee collector
      feeCollectorTokenBalances[i] = IERC20(poolTokens[i]).balanceOf(address(this));
    }

    // tokens are exitted to feeCollector
    crp.exitPool(_amount, minTokenOut);

    IERC20 tokenInterface;
    uint256 tokenBalanceToTransfer;
    for (uint256 i=0; i<poolTokens.length; i++) {
      tokenInterface = IERC20(poolTokens[i]);

      tokenBalanceToTransfer = tokenInterface.balanceOf(address(this)).sub( // get the new balance of token
        feeCollectorTokenBalances[i] // subtract previous balance
      );

      if (tokenBalanceToTransfer > 0) {
        // transfer to `_toAddress` [newBalance - oldBalance]
        tokenInterface.safeTransfer(
          _toAddress,
          tokenBalanceToTransfer
        ); // transfer to `_toAddress`
      }
    }
  }

  /**
  @author Asaf Silman
  @notice Replaces the current admin with a new admin.
  @dev The current admin rights are revoked, and given the new address.
  @dev The caller must be admin (see onlyAdmin modifier).
  @param _newAdmin The new admin address.
   */
  function replaceAdmin(address _newAdmin) external override onlyAdmin {
    grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
    revokeRole(DEFAULT_ADMIN_ROLE, msg.sender); // caller must be admin
  }

  function getSplitAllocation() external view returns (uint256[] memory) { return (allocations); }

  function isAddressWhitelisted(address _address) external view returns (bool) {return (hasRole(WHITELISTED, _address)); }
  function isAddressAdmin(address _address) external view returns (bool) {return (hasRole(DEFAULT_ADMIN_ROLE, _address)); }

  function getBeneficiaries() external view returns (address[] memory) { return (beneficiaries); }
  function getSmartTreasuryAddress() external view returns (address) { return (beneficiaries[0]); }

  function isTokenInDespositList(address _tokenAddress) external view returns (bool) {return (depositTokens.contains(_tokenAddress)); }
  function getNumTokensInDepositList() external view returns (uint256) {return (depositTokens.length());}

  function getDepositTokens() external view returns (address[] memory) {
    uint256 numTokens = depositTokens.length();

    address[] memory depositTokenList = new address[](numTokens);
    for (uint256 index = 0; index < numTokens; index++) {
      depositTokenList[index] = depositTokens.at(index);
    }
    return (depositTokenList);
  }
}