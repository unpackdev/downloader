// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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

// File: WoooooCoinETH.sol

/*
@@@@
 @@@@  @@@@@                               @@@@@@    @@@@@@@%     @@@@@     @@@
 &@@@% @@@@@  @@@ @@@@@@@@    @@@@@@@@   @@@@  @@@ @@@@    @@@  @@@@  @@@   @@@@
  @@@@@@@@@@ @@ &@@@/   @@@ @@@@   @@E@.@@@    @@@@@S@@   @@@@ @@@@  @@@@  @@@L
  @@@@  @@@@@   @@W.   @@@@ @@@   @@@@ @@@@  @@@@@ @@@   @@@@ @@@@  @@@   @@
         @@     @@@@@@@@@   @@@@@@@@(    @@@@@@     @@@@@      @@@@@@    @@
                                                                        @@@
Official Ric Flair Wooooo! Coin
https://wooooo.io
https://woooooenergy.com/
*/

pragma solidity 0.8.17;

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IPair {
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
//ERC20 is the same as BEP20
contract WoooooCoin is ERC20, Ownable, ReentrancyGuard  {
    bool private process;
    bool public LP_STATE;
    bool public autoLiquidity;
    bool public autoTreasury;
    bool public autoLiquifyLevel;

    uint256 public immutable supply;
    bool public blocker;
    bool public autoLiquify;
    uint256 public liquifyLevel;
    uint256 public slippage;
    uint256 public liquidationRatio;
    uint256 public liquidationValue;
    uint256 public impactLevel;

    struct Max {
        uint256 addr;
        uint256 sell;
        uint256 buy;
    }
    Max public max;

    mapping (address => bool) public exempt;
    mapping (address => bool) public deny;
    mapping (address => bool) public isInvestor;
    mapping (address => uint256) public vested;
    mapping (address => address) public payouts;
    mapping (address => bool) public hasPayout;
    mapping (address => bool) public soldout;
    mapping (address => uint256) public sold;
    address[] public vestedKey;
    uint32 public out;

    IUniswapV2Router02 public router;
    address public pair;
    address public currency;
    address public ROUTER;
    address public PAIR;
    address public CURRENCY;

    struct Fee {
        uint256 treasury;
        uint256 lp;
    }

    Fee public sendFee;
    Fee public buyFee;
    Fee public sellFee;
    Fee public vestedFee;

    struct OPS {
        uint256 L1;
        uint256 marketing;
        uint256 RicFlair;
        uint256 network;
    }
    OPS public ops;

    struct POOL {
        uint256 lp;
        uint256 L1;
        uint256 marketing;
        uint256 RicFlair;
        uint256 network;
    }
    POOL public pool;

    struct TXN {
        address marketing;
        address RicFlair;
        address network;
    }
    TXN public txn;

    event WoooooEvent(string str);

    modifier Process() {
        if (!process) {
            process = true;
            _;
            process = false;
        }
    }
    modifier validAddress(address _address) {
        require(_address != address(0), "Invalid address");
        _;
    }
    modifier limitFees(Fee memory fees) {
        require(fees.treasury + fees.lp <= 250, "Cannot exceed 25%");
        _;
    }

    constructor() ERC20("Wooooo! Coin", "WOOOOO!") payable {
        supply = 10_000_000_000 * 1e18;
        liquifyLevel = 200_000 * 1e18;
        impactLevel = 0.05 ether; // Default of 5%
        slippage=1;

        max.addr = 250_000_000 * 1e18;
        max.buy  = 100_000_000 * 1e18;
        max.sell = 50_000_000 * 1e18;

        sendFee = Fee(20,0);  // Treasury = 2%  | LP = 0%
        buyFee  = Fee(50,10); // Treasury = 6% | LP = 1%
        sellFee = Fee(50,10); // Treasury = 6% | LP = 1%
        vestedFee = Fee(35,15); // Treasury = 3.5% | LP = 1.5%

        txn.marketing = 0xD8B4df10F9ae893E51514db9e58084B3465A23A6; // Marketing Fees
        txn.RicFlair = 0xE1145542a7749C13303f1E42BcD676D43709c449; //Royalty Fees
        txn.network = 0x6132620eFe52A851508Cf0a779D343F5914ba843; //Network
        CURRENCY = 0xdAC17F958D2ee523a2206206994597C13D831ec7;  // USDT Contract
        ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap Router

        router = IUniswapV2Router02(ROUTER);
        PAIR   = router.WETH();
        pair   = IFactory(router.factory()).createPair(address(this), PAIR);
        currency = IFactory(router.factory()).getPair(CURRENCY, PAIR);
        liquidationRatio = 150;
        autoLiquifyLevel = true;
        autoLiquidity = true;
        autoTreasury = true;
        ops = OPS( 428, 285, 72, 143 );
        blocker=true;

        exempt[address(this)] = true;
        exempt[PAIR] = true;
        exempt[ROUTER] = true;
        exempt[msg.sender] = true;

        _mint(msg.sender,supply);
        emit WoooooEvent("Wooooo!");
    }

    receive() external payable {}

    function setRouter(address addr)external onlyOwner{
        ROUTER = addr;
        router = IUniswapV2Router02(ROUTER);
        PAIR   = router.WETH();
    }
    function setTokenPair()external onlyOwner{
        pair   = IFactory(router.factory()).createPair(address(this), PAIR);
    }
    function setLiquifyTreshhold(uint256 tokens, bool state, uint32 ratio, uint256 value, uint256 level) external onlyOwner {
        liquifyLevel = tokens*1e18;
        autoLiquifyLevel = state;
        liquidationRatio  = ratio;
        liquidationValue = value;
        impactLevel = level;
        emit WoooooEvent("Updated.Liquify.Level");
    }
    function setSlippage(uint256 amount) external onlyOwner{
        slippage=amount;
    }
    function setAutoLiquidity(bool state) external onlyOwner {
        autoLiquidity = state;
    }
    function setAutoTreasury(bool state) external onlyOwner {
        autoTreasury = state;
    }
    function setTaxes(Fee memory fees) external onlyOwner limitFees(fees){
        sendFee = fees;
        emit WoooooEvent("Updated.Fees.Send");
    }
    function setSellTaxes(Fee memory fees) external onlyOwner limitFees(fees){
        sellFee = fees;
        emit WoooooEvent("Updated.Fees.Sell");
    }
    function setBuyTaxes(Fee memory fees) external onlyOwner limitFees(fees){
        buyFee = fees;
        emit WoooooEvent("Updated.Fees.Buy");
    }
    function setMarketing(address addr) external onlyOwner validAddress(addr) {
        txn.marketing = addr;
    }
    function setRicFlair(address addr) external onlyOwner validAddress(addr){
        txn.RicFlair = addr;
    }
    function setNetwork(address addr) external onlyOwner validAddress(addr){
        txn.network = addr;
    }
    function addInvestor(address addr, uint256 tokens)external onlyOwner validAddress(addr){
        require(!LP_STATE, "L1.Investors.Already.Enabled");
        vested[addr]=tokens;
        vestedKey.push(addr);
        isInvestor[addr]=true;
    }
    function addPayouts(address investor,address addr)external onlyOwner validAddress(addr){
        require(!LP_STATE, "L1.Investors.Already.Enabled");
        payouts[investor]=addr;
        hasPayout[investor]=true;
    }
    function setCurrency(address addr) external onlyOwner validAddress(addr){
        CURRENCY = addr;
    }
    function setCurrencyPair() external onlyOwner{
        currency = IFactory(router.factory()).getPair(CURRENCY, PAIR);
    }
    function setAutoLiquify(bool state) external onlyOwner{
        autoLiquify = state;
    }
    function setBlocker(bool state) external onlyOwner{
        blocker = state;
    }
    function launch() external onlyOwner{
        require(!LP_STATE, "Trading.Already.Launched");
        LP_STATE = true;
        emit WoooooEvent("Wooooo!");
    }
    function renounceOwnership() public view override onlyOwner {
        revert("Ownership cannot be renounced in this contract");
    }
    function recover() public onlyOwner {
        uint256 amount = address(this).balance;
        payout(payable(msg.sender), amount);
    }
    function Wooooo() public view returns (string memory) {
        string[5] memory options = [
        "Wooooo!",
        "In order to be the man, you have to beat the man.",
        "I'm Ric Flair! The Stylin', profilin', limousine riding, jet flying, kiss-stealing, wheelin' n' dealin' son of a gun!",
        "If you don't like it, learn to *love* it!",
        "Harley Race is a great wrestler, a great champion, and a master technician. I learned something new every time I wrestled him. One of the all-time greats"
        ];
        bytes32 randomHash = keccak256(abi.encodePacked(block.timestamp, uint256(1)));
        uint256 randomIndex = uint256(randomHash) % options.length;
        return options[randomIndex];
    }
    function getReserves(address addr)public view returns(uint256, uint256){
        (uint256 token0, uint256 token1,) = IPair(addr).getReserves();
        if(token0>token1){
            return(token1,token0);
        }else{
            return(token0,token1);
        }
    }
    function priceETH() public view returns (uint256) {
        (uint256 token0, uint256 token1) = getReserves(currency);
        return ((token0 * 1e18) / token1)*1e12;
        //return ((token1 * 1e18) / token0);
    }
    function priceInETH() public view returns (uint256) {
        (uint256 token0, uint256 token1) = getReserves(pair);
        return (token0 * 1e18) / token1;
    }
    function priceUSD() public view returns (uint256) {
        return (priceInETH() * priceETH()) / 1e18;
    }
    function totalLiquidity()public view returns(uint256){
        (uint256 token0, ) = getReserves(pair);
        return (token0 * priceETH()) / 1e18;
    }
    function accumulatedValue()public view returns(uint256){
        uint256 tokens = balanceOf(address(this));
        return (tokens * priceUSD()) / 1e18;
    }
    function priceImpact(uint256 TOKENS) public view returns (uint256) {
        uint256 value = (TOKENS * priceUSD()) / 1e18;
        uint256 available = totalLiquidity();
        uint256 impact = (value*1e18) / available;
        return impact;
    }
    function dynamicLiquidityLevel() public view returns (uint256) {
        uint256 pooled = accumulatedValue();
        uint256 value = (pooled*liquidationRatio)/1000;
        uint256 liquidateTokens = (value*1e18)/priceUSD();
        return liquidateTokens;
    }
    function tokenQuote(uint256 amount) public view returns (uint256) {
        uint256 tokens = (amount*1e18)/priceUSD();
        return tokens;
    }
    function checkLiquidity()public view returns(uint256[2] memory){
        (uint256 token0, uint256 token1 ) = getReserves(pair);
        uint256[2] memory res;
        res[0] = token0;
        res[1] = token1;
        return res;
    }
    function _transfer(address sender,address recipient,uint256 amount) internal override  validAddress(sender) validAddress(recipient){
        require(amount != 0, "Must.Not.Be.Zero");
        require(!deny[recipient], "Snipe.Attacker.Not.Permitted");
        if(LP_STATE){
            if(sender == pair && !exempt[recipient] && !process){
                require(amount <= max.buy, "Amount.Buy.Exceeded");
                require(balanceOf(recipient) + amount <= max.addr, "Balance.Exceeded");
            }
            if(sender != pair && !exempt[recipient] && !exempt[sender] && !process){
                require(amount <= max.sell, "Amount.Sell.Exceeded");
                if(recipient != pair){
                    require(balanceOf(recipient) + amount <= max.addr, "Balance.Exceeded");
                }
            }
        }else{
            if(!exempt[recipient] && !exempt[sender]){
                deny[recipient]=true;
            }
        }
        uint256 fee; 
        if (process || exempt[sender] || exempt[recipient]) fee = 0;
        else if(recipient == pair){
            fee = sellFee.treasury + sellFee.lp;
            if(vested[sender]!=0){
                vestedSell(sender,amount);
                fee = vestedFee.treasury + vestedFee.lp;
            }
        }else if(sender == pair){
            if (!blocker && isInvestor[recipient]) {
                revert("L1.Investor.Cannot.Buy");
            }
            fee = buyFee.treasury + buyFee.lp ;
            emit WoooooEvent("Wooooo!");
        }else{
            if(!blocker && isInvestor[recipient]){
                revert("L1.Investor.Cannot.Receieve");
            }
            if(vested[sender]!=0){ vestedSell(sender,amount);}
            fee = sendFee.lp;
        }
        uint256 fees = (amount * fee) / 1000;
        if(autoLiquify){
            if(LP_STATE && sender != pair && fee !=0 && !exempt[sender] && !exempt[recipient]) liquidate(recipient);
        }
        super._transfer(sender, recipient, amount - fees);
        if(fee!=0){
            super._transfer(sender, address(this), fees);
        }
    }
    function payout(address recipient, uint256 amount) internal nonReentrant{
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Transfer failed");
    }
    function vestedSell(address seller,uint256 amount)private{
        sold[seller]+=amount; //Track vested tokens being sold
        if(sold[seller]==vested[seller]){
            soldout[seller]=true;
            out+=1;
            if(out>=vestedKey.length){
                ops = OPS( 0, 500, 125, 250 );
            }
        }
    }
    function estimateEthOut(uint256 TOKENS) private view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        uint[] memory amounts = router.getAmountsOut(TOKENS, path);
        return amounts[1];
    }
    function liquidityAdd(uint256 _tokens, uint256 _pair) private {
        if(autoLiquidity){
            if(_pair > 0){
                _approve(address(this), address(router), _tokens);
                router.addLiquidityETH{ value: _pair }(address(this), _tokens, 0, 0, owner(), block.timestamp);
            }
        }
    }
    function liquify(uint256 TOKENS) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), TOKENS);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            TOKENS,
            0,
            path,
            address(this),
            block.timestamp 
        );
    }
    function liquidationImpact() public view returns(uint256){
        uint256 tokens = balanceOf(address(this));
        uint256 tokenLevel = liquifyLevel;
        if(autoLiquifyLevel){
            tokenLevel = dynamicLiquidityLevel();
            if(liquidationValue!=0){
                tokenLevel = tokenQuote(liquidationValue);
            }
            if (tokens >= tokenLevel) {
                if(tokenLevel > 1){
                    tokens = tokenLevel;
                }
                return priceImpact(tokens);
            }
        }
        return 0;
    }
    function liquidate(address seller) private Process {
        uint256 tokens = balanceOf(address(this));
        uint256 tokenLevel = liquifyLevel;
        if(autoLiquifyLevel){
            tokenLevel = dynamicLiquidityLevel();
            if(liquidationValue!=0){
                tokenLevel = tokenQuote(liquidationValue);
            }
        }
        if (tokens >= tokenLevel) {
            if(tokenLevel > 1){
                tokens = tokenLevel;
            }
            uint256 impact = priceImpact(tokens);

            if(impact<impactLevel){
                uint256 initial = address(this).balance;
                uint256 LP_TOKENS = (tokens * 62) / 1000;
                liquify(tokens-LP_TOKENS);

                uint256 current = address(this).balance - initial;
                uint256 PAIR_TOKENS = estimateEthOut(LP_TOKENS);
                if(current>PAIR_TOKENS){
                    liquidityAdd( LP_TOKENS, PAIR_TOKENS );

                    uint256 amount = address(this).balance - current;
                    treasuryTransfer((amount*900)/1000,seller);
                    emit WoooooEvent("Token.Liquidation.Complete");
                }
            }
        }
    }
    function triggerLiquidation() external onlyOwner{
        liquidate(msg.sender);
    }
    function treasuryTransfer(uint256 amount, address seller) private {
        if (autoTreasury) {
            uint32 len = uint32(vestedKey.length);
            if (len != 0 && ops.L1 != 0) {
                uint256 L1 = (amount * ops.L1) / 1000;
                uint256 totalShares;
                address[] memory exclude = new address[](len);
                uint256 excludeCount = 0;
                for (uint32 i = 0; i < len;) {
                    uint256 vestedMin = vested[vestedKey[i]] / 4;
                    uint256 bal = balanceOf(vestedKey[i]);
                    if (vestedKey[i] != seller && bal >= vestedMin) {
                        totalShares += bal;
                    } else {
                        exclude[excludeCount] = vestedKey[i];
                        excludeCount++;
                    }
                unchecked{
                    i++;
                }
                }
                for (uint32 i = 0; i < len;) {
                    address investor = vestedKey[i];
                    if (!contains(exclude, investor, excludeCount)) {
                        uint256 div = (balanceOf(investor) * 1000) / totalShares;
                        uint256 payment = (div * L1) / 1000;
                        if (hasPayout[investor]) {
                            payout(payouts[investor], payment);
                        } else {
                            payout(investor, payment);
                        }
                    }
                unchecked{
                    i++;
                }
                }
            }
            payout(txn.marketing, (amount * ops.marketing) / 1000);
            payout(txn.RicFlair, (amount * ops.RicFlair) / 1000);
            payout(txn.network, (amount * ops.network) / 1000);
        } else {
            payout(owner(), amount);
        }
        emit WoooooEvent("Payouts.Complete");
    }
    function contains(address[] memory array, address target, uint256 length) internal pure returns (bool) {
        for (uint256 i = 0; i < length; i++) {
            if (array[i] == target) {
                return true;
            }
        }
        return false;
    }

}