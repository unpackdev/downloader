/**
 * SPDX-License-Identifier: MIT
 https://t.me/DoodlePepeERC20
 https://twitter.com/DoodlePepeERC20
 https://doodlepepe.vip/
 */
pragma solidity ^0.8.19;

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error ERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
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
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
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
     * `requestedDecrease`.
     *
     * NOTE: Although this function is designed to avoid double spending with {approval},
     * it can still be frontrunned, preventing any attempt of allowance reduction.
     */
    function decreaseAllowance(address spender, uint256 requestedDecrease) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < requestedDecrease) {
            revert ERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
        }
        unchecked {
            _approve(owner, spender, currentAllowance - requestedDecrease);
        }

        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from` (or `to`) is
     * the zero address. All customizations to transfers, mints, and burns should be done by overriding this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, by transferring it to address(0).
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
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
    function _approve(address owner, address spender, uint256 value) internal virtual {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Alternative version of {_approve} with an optional flag that can enable or disable the Approval event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to true
     * using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

interface IUniV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract DOODLEPEPE is ERC20, Ownable {
    using SafeMath for uint256;

    IUniV2Router public immutable uniV2Router;
    address public immutable uniV2Pair;

    // Swapback
    bool private _duringSwapBack;
    bool public _swapForFeesEnabled = false;
    uint256 public _minSwapbackTreshold;
    uint256 public _maxSwapbackLimit;

    //Anti-whale
    bool public _launchTradingLimitsInPlace = true;
    bool public _sameBlockTxLimitOn = true;
    uint256 public _maxWalletPerAddress;
    uint256 public _maxTokensPerTransfer;
    mapping(address => uint256) private lastTransferBlock; // to hold last Transfers temporarily during launch

    // Fee receivers
    address public _feeReceiverWallet1;
    address public _feeReceiverWallet2;

    bool public _isTradingEnabled = false;

    uint256 public _totalFeeForBuys;
    uint256 public _fee1ForBuy;
    uint256 public _fee2ForBuy;

    uint256 public _totalFeeForSells;
    uint256 public _fee1ForSell;
    uint256 public _fee2ForSell;

    uint256 public _tokensForReceiver1;
    uint256 public _tokensForReceiver2;

    /******************/

    // exclude from fees and max transaction amount
    mapping(address => bool) private feeWhitelisted;
    mapping(address => bool) public _txLimitWhitelisted;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public _isDexPair;

    event AddressExcludedFromFees(address indexed account, bool isExcluded);

    event SetDexPair(address indexed pair, bool indexed value);

    event _feeReceiverWallet1Updated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event _feeReceiverWallet2Updated(
        address indexed newWallet,
        address indexed oldWallet
    );

    constructor() ERC20("DOODLE PEPE", "DOPE") {
        IUniV2Router _uniV2Router = IUniV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        exemptFromTxLim(address(_uniV2Router), true);
        uniV2Router = _uniV2Router;

        uniV2Pair = IUniV2Factory(_uniV2Router.factory())
            .createPair(address(this), _uniV2Router.WETH());
        exemptFromTxLim(address(uniV2Pair), true);
        SetAsDexPair(address(uniV2Pair), true);

        uint256 tokenSupply = 1000000000 * 1e18;

        _maxTokensPerTransfer = (tokenSupply * 2) / 100; // 1% of total supply
        _maxWalletPerAddress = (tokenSupply * 2) / 100; // 1% of total supply

        _minSwapbackTreshold = (tokenSupply * 5) / 10000; // 0.05% swapback trigger
        _maxSwapbackLimit = (tokenSupply * 7) / 100; // 7% max swapback

        _fee1ForBuy = 25;
        _fee2ForBuy = 0;
        _totalFeeForBuys = _fee1ForBuy + _fee2ForBuy;

        _fee1ForSell = 45;
        _fee2ForSell = 0;
        _totalFeeForSells = _fee1ForSell + _fee2ForSell;

        _feeReceiverWallet1 = 0x3B7172c158996F1E632FB8Ca530Ae729a778894D;
        _feeReceiverWallet2 = address(msg.sender);

        // exclude from paying fees or having max transaction amount
        exemptFromSwapFees(owner(), true);
        exemptFromSwapFees(address(this), true);
        exemptFromSwapFees(address(0xdead), true);
        exemptFromSwapFees(_feeReceiverWallet1, true);

        exemptFromTxLim(owner(), true);
        exemptFromTxLim(address(this), true);
        exemptFromTxLim(address(0xdead), true);
        exemptFromTxLim(_feeReceiverWallet1, true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, tokenSupply);
    }

    receive() external payable {}

    /// @notice Launches the token and enables trading. Irriversable.
    function lonchTheCoin() external onlyOwner {
        _isTradingEnabled = true;
        _swapForFeesEnabled = true;
    }

    /// @notice Removes the max wallet and max transaction limits
    function limitsOff() external onlyOwner returns (bool) {
        _launchTradingLimitsInPlace = false;
        return true;
    }

    /// @notice Disables the Same wallet block transfer delay
    function removeSameBlockRes() external onlyOwner returns (bool) {
        _sameBlockTxLimitOn = false;
        return true;
    }

    function changeMinSwapbackTresh(
        uint256 newAmount
    ) external onlyOwner returns (bool) {
        require(
            newAmount >= totalSupply() / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (500 * totalSupply()) / 100000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        require(
            newAmount <= _maxSwapbackLimit,
            "Swap amount cannot be higher than _maxSwapbackLimit"
        );
        _minSwapbackTreshold = newAmount;
        return true;
    }

    function changeMaxSwapbackLim(
        uint256 newAmount
    ) external onlyOwner returns (bool) {
        require(
            newAmount >= _minSwapbackTreshold,
            "Swap amount cannot be lower than _minSwapbackTreshold"
        );
        _maxSwapbackLimit = newAmount;
        return true;
    }

    /// @notice Changes the maximum amount of tokens that can be bought or sold in a single transaction
    /// @param newNum Base 1000, so 1% = 10
    function changeMaxTokensPerTrans(uint256 newNum) external onlyOwner {
        require(newNum >= 2, "Cannot set _maxTokensPerTransfer lower than 0.2%");
        _maxTokensPerTransfer = (newNum * totalSupply()) / 1000;
    }

    /// @notice Changes the maximum amount of tokens a wallet can hold
    /// @param newNum Base 1000, so 1% = 10
    function changeMaxWalletPerAdd(uint256 newNum) external onlyOwner {
        require(newNum >= 5, "Cannot set _maxWalletPerAddress lower than 0.5%");
        _maxWalletPerAddress = (newNum * totalSupply()) / 1000;
    }

    /// @notice Sets if a wallet is excluded from the max wallet and tx limits
    /// @param updAds The wallet to update
    /// @param isEx If the wallet is excluded or not
    function exemptFromTxLim(
        address updAds,
        bool isEx
    ) public onlyOwner {
        _txLimitWhitelisted[updAds] = isEx;
    }

    /// @notice Sets if the contract can sell tokens
    /// @param enabled set to false to disable selling
    function changeSwapForFeesEna(bool enabled) external onlyOwner {
        _swapForFeesEnabled = enabled;
    }

    /// @notice Sets the fees for buys
    /// @param _treasuryFee The fee for the treasury wallet
    /// @param _projectFee The fee for the dev wallet
    function chngeFeesForBuys(
        uint256 _treasuryFee,
        uint256 _projectFee
    ) external onlyOwner {
        _fee1ForBuy = _treasuryFee;
        _fee2ForBuy = _projectFee;
        _totalFeeForBuys = _fee1ForBuy + _fee2ForBuy;
        require(_totalFeeForBuys <= 12, "Must keep fees at 12% or less");
    }

    /// @notice Sets the fees for sells
    /// @param _treasuryFee The fee for the treasury wallet
    /// @param _projectFee The fee for the dev wallet
    function chngeFeesForSells(
        uint256 _treasuryFee,
        uint256 _projectFee
    ) external onlyOwner {
        _fee1ForSell = _treasuryFee;
        _fee2ForSell = _projectFee;
        _totalFeeForSells = _fee1ForSell + _fee2ForSell;
        require(_totalFeeForSells <= 12, "Must keep fees at 12% or less");
    }

    /// @notice Sets if a wallet is excluded from fees
    /// @param account The wallet to update
    /// @param excluded If the wallet is excluded or not
    function exemptFromSwapFees(address account, bool excluded) public onlyOwner {
        feeWhitelisted[account] = excluded;
        emit AddressExcludedFromFees(account, excluded);
    }

    /// @notice Sets an address as a new liquidity pair. You probably dont want to do this.
    /// @param pair The new pair
    function chngeAddressIsDexPair(
        address pair,
        bool value
    ) public onlyOwner {
        require(
            pair != uniV2Pair,
            "The pair cannot be removed from _isDexPair"
        );

        SetAsDexPair(pair, value);
    }

    function SetAsDexPair(address pair, bool value) private {
        _isDexPair[pair] = value;

        emit SetDexPair(pair, value);
    }

    /// @notice Sets a wallet as the new fee receiver 1 wallet
    /// @param newFeeReceiver1 The new fee receiver 1 wallet
    function chngeFeeReceiver1(
        address newFeeReceiver1
    ) external onlyOwner {
        emit _feeReceiverWallet1Updated(newFeeReceiver1, _feeReceiverWallet1);
        _feeReceiverWallet1 = newFeeReceiver1;
    }

    /// @notice Sets a wallet as the new fee receiver 2 wallet
    /// @param newFeeReceiver2 The new fee receiver 2 wallet
    function chngeFeeReceiver2(address newFeeReceiver2) external onlyOwner {
        emit _feeReceiverWallet2Updated(newFeeReceiver2, _feeReceiverWallet2);
        _feeReceiverWallet2 = newFeeReceiver2;
    }

    function isAddWhitelistedFromFees(address account) public view returns (bool) {
        return feeWhitelisted[account];
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (amount == 0) {
            super._update(from, to, 0);
            return;
        }

        if (_launchTradingLimitsInPlace) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !_duringSwapBack
            ) {
                if (!_isTradingEnabled) {
                    require(
                        feeWhitelisted[from] || feeWhitelisted[to],
                        "Trading is not active."
                    );
                }

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
                if (_sameBlockTxLimitOn) {
                    if (
                        to != owner() &&
                        to != address(uniV2Router) &&
                        to != address(uniV2Pair)
                    ) {
                        require(
                            lastTransferBlock[tx.origin] <
                                block.number,
                            "_update:: Transfer Delay enabled.  Only one purchase per block allowed."
                        );
                        lastTransferBlock[tx.origin] = block.number;
                    }
                }

                //when buy
                if (_isDexPair[from] && !_txLimitWhitelisted[to]) {
                    require(
                        amount <= _maxTokensPerTransfer,
                        "Buy transfer amount exceeds the _maxTokensPerTransfer."
                    );
                    require(
                        amount + balanceOf(to) <= _maxWalletPerAddress,
                        "Max wallet exceeded"
                    );
                }
                //when sell
                else if (
                    _isDexPair[to] && !_txLimitWhitelisted[from]
                ) {
                    require(
                        amount <= _maxTokensPerTransfer,
                        "Sell transfer amount exceeds the _maxTokensPerTransfer."
                    );
                } else if (!_txLimitWhitelisted[to]) {
                    require(
                        amount + balanceOf(to) <= _maxWalletPerAddress,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= _minSwapbackTreshold;

        if (
            canSwap &&
            _swapForFeesEnabled &&
            !_duringSwapBack &&
            !_isDexPair[from] &&
            !feeWhitelisted[from] &&
            !feeWhitelisted[to]
        ) {
            _duringSwapBack = true;

            swapTaxesForETH();

            _duringSwapBack = false;
        }

        bool takeFee = !_duringSwapBack;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (feeWhitelisted[from] || feeWhitelisted[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (_isDexPair[to] && _totalFeeForSells > 0) {
                fees = amount.mul(_totalFeeForSells).div(100);
                _tokensForReceiver2 += (fees * _fee2ForSell) / _totalFeeForSells;
                _tokensForReceiver1 += (fees * _fee1ForSell) / _totalFeeForSells;
            }
            // on buy
            else if (_isDexPair[from] && _totalFeeForBuys > 0) {
                fees = amount.mul(_totalFeeForBuys).div(100);
                _tokensForReceiver2 += (fees * _fee2ForBuy) / _totalFeeForBuys;
                _tokensForReceiver1 += (fees * _fee1ForBuy) / _totalFeeForBuys;
            }

            if (fees > 0) {
                super._update(from, address(this), fees);
            }

            amount -= fees;
        }

        super._update(from, to, amount);
    }

    function swapExactTokensForETHOnUniV2Router(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniV2Router.WETH();

        _approve(address(this), address(uniV2Router), tokenAmount);

        // make the swap
        uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapTaxesForETH() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _tokensForReceiver1 + _tokensForReceiver2;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > _maxSwapbackLimit) {
            contractBalance = _maxSwapbackLimit;
        }

        uint256 initialETHBalance = address(this).balance;

        swapExactTokensForETHOnUniV2Router(contractBalance);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForProject = ethBalance.mul(_tokensForReceiver2).div(totalTokensToSwap);

        _tokensForReceiver1 = 0;
        _tokensForReceiver2 = 0;

        (success, ) = address(_feeReceiverWallet2).call{value: ethForProject}("");

        (success, ) = address(_feeReceiverWallet1).call{
            value: address(this).balance
        }("");
    }
}