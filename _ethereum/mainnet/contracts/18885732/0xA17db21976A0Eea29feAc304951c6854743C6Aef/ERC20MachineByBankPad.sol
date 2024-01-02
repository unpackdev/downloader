// Sources flattened with hardhat v2.19.1 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/Context.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/access/Ownable.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC20/ERC20.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}


// File @openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/utils/Address.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
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


// File contracts/token/AntiBotHelper.sol

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice Anti-Bot Helper
 * Max TX Amount feature
 * Max Wallet Amount feature
 * Sniper auto-burn feature
 */
contract AntiBotHelper is Ownable {
    /// @dev Minimum limit that can be set for the max transaction limit - 0.5%
    uint16 private constant MIN_MAX_TX_LIMIT = 50;
    /// @dev Minimum limit that can be set for the max hold limit - 0.5%
    uint16 private constant MIN_MAX_HOLD_LIMIT = 50;

    /// @dev Anti-snipe tax is burned, reducing total supply
    /// 1. 20% tax on buys in the first block
    /// 2. Reducing to 13.33% in the second block
    /// 3. Reducing to 6.66% in the third
    /// 4. Finally 0% from the fourth block on
    uint16 private constant SNIPER_AUTO_BURN_FIRST_PERC = 2000;
    uint16 private constant SNIPER_AUTO_BURN_SECOND_PERC = 1333;
    uint16 private constant SNIPER_AUTO_BURN_THIRD_PERC = 666;

    uint16 internal _maxTxLimit;
    uint16 internal _maxHoldLimit;

    bool internal _isAntiSniperOn;
    bool internal _isTradingDelayed;
    bool internal _isTradingDisabled;

    uint256 internal _firstBuyAt;
    uint256 internal _secondBuyAt;
    uint256 internal _thirdBuyAt;

    mapping(address => bool) internal _isExcludedFromTxLimit;
    mapping(address => bool) internal _isExcludedFromHoldLimit;

    event ExcludedFromHoldLimit(address account, bool flag);
    event ExcludedFromTxLimit(address account, bool flag);
    event MaxLimitUpdated(uint16 maxHoldLimit, uint16 maxTxLimit);
    event TradingEnabled();

    constructor() {
        _isExcludedFromTxLimit[_msgSender()] = true;
        _isExcludedFromTxLimit[address(0)] = true;
        _isExcludedFromTxLimit[address(0xdead)] = true;
        _isExcludedFromTxLimit[address(this)] = true;

        _isExcludedFromHoldLimit[_msgSender()] = true;
        _isExcludedFromHoldLimit[address(0)] = true;
        _isExcludedFromHoldLimit[address(0xdead)] = true;
        _isExcludedFromHoldLimit[address(this)] = true;
    }

    /// @dev Initialize anti bot configuration
    /// abi encoded param
    /// 1. txLimit
    /// 2. holdLimit
    /// 3. antiSniperOn
    function _initializeAntiBot(bytes memory param) internal {
        (uint16 holdLimit, uint16 txLimit, bool antiSniperOn) = abi.decode(
            param,
            (uint16, uint16, bool)
        );
        require(txLimit >= MIN_MAX_TX_LIMIT, "tx limit too small");
        require(holdLimit >= MIN_MAX_HOLD_LIMIT, "hold limit too small");
        require(txLimit <= holdLimit, "tx limit exceeds hold limit");

        _maxTxLimit = txLimit;
        _maxHoldLimit = holdLimit;
        _isAntiSniperOn = antiSniperOn;
    }

    /// @dev Return anti-sniper auto-burn percent
    function _antiSniperAutoBurn() internal returns (uint16) {
        if (!_isAntiSniperOn) return 0;
        uint256 blockTime = block.timestamp;
        if (blockTime == _thirdBuyAt) return SNIPER_AUTO_BURN_THIRD_PERC;
        if (blockTime == _secondBuyAt) return SNIPER_AUTO_BURN_SECOND_PERC;
        if (blockTime == _firstBuyAt) return SNIPER_AUTO_BURN_FIRST_PERC;
        if (_thirdBuyAt > 0) return 0;
        if (_secondBuyAt > 0) {
            _thirdBuyAt = block.timestamp;
            return SNIPER_AUTO_BURN_THIRD_PERC;
        }
        if (_firstBuyAt > 0) {
            _secondBuyAt = block.timestamp;
            return SNIPER_AUTO_BURN_SECOND_PERC;
        }
        _firstBuyAt = block.timestamp;
        return SNIPER_AUTO_BURN_FIRST_PERC;
    }

    /// @notice Exclude / Include the multiple accounts from max tx limit
    /// @dev Only callable by owner
    function batchExcludeFromTxLimit(
        address[] calldata accounts,
        bool flag
    ) external onlyOwner {
        uint256 len = accounts.length;
        for (uint256 i; i < len; ) {
            address account = accounts[i];
            _isExcludedFromTxLimit[account] = flag;

            unchecked {
                ++i;
            }

            emit ExcludedFromTxLimit(account, flag);
        }
    }

    /// @notice Exclude / Include the multiple accounts from max wallet limit
    /// @dev Only callable by owner
    function batchExcludeFromHoldLimit(
        address[] calldata accounts,
        bool flag
    ) external onlyOwner {
        uint256 len = accounts.length;
        for (uint256 i; i < len; ) {
            address account = accounts[i];
            _isExcludedFromHoldLimit[account] = flag;

            unchecked {
                ++i;
            }

            emit ExcludedFromHoldLimit(account, flag);
        }
    }

    /// @notice Check if the account is excluded from max hold & wallet limit
    /// @return bool excluded from max hold limit
    /// @return bool excluded from max tx limit
    function isExcludedFromLimit(
        address account
    ) external view returns (bool, bool) {
        return (
            _isExcludedFromHoldLimit[account],
            _isExcludedFromTxLimit[account]
        );
    }

    /// @notice Update max hold limit & max tx limit
    /// @param holdLimit new max hold limit
    /// @param txLimit new max tx limit
    function updateMaxLimit(
        uint16 holdLimit,
        uint16 txLimit
    ) external onlyOwner {
        require(holdLimit >= txLimit, "tx limit exceeds hold limit");
        require(
            _maxHoldLimit <= holdLimit && _maxTxLimit <= txLimit,
            "increase only"
        );

        _maxHoldLimit = holdLimit;
        _maxTxLimit = txLimit;

        emit MaxLimitUpdated(holdLimit, txLimit);
    }

    /// @notice View max hold limit & max tx limit
    /// @return uint16 max hold limit percent
    /// @return uint16 max tx limit percent
    function viewMaxLimit() external view returns (uint16, uint16) {
        return (_maxHoldLimit, _maxTxLimit);
    }

    /// @notice Enable trading
    function enableTrading() external onlyOwner {
        require(_isTradingDisabled, "already enabled");
        _isTradingDisabled = false;

        emit TradingEnabled();
    }

    /// @notice View anti-bot mechanism flags
    /// @return bool {_isAntiSniperOn}
    /// @return bool {_isTradingDelayed}
    /// @return bool {_isTradingDisabled}
    function viewAntiBotFlags() external view returns (bool, bool, bool) {
        return (_isAntiSniperOn, _isTradingDelayed, _isTradingDisabled);
    }
}


// File contracts/interfaces/IBase.sol

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.4;

interface IBase {
    /// - antiBotParam
    /// 1. holdLimit
    /// 2. txLimit
    /// 3. antiSniperOn
    ///
    /// - taxParam
    /// 1. dexRouter: uniswap or sushiswap
    /// 2. pairedToken: eth or usdc
    /// 3. taxPayAccount
    /// 4. treasuryAccount
    /// 5. buyTax
    /// 6. sellTax
    /// 7. treasuryTax
    ///
    /// - distribParam
    /// 1. totalSupply
    /// 2. teamAccount
    /// 3. teamAllocPercent
    ///
    /// - lpParam
    /// 1. isLPBurn
    /// 2. isTradingDelayed
    /// 3. isTradingDisabled
    /// 4. pairedTokenAmount
    /// 5. lockPeriod
    struct TokenLaunchConf {
        string uuid;
        string name;
        string symbol;
        bytes distribParam;
        bytes antiBotParam;
        bytes taxParam;
        bytes lpParam;
    }
}


// File contracts/interfaces/IERC20FactoryByBankPad.sol

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20FactoryByBankPad {
    function viewServicePayAccount() external view returns (address payable);

    function viewLPLocker() external view returns (address);

    function viewDelayedTradingFee() external view returns (uint256);

    function viewLaunchFee() external view returns (uint256);
}


// File contracts/interfaces/IDexRouter.sol

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.4;

interface IDexFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

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

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}


// File contracts/token/TaxHelper.sol

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @notice Tax Helper
 * Marketing fee
 * Burn fee
 * Fee in buy/sell/transfer separately
 */
contract TaxHelper is Ownable {
    using Address for address payable;

    /// @dev Max buy tax
    uint16 private constant MAX_BUY_TAX = 3500;
    /// @dev Max sell tax
    uint16 private constant MAX_SELL_TAX = 3500;
    /// @dev Max treasury tax
    uint16 private constant MAX_TREASURY_TAX = 500;
    /// @dev Ownership can be renounced only when buy/sell tax is less than 5%
    uint16 internal constant MAX_TAX_BEFORE_RENOUNCE = 500;
    /// @dev Bankpad tax is sset on top buy / sell tax as a service fee - 10% of buy / sell tax
    uint16 internal constant BANKPAD_TAX = 1000;
    /// @dev Bankpad tax is removed 15 days after token launches
    uint256 internal constant BANKPAD_TAX_PERIOD = 15 days;
    /// @dev Whitelist (exclude list) is not applied within 2 days after token launches
    uint256 internal constant WHITELIST_DELAY = 2 days;

    address internal constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    bool internal _bankpadFeeApplied = true;
    uint16 internal _buyTax;
    uint16 internal _sellTax;
    uint16 internal _treasuryTax;

    address internal _dexRouter;
    address internal _taxPayAccount;
    address internal _treasuryAccount;
    address internal _baseAmmPair;
    address internal _basePairedToken;

    mapping(address => bool) internal _isExcludedFromTax;
    mapping(address => bool) internal _isAmmPair;

    event ExcludedFromTax(address account, bool flag);
    event NewAmmPair(address pair, bool flag);
    event TaxesUpdated(uint16 buyTax, uint16 sellTax, uint16 treasuryTax);

    constructor() {
        _isExcludedFromTax[_msgSender()] = true;
        _isExcludedFromTax[address(0)] = true;
        _isExcludedFromTax[address(0xdead)] = true;
        _isExcludedFromTax[address(this)] = true;
    }

    /// @dev Initialize tax configuration
    /// abi encoded param
    /// 1. dexRouter: uniswap or sushiswap
    /// 2. pairedToken: eth or usdc
    /// 3. taxPayAccount
    /// 4. buyTax
    /// 5. sellTax
    function _initializeTax(bytes memory param) internal {
        (
            address dexRouter,
            address pairedToken,
            address taxPayAccount,
            address treasuryAccount,
            uint16 buyTax,
            uint16 sellTax,
            uint16 treasuryTax
        ) = abi.decode(
                param,
                (address, address, address, address, uint16, uint16, uint16)
            );
        require(
            buyTax <= MAX_BUY_TAX &&
                sellTax <= MAX_SELL_TAX &&
                treasuryTax <= MAX_TREASURY_TAX,
            "too much tax"
        );

        require(
            taxPayAccount != address(0) && treasuryAccount != address(0),
            "invalid pay account"
        );
        // check if tax pay account and treasury account can receive ETH when the base pair token is ETH
        if (pairedToken == ETH_ADDRESS) {
            payable(taxPayAccount).sendValue(0);
            payable(treasuryAccount).sendValue(0);
        }

        _dexRouter = dexRouter;
        // pair with ETH or any other stable coin
        address lpPair = IDexFactory(IDexRouter(dexRouter).factory())
            .createPair(
                address(this),
                pairedToken == ETH_ADDRESS
                    ? IDexRouter(dexRouter).WETH()
                    : pairedToken
            );

        _baseAmmPair = lpPair;
        _basePairedToken = pairedToken;
        _taxPayAccount = taxPayAccount;
        _treasuryAccount = treasuryAccount;

        _buyTax = buyTax;
        _sellTax = sellTax;
        _treasuryTax = treasuryTax;

        _isAmmPair[lpPair] = true;
    }

    /// @notice Update buy / sell / treasury tax
    /// @dev Max buy tax 35%, max sell tax 35%, max treasury tax 5%
    /// @dev Tax values should be decreased only
    /// @param buyTax new buy tax value
    /// @param sellTax new sell tax value
    /// @param treasuryTax new treasury tax value
    function updateTaxes(
        uint16 buyTax,
        uint16 sellTax,
        uint16 treasuryTax
    ) external onlyOwner {
        require(
            _buyTax >= buyTax &&
                _sellTax >= sellTax &&
                _treasuryTax >= treasuryTax,
            "decrease only"
        );
        _buyTax = buyTax;
        _sellTax = sellTax;
        _treasuryTax = treasuryTax;

        emit TaxesUpdated(buyTax, sellTax, treasuryTax);
    }

    /// @notice View taxes applied to the token
    /// @return uint16 {_buyTax}
    /// @return uint16 {_sellTax}
    /// @return uint16 {_treasuryTax}
    function viewTaxes() external view returns (uint16, uint16, uint16) {
        return (_buyTax, _sellTax, _treasuryTax);
    }

    /// @notice Exclude / Include the multiple accounts from tax
    /// @dev Only callable by owner
    function batchExcludeFromTax(
        address[] calldata accounts,
        bool flag
    ) external onlyOwner {
        uint256 len = accounts.length;
        for (uint256 i; i < len; ) {
            address account = accounts[i];
            _isExcludedFromTax[account] = flag;

            unchecked {
                ++i;
            }

            emit ExcludedFromTax(account, flag);
        }
    }

    /// @notice Check if the account is excluded from the fees
    /// @param account: the account to be checked
    function isExcludedFromTax(address account) external view returns (bool) {
        return _isExcludedFromTax[account];
    }

    /// @notice Check if the {pair} is AMM pair
    function isAmmPair(address pair) external view returns (bool) {
        return _isAmmPair[pair];
    }

    /// @notice View tax receive accounts
    /// @return address buy/sell tax pay account
    /// @return address treasury tax pay account
    function viewTaxAccounts() external view returns (address, address) {
        return (_taxPayAccount, _treasuryAccount);
    }

    /// @notice View amm related configuration addresses
    /// @return address dex router address
    /// @return address base paired token address
    /// @return address base pair address from the dex router
    function viewAmmAddresses()
        external
        view
        returns (address, address, address)
    {
        return (_dexRouter, _basePairedToken, _baseAmmPair);
    }
}


// File contracts/util/Revert.sol

pragma solidity ^0.8.0;

// Original license: SPDX_License_Identifier: MIT

/**
 *
 * @title Revert.sol. For efficient reverts
 *
 *
 */

abstract contract Revert {
  /**
   * @dev For more efficient reverts.
   */
  function _revert(bytes4 errorSelector) internal pure {
    assembly {
      mstore(0x00, errorSelector)
      revert(0x00, 0x04)
    }
  }
}


// File contracts/token/ERC20ByBankPad.sol

pragma solidity ^0.8.0;

// Original license: SPDX_License_Identifier: MIT






contract ERC20ByBankPad is IBase, AntiBotHelper, ERC20, TaxHelper {
    bytes32 public constant BANK_UUID_HASH =
        0x4D45544144524F504D45544144524F504D45544144524F504D45544144524F50;

    using Address for address payable;
    using SafeERC20 for IERC20;

    address public immutable factory;

    uint16 private constant DENOMINATOR = 10000;

    /// @dev Max team distribution rate 10%
    uint16 private constant MAX_TEAM_ALLOC = 1000;

    bool private _isLaunched;
    bool private _inSwap;
    bool private _isTaxConvertEnabled = true;

    /// @dev Token transfer is disabled for 1 mins once trading_delay flag is set
    uint256 private constant AUTO_TRADING_DELAY_TIME = 1 minutes;
    /// @dev Trading is disabled once {_isTradingDisabled} flag is set,
    /// it is unset automatically after 4 days if owner does not enable trading
    uint256 private constant AUTO_TRADING_ENABLE_TIME = 4 days;

    /// @dev Threshold amount of accumlated tax until swap to pair token
    uint256 private _thresholdAmount = 10000 ether;

    /// @dev Token launched time
    uint256 private _launchedAt;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyFactory() {
        require(factory == _msgSender(), "caller is not the factory");
        _;
    }

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor(
        address factory_,
        address deployer_,
        TokenLaunchConf memory param_
    ) ERC20(param_.name, param_.symbol) {
        factory = factory_;

        _initializeAntiBot(param_.antiBotParam);
        _initializeTax(param_.taxParam);
        _isExcludedFromHoldLimit[_baseAmmPair] = true;

        (uint256 supply, address teamAccount, uint16 teamAlloc) = abi.decode(
            param_.distribParam,
            (uint256, address, uint16)
        );

        // Distribute to team
        if (teamAlloc > 0) {
            require(teamAccount != address(0), "invalid team account");
            require(teamAlloc <= MAX_TEAM_ALLOC, "too much team alloc");
            uint256 teamAllocAmount = (supply * teamAlloc) / DENOMINATOR;
            _mint(teamAccount, teamAllocAmount);
            supply -= teamAllocAmount;
        }

        // Mint rest tokens to the factory contract to add liquidity
        _mint(factory_, supply);
        _transferOwnership(deployer_);
    }

    /// @notice End initialization of the token contract
    /// @dev Token is launched from this moment, and users can start trading
    /// @param tradingDelayed Once this flag is set, trading is delayed for 1 min
    /// @param tradingDisabled Once this flag is set, trading is disabled until it is set or 4 days
    function launch(
        bool tradingDelayed,
        bool tradingDisabled
    ) external onlyFactory {
        require(!_isLaunched, "already launched");
        _isLaunched = true;
        // trading delay flag and trading disable flag can not set at the same time
        require(
            !tradingDelayed || !tradingDisabled,
            "can not delayed and disabled"
        );

        _isTradingDelayed = tradingDelayed;
        _isTradingDisabled = tradingDisabled;
        _launchedAt = block.timestamp;
    }

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
    ) internal virtual override {
        if (!_isLaunched) return;

        uint256 totalSupply_ = totalSupply();

        // Check max tx limit
        require(
            _isExcludedFromTxLimit[from] ||
                _isExcludedFromTxLimit[to] ||
                amount <= (totalSupply_ * _maxTxLimit) / DENOMINATOR,
            "tx amount limited"
        );

        // Check max wallet amount limit
        require(
            _isExcludedFromHoldLimit[to] ||
                balanceOf(to) <= (totalSupply_ * _maxHoldLimit) / DENOMINATOR,
            "receiver hold limited"
        );
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 blockTime = block.timestamp;
        if (
            _isTradingDelayed &&
            blockTime < _launchedAt + AUTO_TRADING_DELAY_TIME
        ) revert("trading delayed");

        if (_isTradingDisabled) {
            if (blockTime < _launchedAt + AUTO_TRADING_ENABLE_TIME)
                revert("trading disabled");
            // enable trading after 4 days
            _isTradingDisabled = false;
            emit TradingEnabled();
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        // tax whitelist is only applied after 2 days of the first buy
        bool isWhitelisted = (_isExcludedFromTax[from] ||
            _isExcludedFromTax[to]) &&
            _firstBuyAt > 0 &&
            blockTime >= _firstBuyAt + WHITELIST_DELAY;
        bool isBuyTx = _isAmmPair[from];
        bool isSellTx = _isAmmPair[to];

        // swap accumlated tax into ETH or USDC
        if (
            !_inSwap &&
            !isWhitelisted &&
            !isBuyTx &&
            _isTaxConvertEnabled &&
            contractTokenBalance >= _thresholdAmount
        ) {
            // although the bankpad tax period is finished, there may still be accumulated taxes thus far.
            // in this case, we will swap all those taxes into ETH / USDC.
            bool isBankpadOverTime = _bankpadFeeApplied &&
                _firstBuyAt > 0 &&
                blockTime > _firstBuyAt + BANKPAD_TAX_PERIOD;
            // when the bankpad fee period is over, swap all accumlated taxes
            if (isBankpadOverTime) _swapToPairedToken(contractTokenBalance);
            else _swapToPairedToken(_thresholdAmount);
            if (isBankpadOverTime) _bankpadFeeApplied = false;
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 fees;
        if (!isWhitelisted && _isLaunched) {
            if (isBuyTx) {
                // bankpad tax is applied on top of buy tax for 15 days
                // its 10% of buy tax
                if (
                    _bankpadFeeApplied &&
                    (_firstBuyAt == 0 ||
                        blockTime <= _firstBuyAt + BANKPAD_TAX_PERIOD)
                )
                    fees =
                        (amount *
                            (_buyTax + _treasuryTax) *
                            (DENOMINATOR + BANKPAD_TAX)) /
                        DENOMINATOR /
                        DENOMINATOR;
                else fees = (amount * (_buyTax + _treasuryTax)) / DENOMINATOR;

                // for the first buy txs, anti sniper auto-burn is applied
                // this is applied for 3 blocks
                uint256 autoBurnPerc = _antiSniperAutoBurn();

                if (autoBurnPerc > 0) {
                    uint256 autoBurnAmount = (amount * autoBurnPerc) /
                        DENOMINATOR;
                    _burn(from, autoBurnAmount);

                    amount -= autoBurnAmount;
                }
            } else if (isSellTx) {
                // bankpad tax is applied on top of sell tax for 15 days
                // its 10% of buy tax
                if (
                    _bankpadFeeApplied &&
                    (_firstBuyAt == 0 ||
                        blockTime <= _firstBuyAt + BANKPAD_TAX_PERIOD)
                )
                    fees =
                        (amount *
                            (_sellTax + _treasuryTax) *
                            (DENOMINATOR + BANKPAD_TAX)) /
                        DENOMINATOR /
                        DENOMINATOR;
                else fees = (amount * (_sellTax + _treasuryTax)) / DENOMINATOR;
            }

            if (fees > 0) super._transfer(from, address(this), fees);
            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    /**
     * @dev Swap token accumlated in this contract to the base paired token
     * 
     * According to the paired token

     * - when paired token is ETH, swapToETH function is called
     * - when paired token is another token, swapToToken is called

     */
    function _swapToPairedToken(uint256 amount) private lockTheSwap {
        address basePairedToken_ = _basePairedToken;
        address payable servicePayAccount = IERC20FactoryByBankPad(factory)
            .viewServicePayAccount();
        if (basePairedToken_ == ETH_ADDRESS) {
            uint256 swappedAmount = _swapToETH(amount);
            if (swappedAmount > 0) {
                // send bankpad fee
                if (_bankpadFeeApplied) {
                    uint256 bankpadFeeAmount = _calcBankpadFee(swappedAmount);
                    servicePayAccount.sendValue(bankpadFeeAmount);
                    swappedAmount -= bankpadFeeAmount;
                }
                // send treasury tax
                if (_treasuryTax > 0) {
                    uint256 treasuryFeeAmount = _calcTreasuryFee(swappedAmount);
                    payable(_treasuryAccount).sendValue(treasuryFeeAmount);
                    swappedAmount -= treasuryFeeAmount;
                }
                // send buy/sell tax
                payable(_taxPayAccount).sendValue(swappedAmount);
            }
        } else {
            uint256 swappedAmount = _swapToToken(basePairedToken_, amount);
            if (swappedAmount > 0) {
                // send bankpad fee
                if (_bankpadFeeApplied) {
                    uint256 bankpadFeeAmount = _calcBankpadFee(swappedAmount);
                    IERC20(basePairedToken_).safeTransfer(
                        servicePayAccount,
                        bankpadFeeAmount
                    );
                    swappedAmount -= bankpadFeeAmount;
                }
                // send treasury tax
                if (_treasuryTax > 0) {
                    uint256 treasuryFeeAmount = _calcTreasuryFee(swappedAmount);
                    IERC20(basePairedToken_).safeTransfer(
                        _treasuryAccount,
                        treasuryFeeAmount
                    );
                    swappedAmount -= treasuryFeeAmount;
                }

                IERC20(basePairedToken_).safeTransfer(
                    _taxPayAccount,
                    swappedAmount
                );
            }
        }
    }

    /// @dev Calculate bankpad fee amount from the swapped total tax amount
    function _calcBankpadFee(
        uint256 swappedAmount
    ) private pure returns (uint256) {
        return (swappedAmount * BANKPAD_TAX) / (DENOMINATOR + BANKPAD_TAX);
    }

    /// @dev Calculate treasury fee amount from the swapped tax amount
    function _calcTreasuryFee(
        uint256 swappedAmount
    ) private view returns (uint256) {
        // gas-saving codes
        uint16 buyTax_ = _buyTax;
        uint16 sellTax_ = _sellTax;
        uint16 treasuryTax_ = _treasuryTax;

        return
            (swappedAmount * 2 * treasuryTax_) /
            (buyTax_ + sellTax_ + 2 * treasuryTax_);
    }

    function _swapToToken(
        address token,
        uint256 amount
    ) private returns (uint256) {
        // generate the uniswap pair path of token -> stable coin
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = token;

        IDexRouter dexRouter_ = IDexRouter(_dexRouter);
        _approve(address(this), address(dexRouter_), amount);
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        // make the swap
        try
            dexRouter_.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0, // accept any amount of tokens
                path,
                address(this),
                block.timestamp + 300
            )
        {
            return IERC20(token).balanceOf(address(this)) - balanceBefore;
        } catch (bytes memory /* lowLevelData */) {}
        return 0;
    }

    function _swapToETH(uint256 amount) private returns (uint256) {
        IDexRouter dexRouter_ = IDexRouter(_dexRouter);
        // generate the uniswap pair path of token -> eth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter_.WETH();

        _approve(address(this), address(dexRouter_), amount);
        uint256 balanceBefore = address(this).balance;
        // make the swap
        try
            dexRouter_.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp + 300
            )
        {
            return address(this).balance - balanceBefore;
        } catch (bytes memory /* lowLevelData */) {}
        return 0;
    }

    /// @notice Renounce ownership of the token contract
    /// @dev Only available when buy/sell tax is less than 5% and no tx / hold limit
    function renounceOwnership() public override onlyOwner {
        require(
            _buyTax <= MAX_TAX_BEFORE_RENOUNCE &&
                _sellTax <= MAX_TAX_BEFORE_RENOUNCE &&
                _treasuryTax <= MAX_TAX_BEFORE_RENOUNCE,
            "too much tax"
        );
        require(
            _maxHoldLimit == 10000 && _maxTxLimit == 10000,
            "still limited"
        );
        super.renounceOwnership();
    }

    /// @notice Enable conversion of token tax
    function enableTaxConvert(bool flag) external onlyOwner {
        _isTaxConvertEnabled = flag;
    }

    function isTaxConvertEnabled() external view returns (bool) {
        return _isTaxConvertEnabled;
    }

    /// @notice Update the threshold amount for the swapping to occur
    /// @dev Too small value will cause sell tx happens in every tx
    function updateThresholdAmount(uint256 amount) external onlyOwner {
        require(amount > 0, "invalid threshold");
        _thresholdAmount = amount;
    }

    function viewThresholdAmount() external view returns (uint256) {
        return _thresholdAmount;
    }

    function viewLaunchedAt() external view returns (uint256) {
        return _launchedAt;
    }

    /// @notice Set / unset multiple pair addresses as AMM pair
    function batchSetAsAmmPair(
        address[] calldata pairs,
        bool flag
    ) external onlyOwner {
        uint256 len = pairs.length;

        for (uint256 i; i < len; ) {
            address pair = pairs[i];
            require(pair != _baseAmmPair, "can not access base amm pair");
            _isAmmPair[pair] = flag;
            _isExcludedFromHoldLimit[pair] = flag;

            unchecked {
                ++i;
            }

            emit NewAmmPair(pair, flag);
        }
    }

    receive() external payable {}

    /**
     * @dev It allows the admin to recover tokens sent to the contract
     * @param token_: the address of the token to withdraw
     * @param amount_: the number of tokens to withdraw
     *
     * This function is only callable by owner
     */
    function recoverToken(address token_, uint256 amount_) external onlyOwner {
        require(token_ != address(this), "Not allowed token");
        IERC20(token_).safeTransfer(_msgSender(), amount_);
    }
}


// File contracts/token/ERC20MachineByBankPad.sol

pragma solidity ^0.8.0;

// Original license: SPDX_License_Identifier: MIT


/**
 * @dev BankPad ERC-20 contract deployer
 *
 *
 * Lightweight deployment module for use with template contracts
 */
contract ERC20MachineByBankPad is Context {
    address public immutable factory;
    uint256 public immutable bytesStartPosition;

    /**
     * @dev {constructor}
     *
     * @param factory_ Address of the factory
     */
    constructor(address factory_) {
        factory = factory_;

        (
            bool validStartPosition,
            uint256 startPosition
        ) = getBytesStartPosition();

        if (!validStartPosition) {
            revert("deployment error");
        }
        bytesStartPosition = startPosition;
    }

    /**
     * @dev {onlyFactory}
     *
     * Throws if called by any account other than the factory.
     */
    modifier onlyFactory() {
        if (factory != _msgSender()) {
            revert("caller is not factory");
        }
        _;
    }

    /**
     * @dev function {deploy} Deploy a fresh instance
     *
     * @param bankIdHash The hash of this token deployment identifier
     * @param salt Provided sale for create2
     * @param args Constructor arguments
     */
    function deploy(
        bytes32 bankIdHash,
        bytes32 salt,
        bytes memory args
    ) external payable onlyFactory returns (address erc20ContractAddress) {
        // First check the bankIdHash_ is valid:
        if (_startsWithEmptyByte(bankIdHash)) revert("invalid hash");

        // 1) Get the deployment bytecode:
        bytes memory deploymentBytecode = type(ERC20ByBankPad).creationCode;

        uint256 startPositionInMemoryForAssembly = bytesStartPosition;

        // 2) Modify the bytecode, replacing the default bankIdHash with the received value.
        // This allows us to verify the contract code (with comments) for every token,
        // rather than matching the deployed code (and comments) of previous tokens.
        assembly {
            // Define the start position
            let start := add(
                deploymentBytecode,
                startPositionInMemoryForAssembly
            )

            // Copy the bytes32 value to the specified position
            mstore(add(start, 0x20), bankIdHash)
        }
        // 3) Add the args to the bytecode:
        bytes memory deploymentData = abi.encodePacked(
            deploymentBytecode,
            args
        );

        // 4) Deploy it:
        assembly {
            erc20ContractAddress := create2(
                0,
                add(deploymentData, 0x20),
                mload(deploymentData),
                salt
            )
            if iszero(extcodesize(erc20ContractAddress)) {
                revert(0, 0)
            }
        }
    }

    /**
     * @dev function {_startsWithEmptyByte} Does the passed hash start with
     * an empty byte?
     *
     * @param hash_ The bytes32 hash
     * @return bool The hash does / doesn't start with an empty tybe
     */
    function _startsWithEmptyByte(bytes32 hash_) internal pure returns (bool) {
        return bytes1(hash_) == 0x00;
    }

    /**
     * @dev function {getBytesStartPosition} Get the replacement bytes start position
     *
     * @return found_ If the bytes have been found
     * @return startPosition_ The start position of the bytes
     */
    function getBytesStartPosition()
        public
        pure
        returns (bool found_, uint256 startPosition_)
    {
        bytes
            memory bytesTarget = hex"4D45544144524F504D45544144524F504D45544144524F504D45544144524F50";
        bytes memory deploymentCode = type(ERC20ByBankPad).creationCode;

        // Iterate through the bytecode to find the search bytes.
        // Start at a reasonable position: byte 5000
        for (
            uint256 i = 5000;
            i < deploymentCode.length - bytesTarget.length + 1;
            i += 1
        ) {
            bool found = true;

            // Check if the current chunk matches the search string
            for (uint256 j = 0; j < bytesTarget.length; j++) {
                if (deploymentCode[i + j] != bytesTarget[j]) {
                    found = false;
                    break;
                }
            }

            if (found) {
                return (true, i);
            }
        }

        return (false, 0);
    }
}