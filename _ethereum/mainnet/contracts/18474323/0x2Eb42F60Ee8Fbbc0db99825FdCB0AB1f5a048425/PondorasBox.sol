/**
 * SPDX-License-Identifier: MIT
 * https://twitter.com/PondorasBox
 * https://t.me/pondorasbox
 * https://pondorasbox.vip/
 */
pragma solidity 0.8.19;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function transferFrom(
        address sender,
        address recipient,
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
     * Emits an {Approval} event indicating the upd allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the upd allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the upd allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract PondorasBox is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniV2R;
    address public immutable uniV2P;

    // Swapback
    bool private swapping;
    bool public SBEnabled = false;
    uint256 public swapBRangeMin;
    uint256 public swapBRangeMax;

    //Anti-whale
    bool public limitsInEffect = true;
    bool public transferDelayEnabled = true;
    uint256 public walletLmt;
    uint256 public txLmt;
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch

    // Fee receivers
    address public liquidityHolder;
    address public marketingWallet;
    address public teamWallet;


    bool public tradingOn = false;

    uint256 public totBuy;
    uint256 public mktBuy;
    uint256 public lpBuy;
    uint256 public devBuy;

    uint256 public totSell;
    uint256 public mktSell;
    uint256 public lpSell;
    uint256 public devSell;

    uint256 public marketingSwapback;
    uint256 public lpSwapback;
    uint256 public devSwapback;

    /******************/

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isFeeExempt;
    mapping(address => bool) public _isTxLimitExempt;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event marketingWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event teamWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() ERC20("Pondoras Box", "PNDBOX") {
        IUniswapV2Router02 _uniV2R = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        excludeFromMaxTransaction(address(_uniV2R), true);
        uniV2R = _uniV2R;

        uniV2P = IUniswapV2Factory(_uniV2R.factory())
            .createPair(address(this), _uniV2R.WETH());
        excludeFromMaxTransaction(address(uniV2P), true);
        _setAutomatedMarketMakerPair(address(uniV2P), true);

        uint256 _mktBuy = 30;
        uint256 _lpBuy = 0;
        uint256 _devBuy = 0;

        uint256 _mktSell = 50;
        uint256 _lpSell = 0;
        uint256 _devSell = 0;

        uint256 totalSupply = 420690000000000 * 1e18;

        txLmt = (totalSupply * 10) / 1000;
        walletLmt = (totalSupply * 10) / 1000;

        swapBRangeMin = (totalSupply * 2) / 1000; // 0.2% swapback trigger
        swapBRangeMax = (totalSupply * 4) / 100; // 4% max swapback

        mktBuy = _mktBuy;
        lpBuy = _lpBuy;
        devBuy = _devBuy;
        totBuy = mktBuy + lpBuy + devBuy;

        mktSell = _mktSell;
        lpSell = _lpSell;
        devSell = _devSell;
        totSell = mktSell + lpSell + devSell;

        marketingWallet = address(0xfC33cD35c20360A2Ae1749C2304C9BD161A44a79); 
        teamWallet = address(msg.sender);
        liquidityHolder = msg.sender;

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(marketingWallet, true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        excludeFromMaxTransaction(marketingWallet, true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    /// @dev Launches the token and enables trading
    function openTheBox() external onlyOwner {
        tradingOn = true;
        SBEnabled = true;
    }

    /// @dev Launches the token and enables trading
    function enableTrading() external onlyOwner {
        tradingOn = true;
        SBEnabled = true;
    }

    /// @dev Removes the max wallet and max transaction limits
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    /// @dev Disables the Same wallet block transfer delay
    function disableTransferDelay() external onlyOwner returns (bool) {
        transferDelayEnabled = false;
        return true;
    }

    /// @dev Changes the minimum balance of tokens the contract must have before swapping tokens for ETH. Base 100000, so 0.5% = 500.
    function upSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= totalSupply()/ 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= 500 * totalSupply()/ 100000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        require(
            newAmount <= swapBRangeMax,
            "Swap amount cannot be higher than swapBRangeMax"
        );
        swapBRangeMin = newAmount;
        return true;
    }

    /// @dev Changes the maximum amount of tokens the contract can swap for ETH. Base 10000, so 0.5% = 50.
    function upMaxTokensForSwapback(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= swapBRangeMin,
            "Swap amount cannot be lower than swapBRangeMin"
        );
        swapBRangeMax = newAmount;
        return true;
    }

    /// @dev Changes the maximum amount of tokens that can be bought or sold in a single transaction
    /// @param newNum Base 1000, so 1% = 10
    function upMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= 2,
            "Cannot set txLmt lower than 0.2%"
        );
        txLmt = newNum * (10**18);
    }

    /// @dev Changes the maximum amount of tokens a wallet can hold
    /// @param newNum Base 1000, so 1% = 10
    function upMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= 5,
            "Cannot set walletLmt lower than 0.5%"
        );
        walletLmt = newNum * totalSupply()/1000;
    }


    /// @dev Sets if a wallet is excluded from the max wallet and tx limits
    /// @param updAds The wallet to update
    /// @param isEx If the wallet is excluded or not
    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isTxLimitExempt[updAds] = isEx;
    }

    /// @dev Sets if the contract can sell tokens
    /// @param enabled set to false to disable selling
    function upSwapEnabled(bool enabled) external onlyOwner {
        SBEnabled = enabled;
    }
    
    /// @dev Sets the fees for buys
    /// @param _marketingFee The fee for the marketing wallet
    /// @param _liquidityFee The fee for the liquidity pool
    /// @param _devFee The fee for the dev wallet
    function setBuyFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _devFee
    ) external onlyOwner {
        mktBuy = _marketingFee;
        lpBuy = _liquidityFee;
        devBuy = _devFee;
        totBuy = mktBuy + lpBuy + devBuy;
    }

    /// @dev Sets the fees for sells
    /// @param _marketingFee The fee for the marketing wallet
    /// @param _liquidityFee The fee for the liquidity pool
    /// @param _devFee The fee for the dev wallet
    function setSellFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _devFee
    ) external onlyOwner {
        mktSell = _marketingFee;
        lpSell = _liquidityFee;
        devSell = _devFee;
        totSell = mktSell + lpSell + devSell;
    }

    /// @dev Sets if a wallet is excluded from fees
    /// @param account The wallet to up
    /// @param excluded If the wallet is excluded or not
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isFeeExempt[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    /// @dev Sets an address as a new liquidity pair. You probably dont want to do this.
    /// @param pair The new pair
    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniV2P,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function upMarketingWallet(address newMarketingWallet)
        external
        onlyOwner
    {
        emit marketingWalletUpdated(newMarketingWallet, marketingWallet);
        marketingWallet = newMarketingWallet;
    }

    function upLPWallet(address newLPWallet)
        external
        onlyOwner
    {
        liquidityHolder = newLPWallet;
    }

    function upDevWallet(address newWallet) external onlyOwner {
        emit teamWalletUpdated(newWallet, teamWallet);
        teamWallet = newWallet;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isFeeExempt[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!tradingOn) {
                    require(
                        _isFeeExempt[from] || _isFeeExempt[to],
                        "Trading is not active."
                    );
                }

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
                if (transferDelayEnabled) {
                    if (
                        to != owner() &&
                        to != address(uniV2R) &&
                        to != address(uniV2P)
                    ) {
                        require(
                            _holderLastTransferTimestamp[tx.origin] <
                                block.number,
                            "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                        );
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }

                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isTxLimitExempt[to]
                ) {
                    require(
                        amount <= txLmt,
                        "Buy transfer amount exceeds the txLmt."
                    );
                    require(
                        amount + balanceOf(to) <= walletLmt,
                        "Max wallet exceeded"
                    );
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isTxLimitExempt[from]
                ) {
                    require(
                        amount <= txLmt,
                        "Sell transfer amount exceeds the txLmt."
                    );
                } else if (!_isTxLimitExempt[to]) {
                    require(
                        amount + balanceOf(to) <= walletLmt,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapBRangeMin;

        if (
            canSwap &&
            SBEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isFeeExempt[from] &&
            !_isFeeExempt[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isFeeExempt[from] || _isFeeExempt[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && totSell > 0) {
                fees = amount.mul(totSell).div(100);
                lpSwapback += (fees * lpSell) / totSell;
                devSwapback += (fees * devSell) / totSell;
                marketingSwapback += (fees * mktSell) / totSell;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && totBuy > 0) {
                fees = amount.mul(totBuy).div(100);
                lpSwapback += (fees * lpBuy) / totBuy;
                devSwapback += (fees * devBuy) / totBuy;
                marketingSwapback += (fees * mktBuy) / totBuy;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniV2R.WETH();

        _approve(address(this), address(uniV2R), tokenAmount);

        // make the swap
        uniV2R.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniV2R), tokenAmount);

        // add the liquidity
        uniV2R.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityHolder,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = lpSwapback +
            marketingSwapback +
            devSwapback;
        bool success;

        if (contractBalance == 0) {
            return;
        }

        if (contractBalance > swapBRangeMax) {
            contractBalance = swapBRangeMax;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * lpSwapback) /
            totalTokensToSwap /
            2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMarketing = ethBalance.mul(marketingSwapback).div(
            totalTokensToSwap
        );
        uint256 ethForDev = ethBalance.mul(devSwapback).div(totalTokensToSwap);

        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForDev;

        lpSwapback = 0;
        marketingSwapback = 0;
        devSwapback = 0;

        (success, ) = address(teamWallet).call{value: ethForDev}("");

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                lpSwapback
            );
        }

        (success, ) = address(marketingWallet).call{
            value: address(this).balance
        }("");
    }

}