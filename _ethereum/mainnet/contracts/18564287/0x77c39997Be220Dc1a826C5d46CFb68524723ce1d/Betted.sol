// Sources flattened with hardhat v2.12.7 https://hardhat.org

// File @openzeppelin/contracts/utils/Context.sol@v4.8.1

// SPDX-License-Identifier: MIT
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


// File @openzeppelin/contracts/access/Ownable.sol@v4.8.1

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


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.8.1

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// File @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol@v4.8.1

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


// File @openzeppelin/contracts/token/ERC20/ERC20.sol@v4.8.1

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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


// File @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol@v1.1.0-beta.0

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


// File @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol@v1.1.0-beta.0

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


// File @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol@v1.0.1

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// File @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol@v1.0.1

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


// File contracts/TaxableToken.sol

pragma solidity ^0.8.9;
abstract contract TaxableToken is Ownable {

	event TaxEnabled();
	event TaxDisabled();
    event TaxRateUpdated(uint newMarketingTaxRate, uint newDevTaxRate);
	event MarketingAddressChanged(address marketingAddress);
	event DevAddressChanged(address devAddress);
    event ExcludedFromTaxStatusUpdated(address target, bool newStatus);
    event TradingPairStatusUpdated(address pair, bool newStatus);

	bool internal _isTaxEnabled;
    uint32 internal _balanceToSwapAt;

	uint8 internal _marketingTaxRate;
    uint8 internal _devTaxRate;

    uint8 internal immutable _initialMarketingTaxRate;
    uint8 internal immutable _initialDevTaxRate;
    
    address payable internal _marketingAddress;
    address payable internal _devAddress;

    mapping(address => bool) public _excludedFromTax;

    address internal _baseTradingPair;
    mapping(address => bool) public automatedMarketMakerPairs;

	constructor(bool isTaxEnabled_, uint8 marketingTaxRate_, uint8 devTaxRate_, address marketingAddress_, address devAddress_) {
        _isTaxEnabled = isTaxEnabled_;
        _balanceToSwapAt = 0;

        _marketingTaxRate = marketingTaxRate_;
        _initialMarketingTaxRate = _marketingTaxRate;

        _devTaxRate = devTaxRate_;
        _initialDevTaxRate = _devTaxRate;

        _marketingAddress = payable(marketingAddress_);
        _devAddress = payable(devAddress_);

        _excludedFromTax[_msgSender()] = true;
        _excludedFromTax[_marketingAddress] = true;
        _excludedFromTax[_devAddress] = true;
        _excludedFromTax[address(0)] = true;
        _excludedFromTax[address(this)] = true;
    }

	modifier whenTaxDisabled() {
        _requireTaxDisabled();
        _;
    }

	modifier whenTaxEnabled() {
        _requireTaxEnabled();
        _;
    }

    function enableTax() public onlyOwner whenTaxDisabled {
        _enableTax();
    }

    function disableTax() public onlyOwner whenTaxEnabled {
        _disableTax();
    }

	function isTaxEnabled() public view returns (bool) {
        return _isTaxEnabled;
    }

    function getTotalTaxRate() public view returns (uint) {
        return _marketingTaxRate + _devTaxRate;
    }

    function updateTaxRate(uint8 newMarketingTaxRate, uint8 newDevTaxRate) public onlyOwner {
        require(newMarketingTaxRate <= _initialMarketingTaxRate, "TaxableToken: Cannot increase marketing tax rate above initial rate.");
        require(newDevTaxRate <= _initialDevTaxRate, "TaxableToken: Cannot increase dev tax rate above initial rate.");
        require((newMarketingTaxRate + newDevTaxRate) > 0, "TaxableToken: Cannot reduce taxes to/below 0. Disable taxes instead.");

        _updateTaxRate(newMarketingTaxRate, newDevTaxRate);
    }

    function getMarketingAddress() public view returns (address) {
        return _marketingAddress;
    }

    function getDevAddress() public view returns (address) {
        return _devAddress;
    }

    function updateMarketingAddress(address newMarketingAddress) public onlyOwner {
        require(newMarketingAddress != address(0), "TaxableToken: Cannot set marketing address to 0");
        require(newMarketingAddress != address(0xdead), "TaxableToken: Cannot set marketing address to dead address");
        require(newMarketingAddress != _devAddress, "TaxableToken: Marketing and dev address cannot be the same");

        _updateMarketingAddress(newMarketingAddress);
    }

    function updateDevAddress(address newDevAddress) public onlyOwner {
        require(newDevAddress != address(0), "TaxableToken: Cannot set dev address to 0");
        require(newDevAddress != address(0xdead), "TaxableToken: Cannot set dev address to dead address");
        require(newDevAddress != _marketingAddress, "TaxableToken: Marketing and dev address cannot be the same");

        _updateDevAddress(newDevAddress);
    }

    function updateTradingPairStatus(address pair, bool status) public onlyOwner {
        require(pair != _baseTradingPair, "TaxableToken: Cannot change status of base trading pair");

        _updateTradingPairStatus(pair, status);
    }

    function updateExcludedFromTax(address target, bool status) public onlyOwner {
        require(!automatedMarketMakerPairs[target], "TaxableToken: Cannot change excludedFromTax status of base trading pair");

        _updateExcludedFromTaxStatus(target, status);
    }

    function isExcludedFromTax(address target) public view returns (bool) {
        return _excludedFromTax[target];
    }

	function _requireTaxDisabled() internal view {
        require(!isTaxEnabled(), "TaxableToken: Tax must be disabled");
    }

	function _requireTaxEnabled() internal view {
        require(isTaxEnabled(), "TaxableToken: Tax must be enabled");
    }

	function _enableTax() internal whenTaxDisabled {
        _isTaxEnabled = true;
        emit TaxEnabled();
    }

	function _disableTax() internal whenTaxEnabled {
        _isTaxEnabled = false;
        emit TaxDisabled();
    }

    function _setSwapAtBalance(uint32 balanceToSwapAt) internal {
        require(balanceToSwapAt > 0, "TaxableToken: Balance to swap at must be more than zero");
        _balanceToSwapAt = balanceToSwapAt;
    }

    function _isBalanceEnoughToSwap(uint contractBalance) internal view returns (bool) {
        return contractBalance > _balanceToSwapAt;
    }

    function _updateTaxRate(uint8 newMarketingTaxRate, uint8 newDevTaxRate) internal {
        _marketingTaxRate = newMarketingTaxRate;
        _devTaxRate = newDevTaxRate;

        emit TaxRateUpdated(_marketingTaxRate, _devTaxRate);
    }

    function _updateMarketingAddress(address newMarketingAddress) internal {
        _marketingAddress = payable(newMarketingAddress);
        emit MarketingAddressChanged(newMarketingAddress);
    }

    function _updateDevAddress(address newDevAddress) internal {
        _devAddress = payable(newDevAddress);
        emit DevAddressChanged(_devAddress);
    }

    function _updateExcludedFromTaxStatus(address target, bool newStatus) internal {
        _excludedFromTax[target] = newStatus;
        emit ExcludedFromTaxStatusUpdated(target, newStatus);
    }

    function _updateTradingPairStatus(address pair, bool newStatus) internal {
        automatedMarketMakerPairs[pair] = newStatus;
        emit TradingPairStatusUpdated(pair, newStatus);
    }

    function _getMarketingTaxFee(uint amount) internal view returns (uint) {
        return (amount * _marketingTaxRate) / 1000;
    }

    function _getDevTaxFee(uint amount) internal view returns (uint) {
        return (amount * _devTaxRate) / 1000;
    }

    function _getMarketingTaxSplit(uint tokensToSplit) internal view returns (uint) {
        uint taxSplitParts = getTotalTaxRate();
        return (tokensToSplit * _marketingTaxRate) / taxSplitParts;
    }

    function _sendEthToTaxRecipients() internal {
        uint contractBalance = address(this).balance;
        bool success;

        if (contractBalance > 0) {
            uint ethForMarketing = _getMarketingTaxSplit(contractBalance);
            uint ethForDev = contractBalance - ethForMarketing;

            (success, ) = address(_marketingAddress).call{value: ethForMarketing}("");
            (success, ) = address(_devAddress).call{value: ethForDev}("");
        }
    }
}


// File contracts/Betted.sol

pragma solidity ^0.8.9;
contract Betted is ERC20, TaxableToken {
    IUniswapV2Router02 private immutable _uniswapV2Router;
    IUniswapV2Factory private immutable _uniswapV2Factory;
    IUniswapV2Pair private immutable _uniswapV2WethPair;

    mapping(address => uint) private _lastTransactionBlockNumber;
    mapping(address => bool) private _blacklistedAddresses;
    mapping(address => bool) private _excludedFromBlacklisting;
    mapping(address => bool) private _excludedFromMaxWallet;
    mapping(address => bool) private _whitelistedAddresses;
    mapping(address => uint) private _whitelistBuyAmounts;

    bool private _whitelistEnabled;
    bool private _isTransferringTax;

    uint private immutable _maxSupply;
    uint private immutable _maxWallet;
    uint private immutable _whitelistMaxBuy;
    
    constructor()
        ERC20("Betted", "BETS")
        TaxableToken(true, 245, 5, 0x61E87D52d5a358eE83043a6d918A2E867e44bD2f, 0x5d7379995772b2eb7f617A524C49D170De4632DB) {

        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
        _uniswapV2WethPair = IUniswapV2Pair(_uniswapV2Factory.createPair(address(this), _uniswapV2Router.WETH()));

        _baseTradingPair = address(_uniswapV2WethPair);
        automatedMarketMakerPairs[_baseTradingPair] = true;

        _excludedFromBlacklisting[_msgSender()] = true;
        _excludedFromBlacklisting[_baseTradingPair] = true;
        _excludedFromBlacklisting[_marketingAddress] = true;
        _excludedFromBlacklisting[_devAddress] = true;
        _excludedFromBlacklisting[address(0)] = true;
        _excludedFromBlacklisting[address(this)] = true;

        _excludedFromMaxWallet[_msgSender()] = true;
        _excludedFromMaxWallet[_baseTradingPair] = true;
        _excludedFromMaxWallet[_marketingAddress] = true;
        _excludedFromMaxWallet[_devAddress] = true;
        _excludedFromMaxWallet[address(0)] = true;
        _excludedFromMaxWallet[address(this)] = true;

        _whitelistedAddresses[_msgSender()] = true;
        _whitelistedAddresses[_baseTradingPair] = true;
        _whitelistedAddresses[_marketingAddress] = true;
        _whitelistedAddresses[_devAddress] = true;
        _whitelistedAddresses[address(0)] = true;
        _whitelistedAddresses[address(this)] = true;

        _whitelistEnabled = true;

        _maxSupply = 1_000_000_000 * (10 ** decimals());
        _maxWallet = _maxSupply / 100;

        uint twoEth = 2 * (10 ** decimals());
        _whitelistMaxBuy = twoEth / 10;

        _mint(_msgSender(), _maxSupply);
        _setSwapAtBalance(uint32(500_000 * (10 ** decimals())));
    }

    function isAddressBlacklistedFromBuying(address target) public view returns (bool) {
        return _blacklistedAddresses[target];
    }

    function removeAddressFromBlacklist(address target) public onlyOwner {
        _removeAddressFromBlacklist(target);
    }

    function isAddressExcludedFromBlacklisting(address target) public view returns (bool) {
        return _excludedFromBlacklisting[target];
    }

    function isAddressWhitelisted(address target) public view returns (bool) {
        return _whitelistedAddresses[target];
    }

    function addAddressToWhitelist(address target) public onlyOwner {
        _whitelistedAddresses[target] = true;
    }

    function isWhitelistEnabled() public view returns (bool) {
        return _whitelistEnabled;
    }

    function disableWhitelist() public onlyOwner {
        _whitelistEnabled = false;
    }

    function excludeFromMaxWallet(address target) public onlyOwner {
        _excludedFromMaxWallet[target] = true;
    }

    function getLastTransactionBlockNumber(address target) public view returns (uint) {
        return _lastTransactionBlockNumber[target];
    }

    function claimTaxes() public onlyOwner {
        _isTransferringTax = true;
        _swapAndClaimTaxes();
        _isTransferringTax = false;
    }

    function _removeAddressFromBlacklist(address target) private onlyOwner {
        _blacklistedAddresses[target] = false;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: Cannot transfer from the zero address");
        require(amount > 0, "ERC20: Must transfer more than zero");

        if (!_excludedFromMaxWallet[to]) {
            require((balanceOf(to) + amount) <= _maxWallet, "BETS: Max amount per wallet is 1% of total supply");
        }

        if (!_isTransferringTax && _isBalanceEnoughToSwap(balanceOf(address(this))) && automatedMarketMakerPairs[to]) {
            _isTransferringTax = true;
            _swapAndClaimTaxes();
            _isTransferringTax = false;
        }

        uint amountToTransfer = amount;

        if (!_isTransferringTax) {
            if (automatedMarketMakerPairs[from]) {
                require(!_blacklistedAddresses[to], "BETS: This address is blacklisted from buying. You can always sell any tokens you own");
                
                if (_whitelistEnabled) {
                    require(_whitelistedAddresses[to], "BETS: The whitelist is enabled and this address is not included on the whitelist");

                    (uint112 reserve1, uint112 reserve2, uint32 timestamp) = _uniswapV2WethPair.getReserves();
                    uint ethPaid = _uniswapV2Router.getAmountIn(amount, reserve2, reserve1);

                    uint amountAlreadyBought = _whitelistBuyAmounts[to];
                    uint totalAmountBought = amountAlreadyBought + ethPaid;

                    require(totalAmountBought <= _whitelistMaxBuy, "BETS: The maximum you can buy while whitelist is enabled is 0.2 eth");

                    _whitelistBuyAmounts[to] = totalAmountBought;
                }

                if (!_excludedFromBlacklisting[to]) {
                    if (_lastTransactionBlockNumber[to] == block.number) {
                        _blacklistedAddresses[to] = true;
                    }
                }

                _lastTransactionBlockNumber[to] = block.number;
            }

            if (automatedMarketMakerPairs[to]) {
                if (!_excludedFromBlacklisting[from]) {
                    if (_lastTransactionBlockNumber[from] == block.number) {
                        _blacklistedAddresses[from] = true;
                    }
                }

                _lastTransactionBlockNumber[from] = block.number;
            }

            if (automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]) {
                if (isTaxEnabled() && !_excludedFromTax[from] && !_excludedFromTax[to]) {
                    uint marketingTaxFee = _getMarketingTaxFee(amountToTransfer);
                    uint devTaxFee = _getDevTaxFee(amountToTransfer);
                    amountToTransfer = amount - marketingTaxFee - devTaxFee;

                    if ((marketingTaxFee + devTaxFee) > 0) {
                        super._transfer(from, address(this), marketingTaxFee + devTaxFee);
                    }
                }
            }
        }

        super._transfer(from, to, amountToTransfer);
    }

    function _swapAndClaimTaxes() private {
        uint tokensToSwap = balanceOf(address(this));
        uint maxTokensToSwap = uint(_balanceToSwapAt) * 5;
        if (tokensToSwap > maxTokensToSwap) {
            tokensToSwap = maxTokensToSwap;
        }

        _swapTokensForEth(tokensToSwap);
        _sendEthToTaxRecipients();
    }

    function _swapTokensForEth(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), amount);
        _uniswapV2Router.swapExactTokensForETH(amount, 0, path, address(this), block.timestamp);
    }

    receive() external payable {}
    fallback() external payable {}
}