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


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: node_modules\@uniswap\v2-periphery\contracts\interfaces\IUniswapV2Router01.sol

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

// File: @uniswap\v2-periphery\contracts\interfaces\IUniswapV2Router02.sol

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

// File: contracts\GoaldProxy.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;




interface IGoaldProxy {
    /** Returns the current address that fees will be sent to. */
    function getProxyAddress() external view returns (address);
}

contract GoaldProxy is ERC20 {
    /** 
     * @dev The minimum amount of tokens necessary to be eligible for a reward. This is "one token", considering decimal places. We
     * are choosing two decimal places because we are initially targeting WBTC, which has 8. This way we can do a minimum reward ratio
     * of 1 / 1,000,000 of a WBTC, relative to our token. So at $25,000 (2020 value), the minimum reward would be $250 (assuming we
     * have issued all 10,000 tokens).
     */
    uint256 private constant REWARD_THRESHOLD = 10*2;

    /** @dev The current owner of the proxy. */
    address public  _owner = msg.sender;

    /** @dev Which Uniswap router we're currently using for trades. */
    address private _uniswapRouterAddress;

    /** @dev The latest proxy address. This is private since Goald contracts use `getProxyAddress()` to determine the address. */
    address private _proxyAddress = address(this);

    /** @dev The address of the token that will be used as a liquidity intermediary within Uniswap for indirect swaps (e.g., WETH). */
    address private _intermediaryToken;

    /** @dev The base token URI for the Goald metadata. */
    string  private _baseTokenURI;


    /** @dev Which deployers are allowed to create new Goalds. We use a mapping for O(1) lookups and an array for complete list. */
    mapping (address => bool) private _allowedDeployersMap;
    address[] private _allowedDeployersList;

    /** @dev The addresses of all deployed goalds. */
    address[] private _deployedGoalds;

    /** @dev The owner of each deployed goald. */
    address[] private _goaldOwners;


    /** @dev Which ERC20 contract will be used for rewards (e.g., WBTC). */
    address   private _rewardToken;

    /** @dev How many holders are eligible for rewards. This is used to determine how much should be reserved. */
    uint256   private _rewardHolders;

    /** @dev How much of the current balance is reserved for rewards. */
    uint256   private _reservedRewardBalance;

    /** @dev How many holders have yet to withdraw a given reward. */
    uint256[] private _rewardHolderCounts;

    /** @dev The multipliers for each reward. */
    uint256[] private _rewardMultipliers;

    /** @dev The remaining reserves for a given reward. */
    uint256[] private _rewardReserves;

    /** @dev The minimum reward index to check eligibility against for a given address. */
    mapping (address => uint256) private _minimumRewardIndex;
    
    /** @dev The available reward balance for a given address. */
    mapping (address => uint256) private _rewardBalance;

    /**
     * @dev The stage of the governance token. Tokens can be issued based on deployments regardless of what stage we are in.
     *      0: Created, with no governance protocol initiated. The initial governance issuance can be claimed.
     *      1: Initial governance issuance has been claimed.
     *      2: The governance protocal has been initiated.
     *      3: All governance tokens have been issued.
     */
    uint256 private constant STAGE_INITIAL               = 0;
    uint256 private constant STAGE_ISSUANCE_CLAIMED      = 1;
    uint256 private constant STAGE_DAO_INITIATED         = 2;
    uint256 private constant STAGE_ALL_GOVERNANCE_ISSUED = 3;
    uint256 private _governanceStage;

    // Reentrancy reversions are the only calls to revert (in this contract) that do not have reasons. We add a third state, 'frozen'
    // to allow for locking non-admin functions. The contract may be permanently frozen if it has been upgraded.
    uint256 private constant RE_NOT_ENTERED = 1;
    uint256 private constant RE_ENTERED     = 2;
    uint256 private constant RE_FROZEN      = 3;
    uint256 private _status;

    // Override decimal places to 2. See `REWARD_THRESHOLD`.
    constructor() ERC20("Goald", "GOALD") public {
        _setupDecimals(2);
        _status = RE_NOT_ENTERED;
        _proxyAddress = address(this);
    }

    /// Events ///

    event OwnerChanged(uint256 id, address owner);

    event RewardCreated(uint256 multiplier, string reason);

    /// Admin Functions ///

    /** Adds an allowed deployer. */
    function addAllowedDeployer(address newDeployer) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED || _status == RE_FROZEN);
        require(msg.sender == _owner,               "Not owner");
        require(!_allowedDeployersMap[newDeployer], "Already allowed");

        // Add the deployer.
        _allowedDeployersMap[newDeployer] = true;
        _allowedDeployersList.push(newDeployer);
    }

    /** Freezes the proxy contract. Only admin functions can be called. */
    function freeze() external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED);
        require(msg.sender == _owner, "Not owner");

        _status = RE_FROZEN;
    }

    /** Removes an allowed deployer by index. We require the index for no-traversal removal against a known address. */
    function removeAllowedDeployer(address deployerAddress, uint256 index) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED || _status == RE_FROZEN);
        require(msg.sender == _owner,                 "Not owner");
        require(index < _allowedDeployersList.length, "Out of bounds");

        // Check the address.
        address indexAddress = _allowedDeployersList[index];
        require(indexAddress == deployerAddress,       "Address mismatch");
        require(_allowedDeployersMap[deployerAddress], "Already restricted");

        // Remove the deployer.
        _allowedDeployersMap[deployerAddress] = false;
        _allowedDeployersList[index] = _allowedDeployersList[index - 1];
        _allowedDeployersList.pop();
    }

    /** Sets the base url for Goald metadata. */
    function setBaseTokenURI(string calldata baseTokenURI) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED || _status == RE_FROZEN);
        require(msg.sender == _owner, "Not owner");

        _baseTokenURI = baseTokenURI;
    }

    function setOwner(address newOwner) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED || _status == RE_FROZEN);
        require(msg.sender == _owner,   "Not owner");
        require(newOwner != address(0), "Can't be zero address");

        _owner = newOwner;
    }

    /** The proxy address is what the Goald deployers send their fees to. */
    function setProxyAddress(address newAddress) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED || _status == RE_FROZEN);
        require(msg.sender == _owner,     "Not owner");
        require(newAddress != address(0), "Can't be zero address");
        require(IGoaldProxy(newAddress).getProxyAddress() == newAddress);

        _proxyAddress = newAddress;
    }

    /** The uniswap router for converting tokens within this proxys. */
    function setUniswapRouterAddress(address newAddress) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED || _status == RE_FROZEN);
        require(msg.sender == _owner,     "Not owner");
        require(newAddress != address(0), "Can't be zero address");

        _uniswapRouterAddress = newAddress;
    }

    /** Unfreezes the proxy contract. Non-admin functions can again be called. */
    function unfreeze() external {
        // Reentrancy guard.
        require(_status == RE_FROZEN);
        require(msg.sender == _owner, "Not owner");

        _status = RE_NOT_ENTERED;
    }

    /// Goald Deployers ///

    /** Returns the address of the deployer at the specified index. */
    function getDeployerAt(uint256 index) external view returns (address) {
        return _allowedDeployersList[index];
    }

    /** Returns the address and owner of the Goald at the specified index. */
    function getGoaldAt(uint256 index) external view returns (address[2] memory) {
        return [_deployedGoalds[index], _goaldOwners[index]];
    }

    /** Gets the token that is used as an intermediary in Uniswap swaps for token pairs that have insufficient liquidity. */
    function getIntermediaryToken() external view returns (address) {
        return _intermediaryToken;
    }

    /** Returns the next Goald id so that we have a unique ID for each NFT, regardless of which deployer was used. */
    function getNextGoaldId() external view returns (uint256) {
        return _deployedGoalds.length + 1;
    }

    /** Returns the current address that fees will be sent to. */
    function getProxyAddress() external view returns (address) {
        return _proxyAddress;
    }

    /** Return the metadata for a specific Goald. */
    function getTokenURI(uint256 tokenId) external view returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        uint256 temp = tokenId;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = tokenId;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }

        return string(abi.encodePacked(_baseTokenURI, string(buffer)));
    }

    /** Returns the address of the uniswap router. */
    function getUniswapRouterAddress() external view returns (address) {
        return _uniswapRouterAddress;
    }

    /** Returns if the address is an allowed deployer. */
    function isAllowedDeployer(address deployer) external view returns (bool) {
        return _allowedDeployersMap[deployer];
    }

    /**
     * Called when a deployer deploys a new Goald. Currently we use this to distribute the governance token according to the following
     * schedule. An additional 12,000 tokens will be claimable by the deployer of this proxy. This will create a total supply of
     * 21,000 tokens. Once the governance protocal is set up, 11,000 tokens will be burned to initiate that mechanism. That will leave
     * 10% ownership for the deployer of the contract, with the remaining 90% disbused on Goald creations. No rewards can be paid out
     * before the governance protocal has been initiated.
     *
     *      # Goalds    # Tokens
     *       0 -  9       100
     *      10 - 19        90
     *      20 - 29        80
     *      30 - 39        70
     *      40 - 49        60
     *      50 - 59        50
     *      60 - 69        40
     *      70 - 79        30
     *      80 - 89        20
     *      90 - 99        10
     *       < 3600         1
     */
    function notifyGoaldCreated(address creator, address goaldAddress) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED);
        require(_allowedDeployersMap[msg.sender], "Not allowed deployer");
        require(_proxyAddress == address(this),   "Not latest proxy");

        // All governance tokens have been issued.
        if (_governanceStage == STAGE_ALL_GOVERNANCE_ISSUED) {
            _deployedGoalds.push(goaldAddress);
            _goaldOwners.push(creator);
            return;
        }

        // Calculate the amount of tokens issued based on the schedule.
        uint256 goaldsDeployed = _deployedGoalds.length;
        uint256 amount;
        if        (goaldsDeployed <   10) {
            amount = 100;
        } else if (goaldsDeployed <   20) {
            amount =  90;
        } else if (goaldsDeployed <   30) {
            amount =  80;
        } else if (goaldsDeployed <   40) {
            amount =  70;
        } else if (goaldsDeployed <   50) {
            amount =  60;
        } else if (goaldsDeployed <   60) {
            amount =  50;
        } else if (goaldsDeployed <   70) {
            amount =  40;
        } else if (goaldsDeployed <   80) {
            amount =  30;
        } else if (goaldsDeployed <   90) {
            amount =  20;
        } else if (goaldsDeployed <  100) {
            amount =  10;
        } else if (goaldsDeployed < 3600) {
            amount =   1;
        }

        // It's possible we have issued all governance tokens without the DAO initiated.
        if (amount > 0) {
            // Update their reward balance.
            _checkRewardBalance(creator);

            // We are creating a new holder.
            if (balanceOf(creator) < REWARD_THRESHOLD) {
                _rewardHolders ++;
            }

            // Give them the tokens.
            _mint(creator, amount * REWARD_THRESHOLD);
        }

        // We have issued all tokens, so move to the last stage of governance. This will short circuit this function on future calls.
        if (goaldsDeployed >= 3600 && _governanceStage == STAGE_DAO_INITIATED) {
            _governanceStage = STAGE_ALL_GOVERNANCE_ISSUED;
        }

        // Track the goald and its owner.
        _deployedGoalds.push(goaldAddress);
        _goaldOwners.push(creator);
    }

    /** Updates the owner of a deployed Goald. */
    function setGoaldOwner(uint256 id) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED);
        _status = RE_ENTERED;

        // Id is offset by one of the index
        id --;
        require(id < _deployedGoalds.length, "Invalid id");

        // We don't have the address as a parameter so we are guaranteed to always have the correct value stored here.
        address owner = IERC721(_deployedGoalds[id]).ownerOf(id + 1);
        _goaldOwners[id] = owner;

        // Hello world!
        emit OwnerChanged(id + 1, owner);

        // By storing the original amount once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200).
        _status = RE_NOT_ENTERED;
    }

    /// Governance ///

    /** Claims the initial issuance of the governance token to enable bootstrapping the DAO. */
    function claimIssuance() external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED || _status == RE_FROZEN);
        require(msg.sender == _owner,              "Not owner");
        require(_governanceStage == STAGE_INITIAL, "Already claimed");

        _mint(_owner, 12000 * REWARD_THRESHOLD);

        _governanceStage = STAGE_ISSUANCE_CLAIMED;
    }

    /** Uses Uniswap to convert all held amount of a specific token into the reward token, using the provided path. */
    function convertToken(address[] calldata path, uint256 deadline) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED);
        _status = RE_ENTERED;
        require(msg.sender == _owner,                    "Not owner");
            
        // Make sure this contract actually has a balance.
        IERC20 tokenContract = IERC20(path[0]);
        uint256 amount = tokenContract.balanceOf(address(this));
        require(amount > 0, "No balance for token");

        // Make sure the reward token is the last address in the path. Since the array is calldata we don't want to spend the gas to
        // push this onto the end.
        require(path[path.length - 1] == _rewardToken, "Last must be reward token");

        // Swap the tokens.
        tokenContract.approve(_uniswapRouterAddress, amount);
        IUniswapV2Router02(_uniswapRouterAddress).swapExactTokensForTokens(amount, 1, path, address(this), deadline);

        // By storing the original amount once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200).
        _status = RE_NOT_ENTERED;
    }

    /**
     * Uses Uniswap to convert all held amount of specific tokens into the reward token. The tokens must have a direct path,
     * otherwise the intermediary is used for increased liquidity.
     */
    function convertTokens(address[] calldata tokenAddresses, bool isIndirect, uint256 deadline) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED);
        _status = RE_ENTERED;
        require(msg.sender == _owner, "Not owner");

        // The path between a given token and the reward token within Uniswap.
        address[] memory path;
        if (isIndirect) {
            path[1] = _intermediaryToken;
            path[2] = _rewardToken;
        } else {
            path[1] = _rewardToken;
        }
        IUniswapV2Router02 uniswap = IUniswapV2Router02(_uniswapRouterAddress);

        address tokenAddress;
        IERC20 tokenContract;
        
        uint256 amount;
        uint256 count = tokenAddresses.length;
        for (uint256 i; i < count; i ++) {
            // Validate the token.
            tokenAddress = tokenAddresses[i];
            require(tokenAddress != address(0),    "Can't be zero address");
            require(tokenAddress != address(this), "Can't be this address");
            require(tokenAddress != _rewardToken,  "Can't be target address");
            
            // Make sure this contract actually has a balance.
            tokenContract = IERC20(tokenAddress);
            amount = tokenContract.balanceOf(address(this));
            if (amount == 0) {
                continue;
            }

            // Swap the tokens.
            tokenContract.approve(_uniswapRouterAddress, amount);
            path[0] = tokenAddress;
            uniswap.swapExactTokensForTokens(amount, 1, path, address(this), deadline);
        }

        // By storing the original amount once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200).
        _status = RE_NOT_ENTERED;
    }

    /** Returns the current stage of the DAO's governance. */
    function getGovernanceStage() external view returns (uint256) {
        return _governanceStage;
    }

    /** Releases ownership of this proxy and all subsequent ones to the DAO. */
    function initializeDAO() external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED);
        require(msg.sender == _owner,                       "Not owner");
        require(_governanceStage == STAGE_ISSUANCE_CLAIMED, "Issuance unclaimed");

        _burn(_owner, 11000 * REWARD_THRESHOLD);

        _governanceStage = STAGE_DAO_INITIATED;
    }

    /**
     * Changes which token will be the reward token. This can only happen if there is no balance in reserve held for rewards. If a
     * change is desired despite there being excess rewards, call `withdrawReward()` on behalf of each holder to drain the reserve.
     */
    function setRewardToken(address newToken) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED || _status == RE_FROZEN);
        require(msg.sender == _owner,        "Not owner");
        require(newToken != address(0),      "Can't be zero address");
        require(newToken != address(this),   "Can't be this address");
        require(_reservedRewardBalance == 0, "Have reserved balance");

        _rewardToken = newToken;
    }

    /// Rewards ///

    /**
     * Check which rewards a given address is eligible for, and update their current reward balance to reflect that total. Since
     * balances are static until transferred (or minted in the case of a new Goald being created), this function is called before
     * any change to a given addresses' balance. Ths will bring them up to date with any past, unclaimed rewards. Any future rewards
     * will be dependant on their balance after the change.
     */
    function _checkRewardBalance(address holder) internal {
        // There is no need for reentrancy since this only updates the `_rewardBalance` for a given holder according to the amounts
        // they are already owed according to the current state. If this is an unexpected reentrant call, then that holder gets the
        // benefit of this math without having to pay the gas.

        // The total number of rewards issued.
        uint256 count = _rewardMultipliers.length;

        // The holder has already claimed all rewards.
        uint256 currentMinimumIndex = _minimumRewardIndex[holder];
        if (currentMinimumIndex == count) {
            return;
        }

        // The holder is not eligible for a reward according to their current balance.
        uint256 balance = balanceOf(holder);
        if (balance < REWARD_THRESHOLD) {
            // Mark that they have been checked for all rewards.
            if (currentMinimumIndex < count) {
                _minimumRewardIndex[holder] = count;
            }

            return;
        }

        // Calculate the balance increase according to which rewards the holder has yet to claim. Also calculate the amount of the
        // reserve should be released if a given reward has been fully collected by all holders.
        uint256 multiplier;
        uint256 reserveDecrease;
        for (; currentMinimumIndex < count; currentMinimumIndex ++) {
            // This can never overflow since a reward can't be created unless there is enough reserve balance to cover its
            // multiplier, which already checks for overflows, likewise `multiplier * balance` can never overflow.
            multiplier += _rewardMultipliers[currentMinimumIndex];

            // Reduce the holder count and reserve for this reward. If this is the last holder, we refund the remainder of the held
            // reserve back to the main pool. We don't need to worry about underflows here because these values never increase. They
            // are set once when the reward is created, based on the total supply of the governance token at that time.
            if (_rewardHolderCounts[currentMinimumIndex] == 1) {
                // This tracks the sum of any excess remainder across all rewards this address is the last holder of. We are
                // offsetting by their eligible balance because we must still hold in reserve their reward until such time that they
                // choose to claim it.
                reserveDecrease += _rewardReserves[currentMinimumIndex] - (multiplier * balance);
                _rewardHolderCounts[currentMinimumIndex] = 0;
                _rewardReserves[currentMinimumIndex] = 0;
                // We don't wipe `_rewardMultipliers` here despite this being the last holder, so we have a historical record.
            } else {
                _rewardHolderCounts[currentMinimumIndex]--;
                _rewardReserves[currentMinimumIndex] -= multiplier * balance;
            }
        }
        _minimumRewardIndex[holder] = count;

        // Update the balance.
        uint256 currentBalance = _rewardBalance[holder];
        require(currentBalance + (multiplier * balance) > currentBalance, "Balance overflow");
        _rewardBalance[holder] = currentBalance + (multiplier * balance);   

        // Update the reserve balance.
        if (reserveDecrease > 0) {
            _reservedRewardBalance -= reserveDecrease;
        }
    }

    /**
     * Creates a new reward. Rewards are only paid out to holders who have at least "one token" at time of creation. The reward
     * is a multiplier, representing how many reward tokens (e.g., WBTC) should be paid out for one governance token. reward
     * eligibility is only updated in state in two cases:
     *      1) When a reward is being withdrawn (in which it is set to zero).
     *      2) When the governance token is transferred (balances are checked before the transfer, on both sender and recipient).
     */
    function createReward(uint256 multiplier, string calldata reason) external {
        // Reentrancy guard.
        require(_status == RE_NOT_ENTERED);
        _status = RE_ENTERED;
        require(msg.sender == _owner,                    "Not owner");
        require(_governanceStage >= STAGE_DAO_INITIATED, "DAO not initiated");
        require(multiplier > 0,                          "Multiplier must be > 0");

        // Make sure we can actually create a reward with that amount. This balance of the reward token at this proxy address should
        // never decrease except when rewards are claimed by holders.
        uint256 reservedRewardBalance = _reservedRewardBalance;
        uint256 currentBalance = IERC20(_rewardToken).balanceOf(address(this));
        require(currentBalance >= reservedRewardBalance, "Current reserve insufficient");
        uint256 reserveIncrease = totalSupply() * multiplier;
        require(reserveIncrease <= currentBalance - reservedRewardBalance, "Multiplier too large");

        // Increase the reserve.
        require(reservedRewardBalance + reserveIncrease > reservedRewardBalance, "Reserved overflow error");
        reservedRewardBalance += reserveIncrease;

        // Keep track of the holders, reserve, and multiplier for this reward. These values will not increase after being set here.
        uint256 holders = _rewardHolders;
        require(holders > 0, "Must have a holder");
        _rewardHolderCounts.push(holders);
        _rewardMultipliers.push(multiplier);
        _rewardReserves.push(reserveIncrease);

        // Hello world!
        emit RewardCreated(multiplier, reason);

        // By storing the original amount once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200).
        _status = RE_NOT_ENTERED;
    }

    /** Returns the reward balance for a holder according to the true state, not the hard state. See: `_checkRewardBalance()`. */
    function getHolderRewardBalance(address holder) external view returns (uint256) {
        uint256 count = _rewardMultipliers.length;
        uint256 balance = balanceOf(holder);
        uint256 rewardBalance = _rewardBalance[holder];
        uint256 currentMinimumIndex = _minimumRewardIndex[holder];
        for (; currentMinimumIndex < count; currentMinimumIndex ++) {
            rewardBalance += _rewardMultipliers[currentMinimumIndex] * balance;
        }

        return rewardBalance;
    }

    /** Get the details of the reward at the specified index.*/
    function getHolderRewardDetailsAt(uint256 index) external view returns (uint256[3] memory) {
        return [
            _rewardMultipliers[index],
            _rewardHolderCounts[index],
            _rewardReserves[index]
        ];
    }

    /** Return the historical reward details. */
    function getRewardDetails() external view returns (uint256[3] memory) {
        return [
            uint256(_rewardToken),
            _rewardHolders,
            _reservedRewardBalance
        ];
    }

    /**
     * Withdraws the current reward balance. The sender doesn't need to have any current balance of the governance token to
     * withdraw, so long as they have a preexisting outstanding balance. This has a provided recipient so that we can drain the
     * reward pool as necessary (e.g., for changing the reward token).
     */
    function withdrawReward(address holder) external {
        // Reentrancy guard. Allow owner to drain the pool even if frozen.
        require(_status == RE_NOT_ENTERED || (_status == RE_FROZEN && msg.sender == _owner));
        _status = RE_ENTERED;

        // Update their balance.
        _checkRewardBalance(holder);

        // Revert so gas estimators will show a failure.
        uint256 balance = _rewardBalance[holder];
        require(balance > 0, "No reward balance");

        // Wipe the balance.
        _rewardBalance[holder] = 0;
        require(_reservedRewardBalance - balance > 0, "Reserved balance underflow");
        _reservedRewardBalance -= balance;

        // Give them their balance.
        IERC20(_rewardToken).transfer(holder, balance);

        // By storing the original amount once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200).
        _status = RE_NOT_ENTERED;
    }

    /// ERC20 Overrides ///

    /** This is overridden so we can update the reward balancees prior to the transfer completing. */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        return transferFrom(msg.sender, recipient, amount);
    }

    /** This is overridden so we can update the reward balancees prior to the transfer completing. */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        // Update the reward balances prior to the transfer for both sender and receiver.
        _checkRewardBalance(sender);
        _checkRewardBalance(recipient);

        // Preserve the original balances so we know if we need to change `_rewardHolders`.
        uint256 senderBefore = balanceOf(sender);
        uint256 recipientBefore = balanceOf(recipient);

        super.transferFrom(sender, recipient, amount);

        // See if we need to change `_rewardHolders`.
        uint256 senderAfter = balanceOf(sender);
        if        (senderBefore  < REWARD_THRESHOLD && senderAfter >= REWARD_THRESHOLD) {
            _rewardHolders ++;
        } else if (senderBefore >= REWARD_THRESHOLD && senderAfter  < REWARD_THRESHOLD) {
            _rewardHolders --;
        }
        uint256 recipientAfter = balanceOf(recipient);
        if        (recipientBefore  < REWARD_THRESHOLD && recipientAfter >= REWARD_THRESHOLD) {
            _rewardHolders ++;
        } else if (recipientBefore >= REWARD_THRESHOLD && recipientAfter  < REWARD_THRESHOLD) {
            _rewardHolders --;
        }

        // The sender has no balance, so clear their minimum index. This should save on total storage space for this contract. We do
        // not clear the reward balance even if their token balance is zero, since they still have a claim to that balance.
        if (senderAfter == 0) {
            _minimumRewardIndex[msg.sender] = 0;
        }

        return true;
    }
}