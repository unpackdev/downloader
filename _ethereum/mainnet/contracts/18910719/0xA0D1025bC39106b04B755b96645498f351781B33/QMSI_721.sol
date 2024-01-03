// SPDX-License-Identifier: MIT
// File: QMSI/OpenZeppelin/EnumerableSet.sol


// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
        return _values(set._inner);
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

        assembly {
            result := store
        }

        return result;
    }
}

// File: QMSI/OpenZeppelin/Context.sol


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

// File: QMSI/OpenZeppelin/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

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

// File: QMSI/OpenZeppelin/IERC20Metadata.sol


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

// File: QMSI/OpenZeppelin/ERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        uint256 currentAllowance = allowance(from, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(from, spender, currentAllowance - amount);
            }
        }

        _transfer(from, to, amount);

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
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: QMSI/QMSIToken.sol


pragma solidity ^0.8.0;



/**
The interface for the 721 contract
These functions are required inside a market/certificate contract in order for this contract to interface correctly
*/
interface QMSI721 { 
  // all makets need to follow this interface for cross functions to work
  function tokenCommission(uint256 tokenId) external view returns (uint256);
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function tokenPrice(uint256 tokenId) external view returns (uint256);
  function ownerOf(uint256 tokenId) external view returns (address);
  function tokenMinter(uint256 tokenId) external view returns (address);
  function buyToken(address from, uint256 tokenId) external;
  function trueMintingPrice() external view returns (uint256);
  function create(bytes32 dataHash, string calldata tokenURI_, uint256 tokenPrice_, uint256 commission_, address minter_) external returns (uint);
}
/**
The interface for calculating burn rate and faucet reward rate
*/
interface QMSI20 {
  function maxSupply() external view returns (uint256);
  function circulatingSupply() external view returns (uint256);
  function burnRate() external view returns (uint256);
}

/**
 * @dev ERC20 spender logic
 */
abstract contract ERC20Spendable is ERC20 {
  uint256 private _burnPool;
  mapping(address => uint256) public lastClaim;
  uint256 public dailyClaimLimit; // max daily cap for faucet
  uint256 public rewardPerClaim; // negative decay reward, reset each day
  // Halving is every 4 years of activity, divides dailyClaimLimit by 2 until no more faucet
  uint256 public constant halvingInterval = 1460; // 365*4 days
  uint256 public daysConsumed; // for halving purposes
  uint256 public tokensClaimedToday; // tracks tokens claimed for the day, reset each day
  uint256 private dailyAdjuster; // keeps track of when to reset rewardPerClaim
  // Uses Euler's number constant to derive negative decay.
  // e^(-1/100) 
  uint256 private constant eN = 99004983374916819303589981151435220778399087722496;
  uint256 private constant eD = 1e50;

  // @notice Event for when the faucet is used
  event Faucet(address indexed wallet, uint256 reward);

  constructor(){
    _burnPool = 0;
    dailyClaimLimit = 3700 * 1e18; // daily tokens available to claim
    rewardPerClaim = dailyClaimLimit / 100; // 1% of daily cap per person
    daysConsumed = 0; // for tracking number of days faucet was used
    // For resetting rewards each day
    dailyAdjuster = block.timestamp;
  }
  /**
   * @dev Function to check if address is contract address
   * @param _addr The address to check
   * @return A boolean that indicates if the operation was successful
  */
  function _isContract(address _addr) internal view returns (bool) {
    uint32 size;
    assembly{
      size := extcodesize(_addr)
    }
    return (size > 0);
  }

  /**
   * @dev Function to return rate at which tokens should burn
   * @return A percent value between 0 to 100 of liquid tokens
   */
  function burnRate() external view returns (uint256) {
    return (totalSupply() * 100) / QMSI20(address(this)).maxSupply();
  }

  /**
   * @dev Function to burn tokens, but add them to a pool that others can stake to reclaim
   * @param value The amount of tokens to spend
   * @return A boolean that indicates if the operation was successful
   */
  function spend(uint256 value) public returns (bool)
  {
    _burn(msg.sender, value);
    _burnPool += value;
    return true;
  }
  /**
    * @dev Returns the amount of tokens burned that can be reclaimed through staking.
    */
  function burnPool() public view virtual returns (uint256){
      return _burnPool;
  }
 /**
   * @dev Function to subtract from the burn pool
   * @param value The tokens to take away from the pool
  */
  function _depleteBurnPool(uint256 value) internal {
    _burnPool -= value;
  }


   /**
   * @dev Function serves as equal opportunity faucet for creating new tokens for free
   * @notice each execution reduces the reward for the next (reset each day)
   * @notice each execution per msg.sender can only be done once a day
  */
  function drinkFromFaucet() external {
    // Needs to run before require checks in case tokenClaimedToday needs to be reset since it's been a day since the last reset
    // otherwise, a deadlock will occur in which tokensClaimedToday helps exceed daily allowed limit, and this will continue forever since it can't be reset in time of the check
    uint256 timeSinceDailyAdjusterRan = block.timestamp - dailyAdjuster;
    if (timeSinceDailyAdjusterRan >= 1 days) {
      // Reset tokens claimed today to 0 if it's been longer than a day, so that it's actually "tokens claimed TODAY"
      tokensClaimedToday = 0;
      daysConsumed += 1;
      // Reward per claim is reset back to original number, this value is divided by 2 per claim on a given day, so that everyone has a chance to get some value from the contract
      rewardPerClaim = dailyClaimLimit / 100;
      dailyAdjuster = block.timestamp;
    }
    
    require(canDrink(msg.sender), "QMSI-ERC20: wait 24 hours before claiming again");
    // Respect the mac supply allowed
    require( QMSI20(address(this)).circulatingSupply() + rewardPerClaim < QMSI20(address(this)).maxSupply(), "QMSI-ERC20: cannot drink above cup size"); // make sure we cannot go above max supply
    require(tokensClaimedToday + rewardPerClaim <= dailyClaimLimit, "QMSI-ERC20: Faucet has reached its daily limit");

    // Tracks the last time user drank from faucet
    lastClaim[msg.sender] = block.timestamp;

    // Transfer tokens to the claimer
    _mint(msg.sender, rewardPerClaim);
    
    emit Faucet(msg.sender, rewardPerClaim);
    // Accumulate total tokens in a given day
    tokensClaimedToday += rewardPerClaim;
    
    // Adjust the reward for the next claim
    adjustReward();
  }

 /**
   * @dev Function to check if claimer is able to drink from the faucet
   * @param claimer The address to check for eligibility
  */
  function canDrink(address claimer) public view returns (bool) {
    uint256 lastClaimedTime = lastClaim[claimer];
    if (lastClaimedTime == 0) {
        return true; // First-time claim
    }
    
    uint256 timeSinceLastClaim = block.timestamp - lastClaimedTime;
    if (timeSinceLastClaim >= 1 days) {
        return true; // Claimer can claim again after 24 hours
    }
    return false; // Claimer can't claim yet
  }

 /**
   * @dev Function (internal) for adjusting the reward using negative decay
   * @notice also handles halving events based on days of activity every 4 years of usage
  */
  function adjustReward() internal {
    // Follow Euler's negative distribution curve
    // reward = (reward) * math.exp(-k)
    rewardPerClaim = (rewardPerClaim * eN) / eD;
    // Halve the reward if needed
    if (daysConsumed >= halvingInterval) {
        dailyClaimLimit = dailyClaimLimit / 2;
        daysConsumed = 0;
    }
  }
}

contract QMSI_20 is ERC20, ERC20Spendable {
  uint256 private constant _maxSupply = 37000000 * 1e18;
  mapping (address => uint256) private _QNS;

  mapping (address => uint256) private _Staked;
  mapping (address => uint256) private _Unlocker;
  uint256 private _totalStaked;

  // @notice Event for when QNS is set
  event SetQNS(address indexed from, uint256 indexed qid);

  // @notice Event for when tokens are staked
  event Stake(address indexed from, uint256 indexed days_, uint256 indexed value_);

  // @notice Event for when tokens staked are unlocked
  event Unlock(address indexed from, uint256 indexed value_);

  // @notice Event for when cross token create occurs
  event CrossTokenBuy(address indexed from, address indexed market, address indexed to, uint256 value);

  // @notice Eveent for when cross token mint occurs
  event CrossTokenCreate(address indexed from, address indexed market, uint256 indexed mintCost);

  constructor() ERC20("Qumosi", "QMSI") {}
  /**
   * @dev Returns the max allowed supply of the token.
   */
  function maxSupply() public view virtual returns (uint256) {
      return _maxSupply;
  }

  function circulatingSupply() public view virtual returns (uint256) {
    return totalSupply() + totalStaked() + burnPool();
  }
  /**
  * @notice allows users to set the ID of their Qumosi profiles. used to verify ownership of a wallet on the website itself.
  * @param qid the Qumosi account ID (example: https://qumosi.com/members.php?id=3981987 <-- this number is the qid)
  */
  function setQNS(uint256 qid) external {
      _QNS[msg.sender] = qid;
      emit SetQNS(msg.sender, qid);
  }
  /**
    * @dev Returns Qumosi profile ID.
    */
  function getQNS(address account) public view virtual returns (uint256) {
    require(_QNS[account] > 0, "QMSI-ERC20: No QNS set");
    return _QNS[account];
  }

  /**
  * @notice stake allows users to trade time for more tokens, by reclaiming burned tokens
  * @param days_ the number of days the tokens are to be locked for
  * @param value_ the amount of tokens to lock
  */
  function stake(uint256 days_, uint256 value_) external{
    require(days_ > 0 && value_ > 0, "QMSI-ERC20: Non-zero values only");
    require(balanceOf(msg.sender) > value_, "QMSI-ERC20: Not enough tokens to lock");
    require(_Staked[msg.sender] == 0, "QMSI-ERC20: Can only stake one set of tokens at a time");
    uint256 reward = ((value_ * days_) / totalSupply());
    // require(reward + circulatingSupply() < maxSupply(), "QMSI-ERC20: Reward exceeds total supply"); // incorrect because reward is included in burnpool which is in circulation
    require(reward < burnPool(), "QMSI-ERC20: Not enough tokens to reward user from the burn pool");
    // lock both collateral and reward from burn pool
    _Staked[msg.sender] = value_ + reward;
    _Unlocker[msg.sender] = block.timestamp + (days_ * 1 days);
    _totalStaked += _Staked[msg.sender]; // includes both staking value and reward of all people
    _burn(msg.sender, value_); // does not add it to burn pool, but still removes them
    _depleteBurnPool(reward); // reclaiming burned tokens from minting 721 tokens

    // total supply is down by value staked
    // burn pool is down by reward being promised
    // total staked is up by reward and value staked
    // circulation showing no difference after conversion
    emit Stake(msg.sender, days_, value_);
  }
  /**
  * @notice allows for user to unlock tokens locked using stake function
  */
  function unlockTokens() external{
    // require(_Staked[msg.sender] + circulatingSupply() < maxSupply(), "QMSI-ERC20: Reward exceeds total supply"); // incorrect because reward is already in total staked value
    require(_Staked[msg.sender] > 0, "QMSI-ERC20: Not staking any tokens to unlock");
    require(block.timestamp > _Unlocker[msg.sender], "QMSI-ERC20: tokens are still locked");
    _mint(msg.sender, _Staked[msg.sender]); // we mint the reward and value staked from before
    _totalStaked -= _Staked[msg.sender]; // takes away reward and value staked back to owner
    emit Unlock(msg.sender, _Staked[msg.sender]);
    _Staked[msg.sender] = 0;

    // totalsupply is up by reward and value staked
    // total staked is down by reward and value staked
    // burn pool is unchanged
    // circulation showing no diference after conversion
  }
  /**
    * @dev Returns the amount staked in total in the entire smart contract.
    */
  function totalStaked() public view virtual returns (uint256) {
      return _totalStaked;
  }
  /**
    * @notice for checking the amount of locked/staked tokens of a particular user
    * @param account the address of the account that is staking an amount
    * @return The amount of tokens that are currently being staked
    */
  function lockedBalanceOf(address account) public view virtual returns (uint256) {
      return _Staked[account];
  }
  /**
    * @notice for checking the date an account is allowed to claim locked tokens
    * @param account the address of the account that is staking an amount
    * @return The date of when the tokens can be claimed back
    */
  function unlockDate(address account) public view virtual returns (uint256) {
      return _Unlocker[account];
  }
  /**
    * @notice Staking rewards estimator
    * @param days_ the number of days the tokens are to be locked for
    * @param value_ the amount of tokens to lock
    */
  function rewardsCalculator(uint256 days_, uint256 value_) public view virtual returns (uint256) {
    // should take into account total staked. if many are staked, lower the reward.
    require(value_ <= totalSupply(), "QMSI-ERC20: Value exceeds available token supply");
    // reward formula for staking
    uint256 reward = ((value_ * days_) / totalSupply());
    
    require(reward < burnPool(), "QMSI-ERC20: Not enough tokens to reward user from the burn pool");
    require(reward + circulatingSupply() < maxSupply(), "QMSI-ERC20: Reward exceeds total supply");
    return reward;
  }

  /**
   * @dev Function to buy certificate using tokens from this contract if certificate is for sale.
   * @param market the address of the certificate contract, must be a spender
   * @param to the address of who we're sending tokens to
   * @param tokenId the tokenId of the token we're buying from market
   * @param tokenPrice_ the price of the token, used so after page load it is cached in the request
   * @param tokenCommission_ the commission of the token, used so after page load it is cached in the request
   * @return A boolean that indicates if the operation was successful
  */
  function crossTokenBuy(address market, address to, uint256 tokenId, uint256 tokenPrice_, uint256 tokenCommission_) public returns (bool) {
    require(balanceOf(msg.sender) >= tokenPrice_, "QMSI-ERC20: Insufficient tokens");
    require(_isContract(market) == true, "QMSI-ERC20: Only contract addresses are considered markets.");
    // To prevent price manipulation by making user aware of the price by including it in the function call
    require(tokenPrice_ == QMSI721(market).tokenPrice(tokenId), "QMSI-ERC721: Price is not equal");
    // To prevent commission manipulation by making user aware of the rate prior to making the function call
    require(tokenCommission_ == QMSI721(market).tokenCommission(tokenId), "QMSI-ERC721: Commission rate does not match");
    require(tokenCommission_ <= 100 && tokenCommission_ >= 0, "QMSI-ERC721: Commission must be a percent");
    require(bytes(QMSI721(market).tokenURI(tokenId)).length > 0, "QMSI-ERC721: Nonexistent token");

    require(QMSI721(market).tokenPrice(tokenId) > 0, "QMSI-ERC721: Token not for sale");
    require(msg.sender != QMSI721(market).ownerOf(tokenId), "QMSI-ERC721: Cannot buy your own token");
    require(to == QMSI721(market).ownerOf(tokenId), "QMSI-ERC721: Sending tokens to the wrong owner");

    if(tokenCommission_ > 0 && msg.sender != QMSI721(market).tokenMinter(tokenId)){
      transfer(to, (tokenPrice_ * (100 - tokenCommission_)) / 100);
      transfer(QMSI721(market).tokenMinter(tokenId), (tokenPrice_ * tokenCommission_) / 100);
    }else{
      transfer(to, tokenPrice_);
    }
    QMSI721(market).buyToken(msg.sender, tokenId);
    emit CrossTokenBuy(msg.sender, market, to, tokenPrice_);
    return true;
  }

  /**
   * @dev Function to mint a certificate using tokens from this contract and the minting price of the ERC721 contract
   * @param market the address of the certificate contract
    * @param dataHash A representation of the certificate data using the Aria
    *   protocol (a 0xcert cenvention).
    * @param tokenURI_ The remote location of the certificate's JSON artifact, represented by the dataHash
    * @param tokenPrice_ The (optional) price of the certificate in token currency in order for someone to buy it and transfer ownership of it
    * @param commission_ The (optional) percentage that the original minter will take each time the certificate is bought
   * @param mintingPrice_ The price of minting a certificate (so that we know the "client" is not unaware of a burn rate change, if there is one prior to executing the create function)
   * @return A boolean that indicates if the operation was successful
  */
  function crossTokenCreate(address market, bytes32 dataHash, string calldata tokenURI_, uint256 tokenPrice_, uint256 commission_, uint256 mintingPrice_) public returns (uint) {
    // verify that user is aware of the 721 market mint price, so no manipulation can occur
    uint256 mintingPrice = QMSI721(market).trueMintingPrice();
    require(mintingPrice_ == mintingPrice, "QMSI-ERC20: Minting price does not match");
    require(tokenPrice_ <= maxSupply() && tokenPrice_ >= 0 && mintingPrice_ <= maxSupply() && mintingPrice_ >= 0, "QMSI-ERC20: Invalid units for token or minting prices");
    require(commission_ <= 100 && commission_ >= 0, "QMSI-ERC721: Commission must be a percent");
    require(bytes(tokenURI_).length > 0, "QMSI-ERC721: Must define token URI string");
    // determine value that needs to be burrned, will always be equal to or less than minting price
    uint256 burnValue = (mintingPrice*this.burnRate())/100;
    require(balanceOf(msg.sender) >= burnValue, "QMSI-ERC20: Insufficient tokens");
    spend(burnValue);
    emit CrossTokenCreate(msg.sender, market, burnValue);
    
    return QMSI721(market).create(dataHash, tokenURI_, tokenPrice_, commission_, msg.sender);

    // total supply is down by value spent
    // burn pool is up by value spent
    // total staked is unchanged
    // circulation showing no difference after conversion
  }
}
// File: QMSI/OpenZeppelin/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: QMSI/Nibbstack/ownable.sol


pragma solidity ^0.8.0;

/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code at:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 */
contract Ownable
{

  /**
   * @dev Error constants.
   */
  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  /**
   * @dev Current owner address.
   */
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    public
    onlyOwner
  {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

// File: QMSI/Nibbstack/address-utils.sol


pragma solidity ^0.8.0;

/**
 * @notice Based on:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
 * Requires EIP-1052.
 * @dev Utility library of inline functions on addresses.
 */
library AddressUtils
{

  /**
   * @dev Returns whether the target address is a contract.
   * @param _addr Address to check.
   * @return addressCheck True if _addr is a contract, false if not.
   */
  function isContract(
    address _addr
  )
    internal
    view
    returns (bool addressCheck)
  {
    // This method relies in extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly { codehash := extcodehash(_addr) } // solhint-disable-line
    addressCheck = (codehash != 0x0 && codehash != accountHash);
  }

}

// File: QMSI/Nibbstack/erc165.sol


pragma solidity ^0.8.0;

/**
 * @dev A standard for detecting smart contract interfaces. 
 * See: https://eips.ethereum.org/EIPS/eip-165.
 */
interface ERC165
{

  /**
   * @dev Checks if the smart contract includes a specific interface.
   * This function uses less than 30,000 gas.
   * @param _interfaceID The interface identifier, as specified in ERC-165.
   * @return True if _interfaceID is supported, false otherwise.
   */
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    view
    returns (bool);
    
}

// File: QMSI/Nibbstack/supports-interface.sol


pragma solidity ^0.8.0;


/**
 * @dev Implementation of standard for detect smart contract interfaces.
 */
contract SupportsInterface is
  ERC165
{

  /**
   * @dev Mapping of supported intefraces. You must not set element 0xffffffff to true.
   */
  mapping(bytes4 => bool) internal supportedInterfaces;

  /**
   * @dev Contract constructor.
   */
  constructor()
  {
    supportedInterfaces[0x01ffc9a7] = true; // ERC165
  }

  /**
   * @dev Function to check which interfaces are suported by this contract.
   * @param _interfaceID Id of the interface.
   * @return True if _interfaceID is supported, false otherwise.
   */
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    override
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceID];
  }

}

// File: QMSI/Nibbstack/erc721-token-receiver.sol


pragma solidity ^0.8.0;

/**
 * @dev ERC-721 interface for accepting safe transfers.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721TokenReceiver
{

  /**
   * @notice The contract address is always the message sender. A wallet/broker/auction application
   * MUST implement the wallet interface if it will accept safe transfers.
   * @dev Handle the receipt of a NFT. The ERC721 smart contract calls this function on the
   * recipient after a `transfer`. This function MAY throw to revert and reject the transfer. Return
   * of other than the magic value MUST result in the transaction being reverted.
   * Returns `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` unless throwing.
   * @param _operator The address which called `safeTransferFrom` function.
   * @param _from The address which previously owned the token.
   * @param _tokenId The NFT identifier which is being transferred.
   * @param _data Additional data with no specified format.
   * @return Returns `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    returns(bytes4);

}

// File: QMSI/Nibbstack/erc721.sol


pragma solidity ^0.8.0;

/**
 * @dev ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721
{

  /**
   * @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
   * created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
   * number of NFTs may be created and assigned without emitting Transfer. At the time of any
   * transfer, the approved address for that NFT (if any) is reset to none.
   */
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
   * address indicates there is no approved address. When a Transfer event emits, this also
   * indicates that the approved address for that NFT (if any) is reset to none.
   */
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
   * all NFTs of the owner.
   */
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  /**
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @dev Transfers the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;

  /**
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @dev Transfers the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they may be permanently lost.
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT.  This function can be changed to payable.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
   * the current NFT owner, or an authorized operator of the current owner.
   * @param _approved The new approved NFT controller.
   * @dev Set or reaffirm the approved address for an NFT. This function can be changed to payable.
   * @param _tokenId The NFT to approve.
   */
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;

  /**
   * @notice The contract MUST allow multiple operators per owner.
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`'s assets. It also emits the ApprovalForAll event.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @notice Count all NFTs assigned to an owner.
   * @param _owner Address for whom to query the balance.
   * @return Balance of _owner.
   */
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  /**
   * @notice Find the owner of an NFT.
   * @dev Returns the address of the owner of the NFT. NFTs assigned to the zero address are
   * considered invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   * @return Address of _tokenId owner.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @dev Get the approved address for a single NFT.
   * @param _tokenId The NFT to find the approved address for.
   * @return Address that _tokenId is approved for.
   */
  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @notice Query if an address is an authorized operator for another address.
   * @dev Returns true if `_operator` is an approved operator for `_owner`, false otherwise.
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   * @return True if approved for all, false otherwise.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}

// File: QMSI/Nibbstack/nf-token.sol


pragma solidity ^0.8.0;





/**
 * @dev Implementation of ERC-721 non-fungible token standard.
 */
contract NFToken is
  ERC721,
  SupportsInterface
{
  using AddressUtils for address;

  /**
   * @dev List of revert message codes. Implementing dApp should handle showing the correct message.
   * Based on 0xcert framework error codes.
   */
  string constant ZERO_ADDRESS = "003001";
  string constant NOT_VALID_NFT = "003002";
  string constant NOT_OWNER_OR_OPERATOR = "003003";
  string constant NOT_OWNER_APPROVED_OR_OPERATOR = "003004";
  string constant NOT_ABLE_TO_RECEIVE_NFT = "003005";
  string constant NFT_ALREADY_EXISTS = "003006";
  string constant NOT_OWNER = "003007";
  string constant IS_OWNER = "003008";

  /**
   * @dev Magic value of a smart contract that can receive NFT.
   * Equal to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")).
   */
  bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

  /**
   * @dev A mapping from NFT ID to the address that owns it.
   */
  mapping (uint256 => address) internal idToOwner;

  /**
   * @dev Mapping from NFT ID to approved address.
   */
  mapping (uint256 => address) internal idToApproval;

   /**
   * @dev Mapping from owner address to count of their tokens.
   */
  mapping (address => uint256) private ownerToNFTokenCount;

  /**
   * @dev Mapping from owner address to mapping of operator addresses.
   */
  mapping (address => mapping (address => bool)) internal ownerToOperators;

  /**
   * @dev Guarantees that the msg.sender is an owner or operator of the given NFT.
   * @param _tokenId ID of the NFT to validate.
   */
  modifier canOperate(
    uint256 _tokenId
  )
  {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_OR_OPERATOR
    );
    _;
  }

  /**
   * @dev Guarantees that the msg.sender is allowed to transfer NFT.
   * @param _tokenId ID of the NFT to transfer.
   */
  modifier canTransfer(
    uint256 _tokenId
  )
  {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender
      || idToApproval[_tokenId] == msg.sender
      || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_APPROVED_OR_OPERATOR
    );
    _;
  }

  /**
   * @dev Guarantees that _tokenId is a valid Token.
   * @param _tokenId ID of the NFT to validate.
   */
  modifier validNFToken(
    uint256 _tokenId
  )
  {
    require(idToOwner[_tokenId] != address(0), NOT_VALID_NFT);
    _;
  }

  /**
   * @dev Contract constructor.
   */
  constructor()
  {
    supportedInterfaces[0x80ac58cd] = true; // ERC721
  }

  /**
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @dev Transfers the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    override
  {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }

  /**
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to "".
   * @dev Transfers the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    override
  {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they may be permanently lost.
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT. This function can be changed to payable.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    override
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);
  }

  /**
   * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
   * the current NFT owner, or an authorized operator of the current owner.
   * @dev Set or reaffirm the approved address for an NFT. This function can be changed to payable.
   * @param _approved Address to be approved for the given NFT ID.
   * @param _tokenId ID of the token to be approved.
   */
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external
    override
    canOperate(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(_approved != tokenOwner, IS_OWNER);

    idToApproval[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }

  /**
   * @notice This works even if sender doesn't own any tokens at the time.
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`'s assets. It also emits the ApprovalForAll event.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external
    override
  {
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @param _owner Address for whom to query the balance.
   * @return Balance of _owner.
   */
  function balanceOf(
    address _owner
  )
    external
    override
    view
    returns (uint256)
  {
    require(_owner != address(0), ZERO_ADDRESS);
    return _getOwnerNFTCount(_owner);
  }

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to the zero address are
   * considered invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   * @return _owner Address of _tokenId owner.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    override
    view
    returns (address _owner)
  {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0), NOT_VALID_NFT);
  }

  /**
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @dev Get the approved address for a single NFT.
   * @param _tokenId ID of the NFT to query the approval of.
   * @return Address that _tokenId is approved for.
   */
  function getApproved(
    uint256 _tokenId
  )
    external
    override
    view
    validNFToken(_tokenId)
    returns (address)
  {
    return idToApproval[_tokenId];
  }

  /**
   * @dev Checks if `_operator` is an approved operator for `_owner`.
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   * @return True if approved for all, false otherwise.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    override
    view
    returns (bool)
  {
    return ownerToOperators[_owner][_operator];
  }

  /**
   * @notice Does NO checks.
   * @dev Actually performs the transfer.
   * @param _to Address of a new owner.
   * @param _tokenId The NFT that is being transferred.
   */
  function _transfer(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
  {
    address from = idToOwner[_tokenId];
    _clearApproval(_tokenId);

    _removeNFToken(from, _tokenId);
    _addNFToken(_to, _tokenId);

    emit Transfer(from, _to, _tokenId);
  }

  /**
   * @notice This is an internal function which should be called from user-implemented external
   * mint function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @dev Mints a new NFT.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   */
  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(_to != address(0), ZERO_ADDRESS);
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    _addNFToken(_to, _tokenId);

    emit Transfer(address(0), _to, _tokenId);
  }

  /**
   * @notice This is an internal function which should be called from user-implemented external burn
   * function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @dev Burns a NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(
    uint256 _tokenId
  )
    internal
    virtual
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    _clearApproval(_tokenId);
    _removeNFToken(tokenOwner, _tokenId);
    emit Transfer(tokenOwner, address(0), _tokenId);
  }

  /**
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @dev Removes a NFT from owner.
   * @param _from Address from which we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(idToOwner[_tokenId] == _from, NOT_OWNER);
    ownerToNFTokenCount[_from] -= 1;
    delete idToOwner[_tokenId];
  }

  /**
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @dev Assigns a new NFT to owner.
   * @param _to Address to which we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    idToOwner[_tokenId] = _to;
    ownerToNFTokenCount[_to] += 1;
  }

  /**
   * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
   * extension to remove double storage (gas optimization) of owner NFT count.
   * @param _owner Address for whom to query the count.
   * @return Number of _owner NFTs.
   */
  function _getOwnerNFTCount(
    address _owner
  )
    internal
    virtual
    view
    returns (uint256)
  {
    return ownerToNFTokenCount[_owner];
  }

  /**
   * @dev Actually perform the safeTransferFrom.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function _safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    private
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);

    if (_to.isContract())
    {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == MAGIC_ON_ERC721_RECEIVED, NOT_ABLE_TO_RECEIVE_NFT);
    }
  }

  /**
   * @dev Clears the current approval of a given NFT ID.
   * @param _tokenId ID of the NFT to be transferred.
   */
  function _clearApproval(
    uint256 _tokenId
  )
    private
  {
    delete idToApproval[_tokenId];
  }

}

// File: QMSI/QMSICertificate.sol


pragma solidity ^0.8.0;





/**
 * @notice A non-fungible certificate that anybody can create by spending tokens
 */

abstract contract DeadmanSwitch is Ownable {
    address private _kin;
    uint256 private _timestamp;
    constructor() {
        _kin = msg.sender;
        _timestamp = block.timestamp;
    }
    // @notice Event for when deadman switch is set
    event SetDeadSwitch(address indexed kin_, uint256 indexed days_);
    /**
    * @notice to be used by contract owner to set a deadman switch in the event of worse case scenario
    * @param kin_ the address of the next owner of the smart contract if the owner dies
    * @param days_ number of days from current time that the owner has to check-in prior to, otherwise the kin can claim ownership
    */
    function setDeadmanSwitch(address kin_, uint256 days_) onlyOwner external returns (bool){
      require(days_ < 365, "QMSI-ERC721: Must check-in once a year");
      require(kin_ != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
      _kin = kin_;
      _timestamp = block.timestamp + (days_ * 1 days);
      emit SetDeadSwitch(kin_, days_);
      return true;
    }
    /**
    * @notice to be used by the next of kin to claim ownership of the smart contract if the time has expired
    * @return true on successful owner transfer
    */
    function claimSwitch() external returns (bool){
      require(msg.sender == _kin, "QMSI-ERC721: Only next of kin can claim a deadman's switch");
      require(block.timestamp > _timestamp, "QMSI-ERC721: Deadman is alive");
      emit OwnershipTransferred(owner, _kin);
      owner = _kin;
      return true;
    }
    /**
    * @notice used to see who the next owner of the smart contract will be, if the switch expires
    * @return the address of the next of kin
    */
    function getKin() public view virtual returns (address) {
        return _kin;
    }
    /**
    * @notice used to get the date that the switch expires to allow for claiming it
    * @return the timestamp for which the switch expires
    */
    function getExpiry() public view virtual returns (uint256) {
        return _timestamp;
    }
}

contract QMSI_721 is NFToken, DeadmanSwitch
{
    // @notice Event for when NFT is sold
    event SoldNFT(address indexed seller, uint256 indexed tokenId, address indexed buyer);

    // @notice Event for when NFT is minted
    event MintedNFT(address indexed minter, uint256 indexed tokenId);

    // @notice Event for when minting currency is set
    event SetMintCurrency(ERC20Spendable indexed qmsi);
    
    // @notice Event for when mint price changes
    event SetMintPrice(uint256 indexed price);

    // @notice Event for when base URI is set
    event SetBaseURI(string indexed baseURI);

    // @notice Event for when NFT price changes
    event SetNFTPrice(address indexed seller, uint256 indexed tokenId, uint256 indexed price);

    // @notice Event for when NFT token commission changes
    event SetTokenCommission(address indexed minter, uint256 indexed tokenId, uint256 indexed percentage);

    // @notice Event for when NFT URI location changes
    event SetTokenURI(address indexed minter, uint256 indexed tokenId, string indexed tokenURI);

    /// @notice The price to create new certificates
    uint256 _mintingPrice;

    /// @notice The currency to create new certificates
    ERC20Spendable _mintingCurrency;

    /// @dev The serial number of the next certificate to create
    uint256 public nextCertificateId = 1;

    mapping(uint256 => bytes32) certificateDataHashes;

    // ERC721 tokenURI standard
    mapping (uint256 => string) private _tokenURIs;

    mapping (uint256 => uint256) private _tokenPrices;

    // Mappings for commission
    mapping (uint256 => uint256) private _tokenCommission;

    mapping (uint256 => address) private _tokenMinter;

    /**
     * @notice Query the certificate hash for a token
     * @param tokenId Which certificate to query
     * @return The hash for the certificate
     */
    function hashForToken(uint256 tokenId) external view returns (bytes32) {
        return certificateDataHashes[tokenId];
    }

    /**
     * @notice The price to create certificates influenced by token circulation and max supply
     * @return The price to create certificates
     */
    function mintingPrice() external view returns (uint256) {
        uint256 _burnRate = _mintingCurrency.burnRate();
        return (_mintingPrice*_burnRate)/100;
    }

    /**
     * @notice The price to create certificates
     * @return The price to create certificates
     */
    function trueMintingPrice() external view returns (uint256) {
        return _mintingPrice;
    }

    /**
     * @notice The currency (ERC20) to create certificates
     * @return The currency (ERC20) to create certificates
     */
    function mintingCurrency() external view returns (ERC20Spendable) {
        return _mintingCurrency;
    }

    /**
     * @notice Set new price to create certificates
     * @param newMintingPrice The new price
     */
    function setMintingPrice(uint256 newMintingPrice) onlyOwner external {
        _mintingPrice = newMintingPrice;
        emit SetMintPrice(newMintingPrice);
    }

    /**
     * @notice Set new ERC20 currency to create certificates
     * @param newMintingCurrency The new currency
     */
    function setMintingCurrency(ERC20Spendable newMintingCurrency) onlyOwner external {
        _mintingCurrency = newMintingCurrency;
        emit SetMintCurrency(newMintingCurrency);
    }

    // Base URI
    string private _baseURIextended;

    /**
    * @dev Function to check if address is contract address
    * @param _addr The address to check
    * @return A boolean that indicates if the operation was successful
    */
    function _isContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly{
        size := extcodesize(_addr)
        }
        return (size > 0);
    }

    /**
     * @notice used by the contract owner to set a prefix string at the beginning of all token resource locations.
     * @param baseURI_ the string that goes at the beginning of all token URI
     *
     */
    function setBaseURI(string calldata baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
        emit SetBaseURI(baseURI_);
    }


    /**
     * @notice used for setting the certificate artifact remote location. only be called by setTokenURI.
     * @param tokenId the id of the certificate that we want to set the remote location of
     * @param _tokenURI a string that contains the URL of the artifact's location.
     *
     */
    function _setTokenURI(uint256 tokenId, string calldata _tokenURI) internal virtual {
        require(bytes(_tokenURI).length > 0, "QMSI-ERC721: token URI cannot be empty");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @notice for setting the commission rate of a certificate, called by setTokenCommissionProperty only.
     * @param tokenId the id of the certificate that we want to set the commission rate
     * @param percentage the percent token commission rate that is taken by the original minter
     *
     */
    function _setTokenCommissionProperty(uint256 tokenId, uint256 percentage) internal virtual{
        require(percentage >= 0 && percentage <= 100, "QMSI-ERC721: Commission property must be a percent integer");
        _tokenCommission[tokenId] = percentage;
    }

    /**
     * @notice for setting the commission rate of a certificate, optional. only original minter can call this.
     * @param tokenId the id of the certificate that we want to set the commission rate
     * @param percentage_ the percent token commission rate that is taken by the original minter
     *
     */
    function setTokenCommissionProperty(uint256 tokenId, uint256 percentage_) external{
        require(bytes(_tokenURIs[tokenId]).length > 0, "QMSI-ERC721: Nonexistent token");
        require(msg.sender == _tokenMinter[tokenId], "QMSI-ERC721: Must be the original minter to set commission rate");
        require(percentage_ >= 0 && percentage_ <= 100, "QMSI-ERC721: Commission property must be a percent integer");
        _setTokenCommissionProperty(tokenId, percentage_);
        emit SetTokenCommission(msg.sender, tokenId, percentage_);

    }

    /**
     * @notice used for setting the original artist/minter of the certificate. called once per tokenId.
     * @param tokenId the id of the certificate that is being minted
     *
     */
    function _setTokenMinter(uint256 tokenId, address minter) internal virtual {
        require(minter != address(0), "QMSI-ERC721: Invalid address");
        _tokenMinter[tokenId] = minter;
    }

    /**
     * @notice used for setting the price of the token. can only be called from sellToken()
     * @param tokenId the id of the certificate that we want sell
     * @param _tokenPrice the amount in token currency units that we want to sell the certificate for
     *
     */
    function _setTokenPrice(uint256 tokenId, uint256 _tokenPrice) internal virtual {
        if(_tokenPrice > 0){
            _tokenPrices[tokenId] = _tokenPrice;
        }
    }

    /**
     * @notice used for creating a listing for the certificate to be bought
     * @param tokenId the id of the certificate that we want sell
     * @param _tokenPrice the amount in token currency units that we want to sell the certificate for
     *
     */
    function sellToken(uint256 tokenId, uint256 _tokenPrice) external {
        require(bytes(_tokenURIs[tokenId]).length > 0, "QMSI-ERC721: Nonexistent token");
        require(msg.sender == idToOwner[tokenId], "QMSI-ERC721: Must own token in order to sell");
        require(_tokenPrice > 0, "QMSI-ERC721: Must set a price to sell token for");
        _setTokenPrice(tokenId, _tokenPrice);
        emit SetNFTPrice(msg.sender, tokenId, _tokenPrice);
    }

    /**
     * @notice used for removing a listing, if the certificate is up for sale
     * @param tokenId the id of the certificate that we want to remove listing of
     *
     */
    function removeListing(uint256 tokenId) external {
        require(bytes(_tokenURIs[tokenId]).length > 0, "QMSI-ERC721: Nonexistent token");
        require(msg.sender == idToOwner[tokenId], "QMSI-ERC721: Must own token in order to remove listing");
        require(_tokenPrices[tokenId] > 0, "QMSI-ERC721: Must be selling in order to remove listing");
        _tokenPrices[tokenId] = 0;
        emit SetNFTPrice(msg.sender, tokenId, 0);
    }

    /**
     * @notice used for setting the certificate artifact remote location
     * @param tokenId the id of the certificate that we want to set the remote location of
     * @param _tokenURI a string that contains the URL of the artifact's location.
     *
     */
    function setTokenURI(uint256 tokenId, string calldata _tokenURI) external {
        require(bytes(_tokenURIs[tokenId]).length > 0, "QMSI-ERC721: Nonexistent token");
        require(msg.sender == _tokenMinter[tokenId], "QMSI-ERC721: Must be the original minter to set URI");
        _setTokenURI(tokenId, _tokenURI);
        emit SetTokenURI(msg.sender, tokenId, _tokenURI);
    }

    /**
     * @notice the price of the certificate in token currency units, if there is one
     * @param tokenId the id of the certificate that we want to the price of
     * @return the amount in token currency the token is set to sell at
     *
     */
    function tokenPrice(uint256 tokenId) external view returns (uint256) {
        return _tokenPrices[tokenId];
    }

    /**
     * @notice for finding the commission rate of a certificate, if there is one
     * @param tokenId the id of the certificate that we want to know the commission rate
     * @return the percent token commission rate that is taken by the original minter
     *
     */
    function tokenCommission(uint256 tokenId) external view returns (uint256) {
        return _tokenCommission[tokenId];
    }

    /**
     * @notice for finding who the original minter of a certificate is
     * @param tokenId the id of the certificate that we want to know the minter of
     * @return the address of the original minter of the certificate
     *
     */
    function tokenMinter(uint256 tokenId) external view returns (address) {
        return _tokenMinter[tokenId];
    }

    /**
     * @notice to be called by the buy function inside the ERC20 contract
     * @param from the address we are transferring the NFT from
     * @param tokenId the id of the NFT we are moving
     *
     */
    function buyToken(address from, uint256 tokenId) external {
        require(_isContract(msg.sender) == true, "QMSI-ERC721: Only contract addresses can use this function");
        require(msg.sender == address(_mintingCurrency), "QMSI-ERC721: Only the set currency can buy NFT on behalf of the user");
        _transfer(from, tokenId);
        _tokenPrices[tokenId] = 0;
        emit SoldNFT(idToOwner[tokenId], tokenId, from);
    }

    /**
     * @notice this string goes at the beginning of the tokenURI, if the contract owner chose to set a value for it.
     * @return a string of the base URI if there is one
     *
     */
    function baseURI() external view returns (string memory) {
        return _baseURIextended;
    }

    /**
     * @notice Purpose is to set the remote location of the JSON artifact
     * @param tokenId the id of the certificate
     * @return The remote location of the JSON artifact
     *
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(bytes(_tokenURIs[tokenId]).length > 0, "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURIextended;

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }

    /**
     * @notice Allows anybody to create a certificate, takes payment from the
     *   msg.sender. Can only be called by the mintingCurrency contract
     * @param dataHash A representation of the certificate data using the Aria
     *   protocol (a 0xcert cenvention).
     * @param tokenURI_ The (optional) remote location of the certificate's JSON artifact, represented by the dataHash
     * @param tokenPrice_ The (optional) price of the certificate in token currency in order for someone to buy it and transfer ownership of it
     * @param commission_ The (optional) percentage that the original minter will take each time the certificate is bought
     * @return The new certificate ID
     *
     */
    function create(bytes32 dataHash, string calldata tokenURI_, uint256 tokenPrice_, uint256 commission_, address minter_) external returns (uint) {
        require(_isContract(msg.sender) == true, "QMSI-ERC721: Only contract addresses can use this function");
        require(msg.sender == address(_mintingCurrency), "QMSI-ERC721: Only the set currency can create NFT on behalf of the user");

        // Set URI of token
        _setTokenURI(nextCertificateId, tokenURI_);

        // Set price of token (optional)
        _setTokenPrice(nextCertificateId, tokenPrice_);

        // Set token minter (the original artist)
        _setTokenMinter(nextCertificateId, minter_);
        _setTokenCommissionProperty(nextCertificateId, commission_);

        // Create the certificate
        uint256 newCertificateId = nextCertificateId;
        _mint(minter_, newCertificateId);
        certificateDataHashes[newCertificateId] = dataHash;
        nextCertificateId = nextCertificateId + 1;
        // Emit that we minted an NFT
        emit MintedNFT(minter_, newCertificateId);

        return newCertificateId;
    }
}