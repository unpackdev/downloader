// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.1;

// File: contracts/governance/GovernanceInterface.sol

interface GovernanceInterface {
    function proposeUpdateCoreParameters(
        uint32 preVoteLength,
        uint32 totalVoteLength,
        uint32 expirationLength,
        uint16 minVoteE4,
        uint16 minVoteCoreE4,
        uint16 minCommitE4
    ) external;

    function proposeUpdateWhitelist(address tokenAddress, address oracleAddress) external;

    function proposeDelistWhitelist(address tokenAddress) external;

    function proposeUpdateIncentiveFund(
        address[] memory incentiveAddresses,
        uint256[] memory incentiveAllocation
    ) external;

    function vote(
        bytes32 proposeId,
        bool approval,
        uint128 amount
    ) external;

    function lockinProposal(bytes32 proposeId) external;

    function applyGovernanceForUpdateCore(bytes32 proposeId) external;

    function applyGovernanceForUpdateWhitelist(bytes32 proposeId) external;

    function applyGovernanceForDelistWhitelist(bytes32 proposeId) external;

    function applyGovernanceForUpdateIncentive(bytes32 proposeId) external;

    function withdraw(bytes32 proposeId) external;

    function getTaxTokenAddress() external view returns (address);

    function getCoreParameters()
        external
        view
        returns (
            uint32 preVoteLength,
            uint32 totalVoteLength,
            uint32 expirationLength,
            uint16 minimumVoteE4,
            uint16 minimumVoteCoreE4,
            uint16 minimumCommitE4
        );

    function getUserStatus(bytes32 proposeId, address userAddress)
        external
        view
        returns (uint128 approvalAmount, uint128 denialAmount);

    function getStatus(bytes32 proposeId)
        external
        view
        returns (
            uint128 currentApprovalVoteSum,
            uint128 currentDenialVoteSum,
            uint128 appliedMinimumVote,
            uint32 preVoteDeadline,
            uint32 mainVoteDeadline,
            uint32 expiration,
            bool lockin,
            bool applied
        );

    function getProposals(uint256 offset, uint256 limit)
        external
        view
        returns (bytes32[] memory allProposals);

    function getInfoUpdateCoreParameters(bytes32)
        external
        view
        returns (
            uint64 preVoteLength,
            uint64 totalVoteLength,
            uint64 expirationLength,
            uint16 minVoteE4,
            uint16 minVoteCoreE4,
            uint16 minCommitE4
        );

    function getInfoUpdateWhitelist(bytes32 proposeId)
        external
        view
        returns (address tokenAddress, address oracleAddress);

    function getInfoDelistWhitelist(bytes32 proposeId) external view returns (address tokenAddress);

    function getInfoUpdateIncentive(bytes32 proposeId)
        external
        view
        returns (address[] memory incentiveAddresses, uint256[] memory incentiveAllocation);
}

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol





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
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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

// File: @openzeppelin/contracts/utils/SafeCast.sol


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// File: contracts/token/TaxTokenInterface.sol


interface TaxTokenInterface is IERC20 {
    function mintToken(
        address,
        uint256,
        address
    ) external;

    function registerWhitelist(address, address) external;

    function unregisterWhitelist(address) external;

    function updateLendingAddress(address) external;

    function updateIncentiveAddresses(address[] memory, uint256[] memory) external;

    function updateGovernanceAddress(address) external;

    function mintDeveloperFund() external;

    function mintIncentiveFund() external;

    function getGovernanceAddress() external view returns (address);

    function getDeveloperAddress() external view returns (address);

    function getLendingAddress() external view returns (address);

    function getFunds() external view returns (uint256 developerFund, uint256 incentiveFund);

    function getConfigs()
        external
        view
        returns (
            uint256 maxTotalSupply,
            uint256 halvingStartLendValue,
            uint256 halvingDecayRateE8,
            uint256 developerFundRateE8,
            uint256 incentiveFundRateE8
        );

    function getIncentiveFundAddresses()
        external
        view
        returns (
            address[] memory incentiveFundAddresses,
            uint256[] memory incentiveFundAllocationE8
        );

    function getMintUnit() external view returns (uint256);

    function getOracleAddress(address) external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// File: contracts/staking/StakingVote.sol


contract StakingVote {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    address internal _governanceAddress;
    mapping(address => uint256) internal _voteNum;

    /* ========== EVENTS ========== */

    event LogUpdateGovernanceAddress(address newAddress);

    /* ========== CONSTRUCTOR ========== */

    constructor(address governanceAddress) {
        _governanceAddress = governanceAddress;
    }

    /* ========== MODIFIERS ========== */

    modifier isGovernance(address account) {
        require(account == _governanceAddress, "sender must be governance address");
        _;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice `_governanceAddress` can be updated by the current governance address.
     * @dev Executed only once when initially set the governance address
     * as the governance contract does not have the function to call this function.
     */
    function updateGovernanceAddress(address newGovernanceAddress)
        external
        isGovernance(msg.sender)
    {
        _governanceAddress = newGovernanceAddress;

        emit LogUpdateGovernanceAddress(newGovernanceAddress);
    }

    function voteDeposit(address account, uint256 amount) external isGovernance(msg.sender) {
        _updVoteSub(account, amount);
    }

    function voteWithdraw(address account, uint256 amount) external isGovernance(msg.sender) {
        _updVoteAdd(account, amount);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _updVoteAdd(address account, uint256 amount) internal {
        require(_voteNum[account] + amount >= amount, "overflow the amount of votes");
        _voteNum[account] += amount;
    }

    function _updVoteSub(address account, uint256 amount) internal {
        require(_voteNum[account] >= amount, "underflow the amount of votes");
        _voteNum[account] -= amount;
    }

    /* ========== CALL FUNCTIONS ========== */

    function getGovernanceAddress() external view returns (address) {
        return _governanceAddress;
    }

    function getVoteNum(address account) external view returns (uint256) {
        return _voteNum[account];
    }
}

// File: contracts/lending/LendingInterface.sol

interface LendingInterface {
    function depositEth() external payable;

    function depositErc20(address tokenAddress, uint256 amount) external;

    function borrow(address tokenAddress, uint256 amount) external;

    function withdraw(address tokenAddress, uint256 amount) external;

    function repayEth() external payable;

    function repayErc20(address tokenAddress, uint256 amount) external;

    function forceLiquidate(address token, address account) external;

    function getStakingAddress() external view returns (address);

    function getTaxTokenAddress() external view returns (address);

    function getInterest() external view returns (uint256);

    function getTvl(address tokenAddress) external view returns (uint256);

    function getTotalLending(address tokenAddress) external view returns (uint256);

    function getTotalBorrowing(address tokenAddress) external view returns (uint256);

    function getTokenInfo(address tokenAddress)
        external
        view
        returns (uint256 totalLendAmount, uint256 totalBorrowAmount);

    function getLenderAccount(address tokenAddress, address userAddress)
        external
        view
        returns (uint256);

    function getBorrowerAccount(address tokenAddress, address userAddress)
        external
        view
        returns (uint256);

    function getRemainingCredit(address tokenAddress, address userAddress)
        external
        view
        returns (uint256);

    function getAccountInfo(address tokenAddress, address userAddress)
        external
        view
        returns (
            uint256 lendAccount,
            uint256 borrowAccount,
            uint256 remainingCredit
        );
}

// File: contracts/oracle/OracleInterface.sol

/**
 * @dev Oracle referenced by OracleProxy must implement this interface.
 */
interface OracleInterface {
    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint8);
}

// File: contracts/governance/Governance.sol









contract Governance is GovernanceInterface {
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeCast for uint256;

    /* ========== CONSTANT VARIABLES ========== */

    uint32 internal constant MAX_TIME_LENGTH = 4 weeks;
    uint32 internal constant MIN_TIME_LENGTH = 24 hours;
    uint16 internal constant MAX_MIN_VOTE = 0.2 * 10**4;
    uint16 internal constant MIN_MIN_VOTE = 0.0001 * 10**4;
    uint16 internal constant MAX_MIN_COMMIT = 0.01 * 10**4;
    uint16 internal constant MIN_MIN_COMMIT = 0.0001 * 10**4;
    TaxTokenInterface internal _taxTokenContract;

    /* ========== STATE VARIABLES ========== */

    uint32 internal _preVoteLength;
    uint32 internal _totalVoteLength;
    uint32 internal _expirationLength;
    uint16 internal _minimumVoteE4;
    uint16 internal _minimumVoteCoreE4;
    uint16 internal _minimumCommitE4;

    /**
     * @dev List of proposal IDs (index starts from 1).
     */
    bytes32[] _proposalList;

    struct CoreParameters {
        uint32 preVoteLength;
        uint32 totalVoteLength;
        uint32 expirationLength;
        uint16 minVoteE4;
        uint16 minVoteCoreE4;
        uint16 minCommitE4;
    }
    mapping(bytes32 => CoreParameters) internal _proposeUpdateCore;

    struct ProposeStatus {
        uint128 appliedMinimumVote;
        uint128 currentApprovalVoteSum;
        uint128 currentDenialVoteSum;
        uint32 preVoteDeadline;
        uint32 mainVoteDeadline;
        uint32 expiration;
        bool lockin;
        bool applied;
    }
    mapping(bytes32 => ProposeStatus) internal _proposeStatus;

    struct ProposeStatusWithProposeId {
        bytes32 proposeId;
        uint128 appliedMinimumVote;
        uint128 currentApprovalVoteSum;
        uint128 currentDenialVoteSum;
        uint32 preVoteDeadline;
        uint32 mainVoteDeadline;
        uint32 expiration;
        bool lockin;
        bool applied;
    }

    struct WhitelistParameters {
        address tokenAddress;
        address oracleAddress;
    }
    mapping(bytes32 => WhitelistParameters) internal _proposeList;

    struct DelistParameters {
        address tokenAddress;
    }
    mapping(bytes32 => DelistParameters) internal _proposeDelist;

    struct IncentiveParameters {
        address[] incentiveAddresses;
        uint256[] incentiveAllocation;
    }
    mapping(bytes32 => IncentiveParameters) internal _proposeUpdateIncentive;

    struct VoteAmount {
        uint128 approval;
        uint128 denial;
    }
    mapping(bytes32 => VoteAmount) internal _amountOfVotes;

    /* ========== EVENTS ========== */

    event LogUpdateCoreParameters(
        uint64 preVoteLength,
        uint64 totalVoteLength,
        uint64 expirationLength,
        uint16 minVoteE4,
        uint16 minVoteCoreE4,
        uint16 minCommitE4
    );

    event LogProposeUpdateCoreParameters(
        bytes32 indexed proposeId,
        uint64 preVoteLength,
        uint64 totalVoteLength,
        uint64 expirationLength,
        uint16 minVoteE4,
        uint16 minVoteCoreE4,
        uint16 minCommitE4,
        uint32 preVoteDeadline,
        uint32 mainVoteDeadline,
        uint32 expiration
    );
    event LogProposeUpdateWhiteList(
        bytes32 indexed proposeId,
        address tokenAddress,
        address oracleAddress,
        uint32 preVoteDeadline,
        uint32 mainVoteDeadline,
        uint32 expiration
    );
    event LogProposeDelistWhiteList(
        bytes32 indexed proposeId,
        address tokenAddress,
        uint32 preVoteDeadline,
        uint32 mainVoteDeadline,
        uint32 expiration
    );
    event LogProposeUpdateIncentive(
        bytes32 indexed proposeId,
        address[] incentiveAddresses,
        uint256[] incentiveAllocation,
        uint32 preVoteDeadline,
        uint32 mainVoteDeadline,
        uint32 expiration
    );

    event LogDeposit(
        bytes32 indexed proposeId,
        address indexed userAddress,
        bool approval,
        uint128 amount
    );

    event LogWithdraw(bytes32 indexed proposeId, address indexed userAddress, uint128 amount);

    event LogApprovedProposal(bytes32 indexed proposeId);

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address taxTokenAddress,
        uint32 preVoteLength,
        uint32 totalVoteLength,
        uint32 expirationLength,
        uint16 minVoteE4,
        uint16 minVoteCoreE4,
        uint16 minCommitE4
    ) {
        _taxTokenContract = TaxTokenInterface(taxTokenAddress);

        _assertValidCoreParameters(
            CoreParameters({
                preVoteLength: preVoteLength,
                totalVoteLength: totalVoteLength,
                expirationLength: expirationLength,
                minVoteE4: minVoteE4,
                minVoteCoreE4: minVoteCoreE4,
                minCommitE4: minCommitE4
            })
        );

        _preVoteLength = preVoteLength; // 1 weeks; // When sufficient amount of vote has not been collected until this deadline, the voting event is canceled.
        _totalVoteLength = totalVoteLength; // 2 weeks; // Only when sufficient amount of vote has been collected, the main voting period starts and the voting result is to be applied.
        _expirationLength = expirationLength; // 1 days; // Expiration of the proposal to be applied if the proposal is confirmed.
        _minimumVoteE4 = minVoteE4; // 0.05 * 10**4 is 5%
        _minimumVoteCoreE4 = minVoteCoreE4; // 0.1 * 10**4 is 10%
        _minimumCommitE4 = minCommitE4; // 0.0001 * 10**4 is 0.01%

        _proposalList.push(bytes32(0)); // The index of _proposalList starts from 1.
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Propose delisting the tokenAddress from the whitelist.
     * The proposer needs to commit minimum deposit amount.
     */
    function proposeUpdateCoreParameters(
        uint32 preVoteLength,
        uint32 totalVoteLength,
        uint32 expirationLength,
        uint16 minVoteE4,
        uint16 minVoteCoreE4,
        uint16 minCommitE4
    ) external override {
        bytes32 proposeId = _generateUpdateCoreProposeId(
            CoreParameters({
                preVoteLength: preVoteLength,
                totalVoteLength: totalVoteLength,
                expirationLength: expirationLength,
                minVoteE4: minVoteE4,
                minVoteCoreE4: minVoteCoreE4,
                minCommitE4: minCommitE4
            })
        );
        uint32 blockTime = block.timestamp.toUint32();
        uint32 preVoteDeadline = blockTime + _preVoteLength;
        uint32 mainVoteDeadline = blockTime + _totalVoteLength;
        uint128 appliedMinimumVote = (_taxTokenContract.totalSupply().mul(_minimumVoteCoreE4) /
            10**4)
            .toUint128();
        uint128 appliedMinCommit = (_taxTokenContract.totalSupply().mul(_minimumCommitE4) / 10**4)
            .toUint128();
        uint32 expiration = _expirationLength;
        require(
            _proposeStatus[proposeId].mainVoteDeadline == 0 ||
                (_proposeStatus[proposeId].lockin == false &&
                    _proposeStatus[proposeId].preVoteDeadline +
                        _proposeStatus[proposeId].expiration <
                    block.timestamp) ||
                (_proposeStatus[proposeId].lockin == true &&
                    _proposeStatus[proposeId].mainVoteDeadline +
                        _proposeStatus[proposeId].expiration <
                    block.timestamp),
            "the proposal should not conflict with the ongoing proposal"
        );

        _assertValidCoreParameters(
            CoreParameters({
                preVoteLength: preVoteLength == 0 ? _preVoteLength : preVoteLength,
                totalVoteLength: totalVoteLength == 0 ? _totalVoteLength : totalVoteLength,
                expirationLength: expirationLength == 0 ? _expirationLength : expirationLength,
                minVoteE4: minVoteE4 == 0 ? _minimumVoteE4 : minVoteE4,
                minVoteCoreE4: minVoteCoreE4 == 0 ? _minimumVoteCoreE4 : minVoteCoreE4,
                minCommitE4: minCommitE4 == 0 ? _minimumCommitE4 : minCommitE4
            })
        );

        _proposalList.push(proposeId);
        _proposeStatus[proposeId] = ProposeStatus({
            preVoteDeadline: preVoteDeadline,
            mainVoteDeadline: mainVoteDeadline,
            expiration: expiration,
            appliedMinimumVote: appliedMinimumVote,
            currentApprovalVoteSum: appliedMinCommit,
            currentDenialVoteSum: 0,
            lockin: false,
            applied: false
        });
        _proposeUpdateCore[proposeId] = CoreParameters({
            preVoteLength: preVoteLength,
            totalVoteLength: totalVoteLength,
            expirationLength: expirationLength,
            minVoteE4: minVoteE4,
            minVoteCoreE4: minVoteCoreE4,
            minCommitE4: minCommitE4
        });
        bytes32 account = keccak256(abi.encode(proposeId, msg.sender));
        _amountOfVotes[account].approval = _amountOfVotes[account]
            .approval
            .add(appliedMinCommit)
            .toUint128();
        _lockStakingToken(msg.sender, appliedMinCommit);

        emit LogProposeUpdateCoreParameters(
            proposeId,
            preVoteLength,
            totalVoteLength,
            expirationLength,
            minVoteE4,
            minVoteCoreE4,
            minCommitE4,
            preVoteDeadline,
            mainVoteDeadline,
            expiration
        );
        emit LogDeposit(proposeId, msg.sender, true, appliedMinCommit);
    }

    /**
     * @notice Propose updating the whitelist.
     * The proposer needs to commit minimum deposit amount.
     */
    function proposeUpdateWhitelist(address tokenAddress, address oracleAddress) external override {
        // Ensure the code of oracleAddress has OracleInterface interface.
        {
            OracleInterface oracleContract = OracleInterface(oracleAddress);
            oracleContract.decimals();
            oracleContract.latestAnswer();
        }

        bytes32 proposeId = _generateRegisterWhitelistProposeId(
            WhitelistParameters({tokenAddress: tokenAddress, oracleAddress: oracleAddress})
        );
        uint32 blockTime = block.timestamp.toUint32();
        uint32 preVoteDeadline = blockTime + _preVoteLength;
        uint32 mainVoteDeadline = blockTime + _totalVoteLength;
        uint128 appliedMinimumVote = (_taxTokenContract.totalSupply().mul(_minimumVoteE4) / 10**4)
            .toUint128();
        uint128 appliedMinCommit = (_taxTokenContract.totalSupply().mul(_minimumCommitE4) / 10**4)
            .toUint128();
        uint32 expiration = _expirationLength;
        require(
            _proposeStatus[proposeId].mainVoteDeadline == 0 ||
                (_proposeStatus[proposeId].lockin == false &&
                    _proposeStatus[proposeId].preVoteDeadline +
                        _proposeStatus[proposeId].expiration <
                    block.timestamp) ||
                (_proposeStatus[proposeId].lockin == true &&
                    _proposeStatus[proposeId].mainVoteDeadline +
                        _proposeStatus[proposeId].expiration <
                    block.timestamp),
            "the proposal should not conflict with the ongoing proposal"
        );

        _proposalList.push(proposeId);
        _proposeStatus[proposeId] = ProposeStatus({
            preVoteDeadline: preVoteDeadline,
            mainVoteDeadline: mainVoteDeadline,
            expiration: expiration,
            appliedMinimumVote: appliedMinimumVote,
            currentApprovalVoteSum: appliedMinCommit,
            currentDenialVoteSum: 0,
            lockin: false,
            applied: false
        });
        _proposeList[proposeId] = WhitelistParameters({
            tokenAddress: tokenAddress,
            oracleAddress: oracleAddress
        });
        bytes32 account = keccak256(abi.encode(proposeId, msg.sender));
        _amountOfVotes[account].approval = _amountOfVotes[account]
            .approval
            .add(appliedMinCommit)
            .toUint128();
        _lockStakingToken(msg.sender, appliedMinCommit);

        emit LogProposeUpdateWhiteList(
            proposeId,
            tokenAddress,
            oracleAddress,
            preVoteDeadline,
            mainVoteDeadline,
            expiration
        );
        emit LogDeposit(proposeId, msg.sender, true, appliedMinCommit);
    }

    /**
     * @notice Propose delisting the tokenAddress from the whitelist.
     * The proposer needs to commit minimum deposit amount.
     */
    function proposeDelistWhitelist(address tokenAddress) external override {
        bytes32 proposeId = _generateUnregisterWhitelistProposeId(
            DelistParameters({tokenAddress: tokenAddress})
        );
        uint32 blockTime = block.timestamp.toUint32();
        uint32 preVoteDeadline = blockTime + _preVoteLength;
        uint32 mainVoteDeadline = blockTime + _totalVoteLength;
        uint128 appliedMinimumVote = (_taxTokenContract.totalSupply().mul(_minimumVoteE4) / 10**4)
            .toUint128();
        uint128 appliedMinCommit = (_taxTokenContract.totalSupply().mul(_minimumCommitE4) / 10**4)
            .toUint128();
        uint32 expiration = _expirationLength;
        require(
            _proposeStatus[proposeId].mainVoteDeadline == 0 ||
                (_proposeStatus[proposeId].lockin == false &&
                    _proposeStatus[proposeId].preVoteDeadline +
                        _proposeStatus[proposeId].expiration <
                    block.timestamp) ||
                (_proposeStatus[proposeId].lockin == true &&
                    _proposeStatus[proposeId].mainVoteDeadline +
                        _proposeStatus[proposeId].expiration <
                    block.timestamp),
            "the proposal should not conflict with the ongoing proposal"
        );

        require(
            _taxTokenContract.getOracleAddress(tokenAddress) != address(0),
            "the tokenAddress is not whitelisted"
        );

        _proposalList.push(proposeId);
        _proposeStatus[proposeId] = ProposeStatus({
            preVoteDeadline: preVoteDeadline,
            mainVoteDeadline: mainVoteDeadline,
            expiration: expiration,
            appliedMinimumVote: appliedMinimumVote,
            currentApprovalVoteSum: appliedMinCommit,
            currentDenialVoteSum: 0,
            lockin: false,
            applied: false
        });
        _proposeDelist[proposeId] = DelistParameters({tokenAddress: tokenAddress});
        bytes32 account = keccak256(abi.encode(proposeId, msg.sender));
        _amountOfVotes[account].approval = _amountOfVotes[account]
            .approval
            .add(appliedMinCommit)
            .toUint128();
        _lockStakingToken(msg.sender, appliedMinCommit);

        emit LogProposeDelistWhiteList(
            proposeId,
            tokenAddress,
            preVoteDeadline,
            mainVoteDeadline,
            expiration
        );
        emit LogDeposit(proposeId, msg.sender, true, appliedMinCommit);
    }

    /**
     * @notice Propose updating the incentive addresses and their allocation.
     * The proposer needs to commit minimum deposit amount.
     */
    function proposeUpdateIncentiveFund(
        address[] memory incentiveAddresses,
        uint256[] memory incentiveAllocation
    ) external override {
        bytes32 proposeId = _generateUpdateIncentiveProposeId(
            IncentiveParameters({
                incentiveAddresses: incentiveAddresses,
                incentiveAllocation: incentiveAllocation
            })
        );
        uint32 blockTime = block.timestamp.toUint32();
        uint32 preVoteDeadline = blockTime + _preVoteLength;
        uint32 mainVoteDeadline = blockTime + _totalVoteLength;
        uint128 appliedMinimumVote = (_taxTokenContract.totalSupply().mul(_minimumVoteE4) / 10**4)
            .toUint128();
        uint128 appliedMinCommit = (_taxTokenContract.totalSupply().mul(_minimumCommitE4) / 10**4)
            .toUint128();
        uint32 expiration = _expirationLength;
        require(
            _proposeStatus[proposeId].mainVoteDeadline == 0 ||
                (_proposeStatus[proposeId].lockin == false &&
                    _proposeStatus[proposeId].preVoteDeadline +
                        _proposeStatus[proposeId].expiration <
                    block.timestamp) ||
                (_proposeStatus[proposeId].lockin == true &&
                    _proposeStatus[proposeId].mainVoteDeadline +
                        _proposeStatus[proposeId].expiration <
                    block.timestamp),
            "the proposal should not conflict with the ongoing proposal"
        );

        require(
            incentiveAddresses.length == incentiveAllocation.length,
            "the length of the addresses and the allocation should be the same"
        );
        uint256 sumcheck = 0;
        for (uint256 i = 0; i < incentiveAllocation.length; i++) {
            sumcheck = sumcheck.add(incentiveAllocation[i]);
        }
        require(sumcheck == 10**8, "the sum of the allocation should be 10**8");

        _proposalList.push(proposeId);
        _proposeStatus[proposeId] = ProposeStatus({
            preVoteDeadline: preVoteDeadline,
            mainVoteDeadline: mainVoteDeadline,
            expiration: expiration,
            appliedMinimumVote: appliedMinimumVote,
            currentApprovalVoteSum: appliedMinCommit,
            currentDenialVoteSum: 0,
            lockin: false,
            applied: false
        });
        _proposeUpdateIncentive[proposeId] = IncentiveParameters({
            incentiveAddresses: incentiveAddresses,
            incentiveAllocation: incentiveAllocation
        });
        bytes32 account = keccak256(abi.encode(proposeId, msg.sender));
        _amountOfVotes[account].approval = _amountOfVotes[account]
            .approval
            .add(appliedMinCommit)
            .toUint128();
        _lockStakingToken(msg.sender, appliedMinCommit);

        emit LogProposeUpdateIncentive(
            proposeId,
            incentiveAddresses,
            incentiveAllocation,
            preVoteDeadline,
            mainVoteDeadline,
            expiration
        );
        emit LogDeposit(proposeId, msg.sender, true, appliedMinCommit);
    }

    /**
     * @notice Approve or deny the proposal by commit.
     * The voter should hold the amount in the staking contract.
     */
    function vote(
        bytes32 proposeId,
        bool approval,
        uint128 amount
    ) external override {
        bytes32 account = keccak256(abi.encode(proposeId, msg.sender));
        require(
            (_proposeStatus[proposeId].lockin &&
                _proposeStatus[proposeId].mainVoteDeadline >= block.timestamp) ||
                _proposeStatus[proposeId].preVoteDeadline >= block.timestamp,
            "voting period has expired"
        );
        if (approval) {
            _proposeStatus[proposeId].currentApprovalVoteSum = _proposeStatus[proposeId]
                .currentApprovalVoteSum
                .add(amount)
                .toUint128();
            _amountOfVotes[account].approval = _amountOfVotes[account]
                .approval
                .add(amount)
                .toUint128();
        } else {
            _proposeStatus[proposeId].currentDenialVoteSum = _proposeStatus[proposeId]
                .currentDenialVoteSum
                .add(amount)
                .toUint128();
            _amountOfVotes[account].denial = _amountOfVotes[account].denial.add(amount).toUint128();
        }
        _lockStakingToken(msg.sender, amount);

        emit LogDeposit(proposeId, msg.sender, approval, amount);
    }

    /**
     * @notice Check and mark flag if the proposal collects minimum vote amount within the pre vote period
     * and the proposal will be accepted if the approval vote is larger than denial vote
     * after the end of the main vote period.
     */
    function lockinProposal(bytes32 proposeId) external override {
        require(
            _proposeStatus[proposeId].currentApprovalVoteSum +
                _proposeStatus[proposeId].currentDenialVoteSum >=
                _proposeStatus[proposeId].appliedMinimumVote,
            "insufficient amount for lockin"
        );
        require(
            _proposeStatus[proposeId].preVoteDeadline >= block.timestamp,
            "lockin period has expired"
        );
        _proposeStatus[proposeId].lockin = true;
    }

    /**
     * @notice Apply the updating core parameters proposal if admitted.
     */
    function applyGovernanceForUpdateCore(bytes32 proposeId) external override {
        require(_proposeStatus[proposeId].lockin = true, "the proposal is not locked in");
        require(
            _proposeStatus[proposeId].applied == false,
            "the proposal has been already applied"
        );
        require(
            _proposeStatus[proposeId].mainVoteDeadline <= block.timestamp,
            "the proposal is still under voting period"
        );
        require(
            _proposeStatus[proposeId].mainVoteDeadline + _proposeStatus[proposeId].expiration >
                block.timestamp,
            "the applicable period of the proposal has expired"
        );
        require(
            _proposeStatus[proposeId].currentApprovalVoteSum >
                _proposeStatus[proposeId].currentDenialVoteSum,
            "the proposal is denied by majority of vote"
        );
        _proposeStatus[proposeId].applied = true;

        require(
            proposeId == _generateUpdateCoreProposeId(_proposeUpdateCore[proposeId]),
            "the propose ID is invalid"
        );

        _preVoteLength = _proposeUpdateCore[proposeId].preVoteLength == 0
            ? _preVoteLength
            : _proposeUpdateCore[proposeId].preVoteLength;
        _totalVoteLength = _proposeUpdateCore[proposeId].totalVoteLength == 0
            ? _totalVoteLength
            : _proposeUpdateCore[proposeId].totalVoteLength;
        _expirationLength = _proposeUpdateCore[proposeId].expirationLength == 0
            ? _expirationLength
            : _proposeUpdateCore[proposeId].expirationLength;
        _minimumVoteE4 = _proposeUpdateCore[proposeId].minVoteE4 == 0
            ? _minimumVoteE4
            : _proposeUpdateCore[proposeId].minVoteE4;
        _minimumVoteCoreE4 = _proposeUpdateCore[proposeId].minVoteCoreE4 == 0
            ? _minimumVoteCoreE4
            : _proposeUpdateCore[proposeId].minVoteCoreE4;
        _minimumCommitE4 = _proposeUpdateCore[proposeId].minCommitE4 == 0
            ? _minimumCommitE4
            : _proposeUpdateCore[proposeId].minCommitE4;

        emit LogApprovedProposal(proposeId);
        emit LogUpdateCoreParameters(
            _preVoteLength,
            _totalVoteLength,
            _expirationLength,
            _minimumVoteE4,
            _minimumVoteCoreE4,
            _minimumCommitE4
        );
    }

    /**
     * @notice Apply the listing proposal if admitted.
     */
    function applyGovernanceForUpdateWhitelist(bytes32 proposeId) external override {
        require(_proposeStatus[proposeId].lockin = true, "the proposal is not locked in");
        require(
            _proposeStatus[proposeId].applied == false,
            "the proposal has been already applied"
        );
        require(
            _proposeStatus[proposeId].mainVoteDeadline <= block.timestamp,
            "the proposal is still under voting period"
        );
        require(
            _proposeStatus[proposeId].mainVoteDeadline + _proposeStatus[proposeId].expiration >
                block.timestamp,
            "the applicable period of the proposal has expired"
        );
        require(
            _proposeStatus[proposeId].currentApprovalVoteSum >
                _proposeStatus[proposeId].currentDenialVoteSum,
            "the proposal is denied by majority of vote"
        );
        _proposeStatus[proposeId].applied = true;

        address tokenAddress = _proposeList[proposeId].tokenAddress;
        address oracleAddress = _proposeList[proposeId].oracleAddress;

        require(
            proposeId ==
                _generateRegisterWhitelistProposeId(
                    WhitelistParameters({tokenAddress: tokenAddress, oracleAddress: oracleAddress})
                ),
            "the propose ID is invalid"
        );
        _taxTokenContract.registerWhitelist(tokenAddress, oracleAddress);

        emit LogApprovedProposal(proposeId);
    }

    /**
     * @notice Apply the delisting proposal if admitted.
     */
    function applyGovernanceForDelistWhitelist(bytes32 proposeId) external override {
        require(_proposeStatus[proposeId].lockin = true, "the proposal is not locked in");
        require(
            _proposeStatus[proposeId].applied == false,
            "the proposal has been already applied"
        );
        require(
            _proposeStatus[proposeId].mainVoteDeadline <= block.timestamp,
            "the proposal is still under voting period"
        );
        require(
            _proposeStatus[proposeId].mainVoteDeadline + _proposeStatus[proposeId].expiration >
                block.timestamp,
            "the applicable period of the proposal has expired"
        );
        require(
            _proposeStatus[proposeId].currentApprovalVoteSum >
                _proposeStatus[proposeId].currentDenialVoteSum,
            "the proposal is denied by majority of vote"
        );
        _proposeStatus[proposeId].applied = true;

        address tokenAddress = _proposeDelist[proposeId].tokenAddress;

        require(
            proposeId ==
                _generateUnregisterWhitelistProposeId(
                    DelistParameters({tokenAddress: tokenAddress})
                ),
            "the propose ID is invalid"
        );
        _taxTokenContract.unregisterWhitelist(tokenAddress);

        emit LogApprovedProposal(proposeId);
    }

    /**
     * @notice Apply the updating incentive proposal if admitted.
     */
    function applyGovernanceForUpdateIncentive(bytes32 proposeId) external override {
        require(_proposeStatus[proposeId].lockin = true, "the proposal is not locked in");
        require(
            _proposeStatus[proposeId].applied == false,
            "the proposal has been already applied"
        );
        require(
            _proposeStatus[proposeId].mainVoteDeadline <= block.timestamp,
            "the proposal is still under voting period"
        );
        require(
            _proposeStatus[proposeId].mainVoteDeadline + _proposeStatus[proposeId].expiration >
                block.timestamp,
            "the applicable period of the proposal has expired"
        );
        require(
            _proposeStatus[proposeId].currentApprovalVoteSum >
                _proposeStatus[proposeId].currentDenialVoteSum,
            "the proposal is denied by majority of vote"
        );
        _proposeStatus[proposeId].applied = true;

        address[] memory incentiveAddresses = _proposeUpdateIncentive[proposeId].incentiveAddresses;
        uint256[] memory incentiveAllocation = _proposeUpdateIncentive[proposeId]
            .incentiveAllocation;

        require(
            proposeId ==
                _generateUpdateIncentiveProposeId(
                    IncentiveParameters({
                        incentiveAddresses: incentiveAddresses,
                        incentiveAllocation: incentiveAllocation
                    })
                ),
            "the propose ID is invalid"
        );
        _taxTokenContract.updateIncentiveAddresses(incentiveAddresses, incentiveAllocation);

        emit LogApprovedProposal(proposeId);
    }

    /**
     * @notice Withdraw deposit after the end of the proposal.
     */
    function withdraw(bytes32 proposeId) external override {
        bytes32 account = keccak256(abi.encode(proposeId, msg.sender));
        VoteAmount memory amountOfVotes = _amountOfVotes[account];
        require(
            amountOfVotes.approval != 0 || amountOfVotes.denial != 0,
            "no deposit on the proposeId"
        );
        require(
            (_proposeStatus[proposeId].lockin == false &&
                _proposeStatus[proposeId].preVoteDeadline < block.timestamp) ||
                (_proposeStatus[proposeId].applied == true &&
                    _proposeStatus[proposeId].mainVoteDeadline <= block.timestamp) ||
                (_proposeStatus[proposeId].mainVoteDeadline +
                    _proposeStatus[proposeId].expiration <=
                    block.timestamp),
            "cannot withdraw while the voting is in progress"
        );
        uint128 withdrawAmount = amountOfVotes.approval + amountOfVotes.denial; // <= _taxTokenContract.totalSupply()
        delete _amountOfVotes[account];
        _unlockStakingToken(msg.sender, withdrawAmount);

        emit LogWithdraw(proposeId, msg.sender, withdrawAmount);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _lockStakingToken(address voter, uint128 amount) internal {
        address lendingAddress = _taxTokenContract.getLendingAddress();
        address stakingAddress = LendingInterface(lendingAddress).getStakingAddress();
        StakingVote(stakingAddress).voteDeposit(voter, amount);
    }

    function _unlockStakingToken(address voter, uint128 amount) internal {
        address lendingAddress = _taxTokenContract.getLendingAddress();
        address stakingAddress = LendingInterface(lendingAddress).getStakingAddress();
        StakingVote(stakingAddress).voteWithdraw(voter, amount);
    }

    function _assertValidCoreParameters(CoreParameters memory params) internal pure returns (bool) {
        require(
            params.preVoteLength + MIN_TIME_LENGTH <= params.totalVoteLength,
            "total voting period should be longer than or equal to pre-voting period"
        );

        uint256 mainVoteLength = params.totalVoteLength - params.preVoteLength;
        require(
            params.preVoteLength <= MAX_TIME_LENGTH && params.preVoteLength >= MIN_TIME_LENGTH,
            "preVoteLength should be in between the acceptable range"
        );

        require(
            mainVoteLength <= MAX_TIME_LENGTH,
            "totalVoteLength should be in between the acceptable range"
        );
        require(
            params.expirationLength <= MAX_TIME_LENGTH &&
                params.expirationLength >= MIN_TIME_LENGTH,
            "expirationLength should be in between the acceptable range"
        );

        require(
            params.minCommitE4 <= params.minVoteE4 && params.minCommitE4 <= params.minVoteCoreE4,
            "quorum to apply proposal is more than or equal to minimum commitment"
        );
        require(
            params.minCommitE4 <= MAX_MIN_COMMIT && params.minCommitE4 >= MIN_MIN_COMMIT,
            "minCommit should be in between the acceptable range"
        );
        require(
            params.minVoteE4 <= MAX_MIN_VOTE && params.minVoteE4 >= MIN_MIN_VOTE,
            "minVote should be in between the acceptable range"
        );
        require(
            params.minVoteCoreE4 <= MAX_MIN_VOTE && params.minVoteCoreE4 >= MIN_MIN_VOTE,
            "minVoteCore should be in between the acceptable range"
        );
    }

    function _generateUpdateCoreProposeId(CoreParameters memory proposal)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    "Update Core",
                    proposal.preVoteLength,
                    proposal.totalVoteLength,
                    proposal.expirationLength,
                    proposal.minVoteE4,
                    proposal.minVoteCoreE4,
                    proposal.minCommitE4
                )
            );
    }

    function _generateRegisterWhitelistProposeId(WhitelistParameters memory proposal)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode("Register Whitelist", proposal.tokenAddress, proposal.oracleAddress)
            );
    }

    function _generateUnregisterWhitelistProposeId(DelistParameters memory proposal)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode("Unregister Whitelist", proposal.tokenAddress));
    }

    function _generateUpdateIncentiveProposeId(IncentiveParameters memory proposal)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    "Update Incentive",
                    proposal.incentiveAddresses,
                    proposal.incentiveAllocation
                )
            );
    }

    /* ========== CALL FUNCTIONS ========== */

    /**
     * @return tax token address.
     */
    function getTaxTokenAddress() external view override returns (address) {
        return address(_taxTokenContract);
    }

    /**
     * @notice Get the current core parameters.
     */
    function getCoreParameters()
        external
        view
        override
        returns (
            uint32 preVoteLength,
            uint32 totalVoteLength,
            uint32 expirationLength,
            uint16 minimumVoteE4,
            uint16 minimumVoteCoreE4,
            uint16 minimumCommitE4
        )
    {
        preVoteLength = _preVoteLength;
        totalVoteLength = _totalVoteLength;
        expirationLength = _expirationLength;
        minimumVoteE4 = _minimumVoteE4;
        minimumVoteCoreE4 = _minimumVoteCoreE4;
        minimumCommitE4 = _minimumCommitE4;
    }

    /**
     * @notice Get the deposit amount of the user for the proposal.
     */
    function getUserStatus(bytes32 proposeId, address userAddress)
        external
        view
        override
        returns (uint128 approvalAmount, uint128 denialAmount)
    {
        bytes32 account = keccak256(abi.encode(proposeId, userAddress));
        VoteAmount memory amountOfVotes = _amountOfVotes[account];
        approvalAmount = amountOfVotes.approval;
        denialAmount = amountOfVotes.denial;
    }

    /**
     * @notice Get the current status of the proposal.
     */
    function getStatus(bytes32 proposeId)
        external
        view
        override
        returns (
            uint128 currentApprovalVoteSum,
            uint128 currentDenialVoteSum,
            uint128 appliedMinimumVote,
            uint32 preVoteDeadline,
            uint32 mainVoteDeadline,
            uint32 expiration,
            bool lockin,
            bool applied
        )
    {
        preVoteDeadline = _proposeStatus[proposeId].preVoteDeadline;
        mainVoteDeadline = _proposeStatus[proposeId].mainVoteDeadline;
        expiration = _proposeStatus[proposeId].expiration;
        appliedMinimumVote = _proposeStatus[proposeId].appliedMinimumVote;
        currentApprovalVoteSum = _proposeStatus[proposeId].currentApprovalVoteSum;
        currentDenialVoteSum = _proposeStatus[proposeId].currentDenialVoteSum;
        lockin = _proposeStatus[proposeId].lockin;
        applied = _proposeStatus[proposeId].applied;
    }

    /**
     * @notice Get the status of multiple proposals.
     * @param offset is a proposal index. If 0 is given, this function searches from the latest proposal.
     * @param limit is the number of proposals you query. If 0 is given, this function returns all proposals.
     * @return allProposals which is the list of the from `[..., proposeId_k, votingResult_k, otherProposalStatus_k, ...]`
     *  (k = offset, ..., offset - limit + 1), where votingResult_k is the binary of the form.
     * `currentApprovalVoteSum_k << 128 | currentDenialVoteSum_k` and otherProposalStatus_k is the binary of the form.
     * `appliedMinimumVote_k << 128 | preVoteDeadline_k << 96 | mainVoteDeadline_k << 64 | expiration_k << 32
     *                              | lockin_k << 24 | applied_k << 16`.
     */
    function getProposals(uint256 offset, uint256 limit)
        external
        view
        override
        returns (bytes32[] memory allProposals)
    {
        if (offset == 0 || offset >= _proposalList.length) {
            offset = _proposalList.length - 1;
        }

        if (limit == 0 || limit > offset) {
            limit = offset;
        }

        allProposals = new bytes32[](3 * limit);
        for (uint256 i = 0; i < limit; i++) {
            bytes32 proposeId = _proposalList[offset - i];
            ProposeStatus memory proposeStatus = _proposeStatus[proposeId];
            allProposals[3 * i] = proposeId;
            allProposals[3 * i + 1] = abi.decode(
                abi.encodePacked(
                    proposeStatus.currentApprovalVoteSum,
                    proposeStatus.currentDenialVoteSum
                ),
                (bytes32)
            );
            allProposals[3 * i + 2] = abi.decode(
                abi.encodePacked(
                    proposeStatus.appliedMinimumVote,
                    proposeStatus.preVoteDeadline,
                    proposeStatus.mainVoteDeadline,
                    proposeStatus.expiration,
                    proposeStatus.lockin,
                    proposeStatus.applied,
                    bytes2(0) // padding
                ),
                (bytes32)
            );
        }
    }

    /**
     * @notice Get the info of the updating core parameters proposal.
     */
    function getInfoUpdateCoreParameters(bytes32 proposeId)
        external
        view
        override
        returns (
            uint64 preVoteLength,
            uint64 totalVoteLength,
            uint64 expirationLength,
            uint16 minVoteE4,
            uint16 minVoteCoreE4,
            uint16 minCommitE4
        )
    {
        preVoteLength = _proposeUpdateCore[proposeId].preVoteLength;
        totalVoteLength = _proposeUpdateCore[proposeId].totalVoteLength;
        expirationLength = _proposeUpdateCore[proposeId].expirationLength;
        minVoteE4 = _proposeUpdateCore[proposeId].minVoteE4;
        minVoteCoreE4 = _proposeUpdateCore[proposeId].minVoteCoreE4;
        minCommitE4 = _proposeUpdateCore[proposeId].minCommitE4;
    }

    /**
     * @notice Get the info of the listing proposal.
     */
    function getInfoUpdateWhitelist(bytes32 proposeId)
        external
        view
        override
        returns (address tokenAddress, address oracleAddress)
    {
        tokenAddress = _proposeList[proposeId].tokenAddress;
        oracleAddress = _proposeList[proposeId].oracleAddress;
    }

    /**
     * @notice Get the info of the delisting proposal.
     */
    function getInfoDelistWhitelist(bytes32 proposeId)
        external
        view
        override
        returns (address tokenAddress)
    {
        tokenAddress = _proposeDelist[proposeId].tokenAddress;
    }

    /**
     * @notice Get the info of the updating incentive proposal.
     */
    function getInfoUpdateIncentive(bytes32 proposeId)
        external
        view
        override
        returns (address[] memory incentiveAddresses, uint256[] memory incentiveAllocation)
    {
        incentiveAddresses = _proposeUpdateIncentive[proposeId].incentiveAddresses;
        incentiveAllocation = _proposeUpdateIncentive[proposeId].incentiveAllocation;
    }
}