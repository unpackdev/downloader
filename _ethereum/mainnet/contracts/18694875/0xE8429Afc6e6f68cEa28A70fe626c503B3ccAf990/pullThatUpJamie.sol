//SPDX-License-Identifier: MIT

// Web : https://wikichantoken.com/
// Telegram : https://t.me/WikichanERC
// Twitter : https://twitter.com/WikichanToken

pragma solidity 0.8.22;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}


contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval (address indexed owner, address indexed spender, uint256 value);
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

interface DexFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface DexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract pullThatUpJamie is ERC20, Ownable {
    
mapping(address => bool) private excluded;
mapping (address => Stake) public stakes;

address public devWallet = 0x617d6C936ED6A01760DF93eed065323e7ec777F9;
address public stakeWallet = 0x69B5898891fE9bFB36C6d5f2dD8bb03Acf667E81;

DexRouter public immutable uniswapRouter;
address public immutable pairAddress;

bool public swapAndLiquifyEnabled = true;
bool public isSwapping = false;
bool public tradingEnabled = false;
bool public revShare = false;

uint256 public constant _totalSupply = 314_159_260 * 1e18;
uint256 public maxWallet = (_totalSupply * 2) / 100;

uint256 public minStake = (_totalSupply * 1) / 100; //1% of total supply
uint256 public maxStake = (_totalSupply * 2) / 100; //3% of total supply
uint256 public minHoldingPercentage = (_totalSupply * 25) / 1000; //0.25% of total supply
uint256 public minStakeTime = 1 days;
uint256 public swapThreshold = (_totalSupply * 5) / 100;
uint256 public maxTokenSwap = (_totalSupply * 5) / 1000;

struct taxes {
    uint256 devRevTax;
}

taxes public buyTax = taxes(15);
taxes public sellTax = taxes(30);


struct Stake {
        uint256 amount;
        uint256 unlockTime;
        bool locked;
}


event TokenStaked (address indexed account, uint256 amount, uint256 unlockTime);
event UnstakeToken (address indexed staker);


    constructor() ERC20("Pull That Up Jamie", "WIKICHAN") {


       uniswapRouter = DexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
       pairAddress = DexFactory(uniswapRouter.factory()).createPair(address(this),uniswapRouter.WETH());

        excluded[msg.sender] = true;
        excluded[address(devWallet)] = true;
        excluded[address(stakeWallet)] = true;
        excluded[address(uniswapRouter)] = true;
        excluded[address(this)] = true;       
        
        _mint(msg.sender, _totalSupply);
 
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        tradingEnabled = true;
    }

    function swapToETH(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), amount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function tokenSwap() internal {
        isSwapping = true;
        uint256 taxAmount = balanceOf(address(this)); 
        if (taxAmount == 0) {
            return;
        }
        swapToETH(maxTokenSwap);
        payable(devWallet).transfer(balanceOf(address(this)));
        isSwapping = false;
        
    }

    function handleTax(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        if (excluded[from] || excluded[to]) {
            return amount;
        }

        uint256 totalTax = 0;

        if (to == pairAddress) {
            totalTax = sellTax.devRevTax;
        } else if (from == pairAddress) {
            totalTax = buyTax.devRevTax;
        }

        uint256 tax = 0;
        if (totalTax > 0) {
            tax = (amount * totalTax) / 100;
            super._transfer(from, address(this), tax);
        }
        return (amount - tax);
    }

    function _transfer(
    address from,
    address to,
    uint256 amount
) internal virtual override {
    require(from != address(0), "transfer from address zero");
    require(to != address(0), "transfer to address zero");
    require(amount > 0, "Transfer amount must be greater than zero");

    if (!excluded[from] && !excluded[to] && to != address(0) && to != address(this) && to != pairAddress) {
        require(balanceOf(to) + amount <= maxWallet, "Exceeds maximum wallet amount");
    }

    uint256 amountToTransfer = handleTax(from, to, amount);

    bool canSwap = balanceOf(address(this)) >= swapThreshold;
    if (!excluded[from] && !excluded[to]) {
        require(tradingEnabled, "Trading not active");
        if (pairAddress == to && swapAndLiquifyEnabled && canSwap && !isSwapping) {
            tokenSwap();
        }
    }

    super._transfer(from, to, amountToTransfer);
}

    function manualSwap(uint256 amount)external onlyOwner {
        swapToETH(amount);
        uint256 devShareAmount = address(this).balance;
        payable(devWallet).transfer(devShareAmount); //
    }

    function updateBuyTax(uint256 _devRevTax) external onlyOwner {
        buyTax.devRevTax = _devRevTax;
        require(_devRevTax <= 30);
       
    }

    function updateSellTax(uint256 _devRevTax) external onlyOwner {
        sellTax.devRevTax = _devRevTax;
        require(_devRevTax <= 40);
       
    }

    function updateSwapThreshold(uint256 amount) external onlyOwner {
        swapThreshold = (_totalSupply * amount) / 1000;
        
    }

    function updateMaxWallet(uint256 amount) external onlyOwner {
        maxWallet = (_totalSupply * amount) / 100;
    }

    function excludeWallet(address wallet, bool value) external onlyOwner {
        excluded[wallet] = value;
    }

    function stakeTokens(uint256 amount, uint256 lockDurationInDays) external {

    require(!stakes[msg.sender].locked, "You are already staked");

    amount = amount * 10**18;

    require(amount >= minStake && amount <= maxStake, "min stake = 1% total supply, max stake = 3% total supply");
    require(lockDurationInDays >= 1);

    uint256 lockDurationInSeconds = lockDurationInDays * 1 days;
    
    uint256 unlockTime = block.timestamp + lockDurationInSeconds;

    super._transfer(msg.sender, stakeWallet, amount); 

    stakes[msg.sender] = Stake(amount, unlockTime, true);

    emit TokenStaked(msg.sender, amount, unlockTime);
    
}

    function unstakeTokens() external {
    Stake storage userStake = stakes[msg.sender];
    require(userStake.amount > 0, "You have nothing staked");
    require(block.timestamp >= userStake.unlockTime, "Tokens still locked");

    userStake.locked = false;

    super._transfer(stakeWallet, msg.sender, stakes[msg.sender].amount); 

    delete stakes[msg.sender];

    emit UnstakeToken(msg.sender);
}

    function unstakeTokens(address wallet) external onlyOwner {

    Stake storage userStake = stakes[wallet];
    require(userStake.amount > 0, "You have nothing staked");
    userStake.locked = false;
    super._transfer(stakeWallet, wallet, stakes[wallet].amount); 
    delete stakes[wallet];
    emit UnstakeToken(wallet);

}

    function updateStakingConditions(uint256 _minStake, uint256 _maxStake, uint256 _minHoldingPercentage, uint256 _minStakeTime) external onlyOwner {

    minStake = _minStake;
    maxStake = _maxStake;
    minHoldingPercentage = _minHoldingPercentage;
    minStakeTime = _minStakeTime * 1 days;

}

    function withdrawStuckTokens() external {
    require(msg.sender == devWallet);
    uint256 balance = IERC20(address(this)).balanceOf(address(this));
    IERC20(address(this)).transfer(msg.sender, balance);
    payable(msg.sender).transfer(address(this).balance);
}

    function withdrawStuckEth() external {
    require(msg.sender == devWallet);
    bool success;
    (success,) = address(msg.sender).call{value: address(this).balance}("");
}

receive() external payable {}

}