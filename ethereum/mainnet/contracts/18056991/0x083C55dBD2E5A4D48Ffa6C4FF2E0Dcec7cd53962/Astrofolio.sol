// SPDX-License-Identifier: MIT

/**
 * Imagine a world where you receive a valuable token such as ETH just by holding an ERC20 token
 * 
 * Astrofolio does exactly that! 🚀👨🏽‍🚀
 * 
 * $ASTRF is an ERC20 token that will reward you with ETH just by holding it in your wallet. 
 * Based on the percentage of the total supply that you hold, you will receive a proportional amount of ETH.
 * 
 * But, how does Astrofolio do that? 🤔
 * 
 * Astrofolio taxes every buy and sell transaction with a 4% fee. With this fee, Astrofolio will be able to invest in a variety of markets, such as real estate, art, collectibles and luxury items!
 * 
 * Astrofolio partners with third-party experts on each field to ensure the best possible investment decisions.
 * 
 * What are you waiting for? 
 * 
 * Invest in your future with Astrofolio! 🏛️💎
 * 
 * Website:     https://astrofolio.finance/
 * Telegram:    https://t.me/astrofolio_finance
 * X:           https://x.com/astrf_finance
 */

pragma solidity ^0.8.21;

import "./Context.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

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

contract Astrofolio is ERC20, Ownable {
    string private _name = "Astrofolio";
    string private _symbol = "ASTRF";

    uint256 private _supply = 100_000_000_000 ether;

    uint256 public maxTxAmount = _supply * 2 / 100; // 2% of the total supply
    uint256 public maxWalletAmount = _supply * 2 / 100; // 2% of the total supply

    address public investmentAddress = 0xE21559FEc5cc30aCc20F9c67847269b52CFa2a9C;

    mapping(address => bool) public excludedFromFees;
    mapping(address => bool) public excludedFromWalletLimit;

    bool swapping = false;

    // Will be 4/4 when the anti-sniping mode is removed
    uint256 public buyTax = 20;
    uint256 public sellTax = 40;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair = address(0);

    uint256 public investmentFunds;

    constructor() ERC20(_name, _symbol) {
        _mint(msg.sender, (_supply));

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
    
        // All wallets will be excluded from the wallet limit when removeWalletLimit() is called. This is to avoid any problems with the liquidity pool in the initial stage
        excludedFromWalletLimit[_msgSender()] = true;
        excludedFromWalletLimit[investmentAddress] = true;
        excludedFromWalletLimit[address(this)] = true;
        excludedFromWalletLimit[address(uniswapV2Router)] = true;

        excludedFromFees[_msgSender()] = true;
        excludedFromFees[investmentAddress] = true;
        excludedFromFees[address(this)] = true;
        excludedFromFees[address(uniswapV2Router)] = true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (!excludedFromWalletLimit[from] && !excludedFromWalletLimit[to] ) { // Check whether the amount that the user wants to transfer is within the limit
            if (to != uniswapV2Pair) { // Only normal transfers (not buy nor sell) will go to this if statement
                require(amount <= maxTxAmount, "ERC20: transfer amount exceeds the max transaction amount bef");
                require(
                    (amount + balanceOf(to)) <= maxWalletAmount,
                    "ERC20: balance amount exceeded max wallet amount limit"
                );
            }
        }

        uint256 transferAmount = amount;

        if (!excludedFromFees[from] && !excludedFromFees[to]) { // Only calculate if the wallet has a fee to pay. Either from or to
            if ((from == uniswapV2Pair || to == uniswapV2Pair)) { // Only buys and sells have fees. Normal transfers between wallets do not
                require(amount <= maxTxAmount, "ERC20: transfer amount exceeds the max transaction amount");
 
                if (
                    buyTax > 0 && 
                    uniswapV2Pair == from &&
                    !excludedFromWalletLimit[to] // Receiver is not excluded from the wallet limit
                ) {
                    uint256 feeTokens = (amount * buyTax) / 100;
                    super._transfer(from, address(this), feeTokens);
                    transferAmount = amount - feeTokens;
                }

                if (
                    sellTax > 0 &&
                    uniswapV2Pair == to &&
                    !excludedFromWalletLimit[from] &&
                    !swapping
                ) {
                    swapping = true;
                    swapAndConvertToETH();
                    swapping = false;

                    uint256 feeTokens = (amount * sellTax) / 100;
                    super._transfer(from, address(this), feeTokens);
                    transferAmount = amount - feeTokens;
                }
            }
        }

        super._transfer(from, to, transferAmount);
    }

    function swapAndConvertToETH() internal { // Swaps the $ASTRF got from the sell tax to ETH and stores it inside the smart contract
        if (balanceOf(address(this)) == 0) {
            return;
        }

        uint256 receivedETH;

        {
            uint256 contractASTRFBalance = balanceOf(address(this));
            uint256 beforeBalance = address(this).balance;

            if (contractASTRFBalance > 0) {
                beforeBalance = address(this).balance;
                _swapASTRFForEth(contractASTRFBalance, 0);
                receivedETH = address(this).balance - beforeBalance;
                investmentFunds += receivedETH; // Investment funds are used to separate the ETH from the fees and the one that is directly transfered to the contract
            }
        }
    }

    function _swapASTRFForEth(
        uint256 tokenAmount,
        uint256 tokenAmountOut
    ) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        IERC20(address(this)).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens( // Will be stored inside the smart contract
            tokenAmount,
            tokenAmountOut,
            path,
            address(this),
            block.timestamp
        );
    }

    function removeAntiSnipingMode() external onlyOwner returns (bool) { // This function allows us to remove the anti-sniping mode and set the tax to 4/4
        buyTax = 4;
        sellTax = 4;

        return true;
    }

    function removeWalletLimit() external onlyOwner returns (bool) { // This function allows us to remove the wallet limit
        maxTxAmount = _supply;
        maxWalletAmount = _supply;

        return true;
    }

    function removeRestrictionsWallet(address addy, bool changer) external onlyOwner { // This function allows us to add or remove wallets from the tx limit and the fees list
        // Once the contract is renounced, this function cannot be called anymore
        excludedFromWalletLimit[addy] = changer;
        excludedFromFees[addy] = changer;
    }

    function getInvestmentsTax() external returns (bool) { // Get the tax for investments. This is used to diversify the funds and pay back users with dividends in form of ETH
        payable(investmentAddress).transfer(investmentFunds);
        investmentFunds = 0; // Reset the investment funds
        return true;
    }

    function withdrawERC20Tokens(address token) external { // Withdraw any stuck ERC20 tokens
        IERC20(token).transfer(
            investmentAddress,
            IERC20(token).balanceOf(address(this))
        );
    }

    function withdrawETH() external { // If somehow the smart contract receives ETH, it will not be taken into account for the investments tax. This function allows us to withdraw it.
        (bool success, ) = payable(investmentAddress).call{value: address(this).balance}("");

        require(success, "ETH withdraw failed");
    }

    receive() external payable {}
    fallback() external payable {}
}