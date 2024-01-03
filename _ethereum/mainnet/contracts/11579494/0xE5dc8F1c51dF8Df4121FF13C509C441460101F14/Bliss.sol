// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ILPERC20Staking.sol";
interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
    ) external; 
}

interface IUniswapV2Pair {
    function sync() external;
}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract Balancer {
    using SafeMath for uint256;    
    IERC20 token;
    address owner;
    
    constructor(address _token) public {
        token = IERC20(_token);
        owner = msg.sender;
    }
    receive () external payable {}
    function enlighten(uint callerRewardDivisor, ILPERC20Staking staking) external returns (uint256) { 
        require(msg.sender == owner, "only token");
        uint256 lockableBalance = token.balanceOf(address(this));
        uint256 callerReward = lockableBalance.div(callerRewardDivisor);
        token.transfer(tx.origin, callerReward);
        token.transfer(address(staking), lockableBalance.sub(callerReward));        

        if(staking.epochCalculationStartBlock() + 50000 < block.number)
            staking.startNewEpoch();
        staking.addPendingRewards();

        return lockableBalance.sub(callerReward);
    }
}


contract Bliss is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    event Enlightenment(uint256 tokens);

    IUniswapV2Factory factory;

    address public uniswapV2Router;
    address public uniswapV2Pair;
    address public wbtc;
    
    address payable public treasury;
    address public bounce = 0x73282A63F0e3D7e9604575420F777361ecA3C86A;
    mapping(address => bool) feelessAddr;
    mapping(address => bool) unlocked;
    
    // the amount of tokens to lock for liquidity during every transfer, i.e. 100 = 1%, 50 = 2%, 40 = 2.5%
    uint256 public liquidityLockDivisor;
    uint256 public callerRewardDivisor;
    uint256 public rebalanceDivisor;
    
    uint256 public minRebalanceAmount;
    uint256 public lastRebalance;
    uint256 public rebalanceInterval;
    
    uint256 public lpUnlocked;
    bool public locked;
    
    Balancer balancer;
    ILPERC20Staking staking;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor () public {
        _mint(msg.sender, 432000*1e18);
        factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        uniswapV2Pair = factory.createPair(address(this), IUniswapV2Router02(uniswapV2Router).WETH());
        _name = "Bliss";
        _symbol = "BLS";
        _decimals = 18;
        lastRebalance = block.timestamp;
        liquidityLockDivisor = 20;
        callerRewardDivisor = 25;
        rebalanceDivisor = 50;
        rebalanceInterval = 5 minutes;
        lpUnlocked = block.timestamp + 90 days;
        minRebalanceAmount = 100 ether;
        feelessAddr[address(this)] = true;
        feelessAddr[address(balancer)] = true;
        feelessAddr[msg.sender] = true;
        feelessAddr[bounce] = true;
        locked = true;
        unlocked[msg.sender] = true;
        unlocked[bounce] = true;
        unlocked[address(balancer)] = true;
        wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;             
        balancer = new Balancer(wbtc);
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
    function transfer(address recipient, uint256 amount) public  override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address _owner, address spender) public view  override returns (uint256) {
        return _allowances[_owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public  override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public  override returns (bool) {
        _transfer(sender, recipient, amount);
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
    function increaseAllowance(address spender, uint256 addedValue) public  returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public  returns (bool) {
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

    function setStaking(address _staking) public onlyOwner {
        require(address(staking) == address(0), "Only once");
        staking = ILPERC20Staking(_staking);
    }

    function setLiquidityLockDivisor(uint256 _liquidityLockDivisor) public onlyOwner {
        if (_liquidityLockDivisor != 0) {
            require(_liquidityLockDivisor >= 10, "BLISS::setLiquidityLockDivisor: too small");
        }
        liquidityLockDivisor = _liquidityLockDivisor;
    }

    function setRebalanceDivisor(uint256 _rebalanceDivisor) public onlyOwner {
        if (_rebalanceDivisor != 0) {
            require(_rebalanceDivisor >= 10, "BLISS::setRebalanceDivisor: too small");
        }        
        rebalanceDivisor = _rebalanceDivisor;
    }

    function setRebalanceInterval(uint256 _interval) public onlyOwner {
        rebalanceInterval = _interval;
    }
    
    function setCallerRewardDivisior(uint256 _rewardDivisor) public onlyOwner {
        if (_rewardDivisor != 0) {
            require(_rewardDivisor >= 10, "BLISS::setCallerRewardDivisor: too small");
        }        
        callerRewardDivisor = _rewardDivisor;
    }
    
    function toggleFeeless(address _addr) public onlyOwner {
        feelessAddr[_addr] = !feelessAddr[_addr];
    }
    function toggleUnlockable(address _addr) public onlyOwner {
        unlocked[_addr] = !unlocked[_addr];
    }    
    function unlock() public onlyOwner {
        locked = false;
    }    

    function setMinRebalanceAmount(uint256 amount_) public onlyOwner {
        minRebalanceAmount = amount_;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        if(locked && unlocked[from] != true && unlocked[to] != true)
            revert("Locked until end of presale");
            
        if (liquidityLockDivisor != 0 && feelessAddr[from] == false && feelessAddr[to] == false) {
            uint256 liquidityLockAmount = amount.div(liquidityLockDivisor);
            _finaltransfer(from, address(this), liquidityLockAmount);
            _finaltransfer(from, to, amount.sub(liquidityLockAmount));
        }
        else {
            _finaltransfer(from, to, amount);
        }
    }
    function _finaltransfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal  {
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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal  {
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
    function _approve(address _owner, address spender, uint256 amount) internal  {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal  { }
    function bringEnlightenment() public {
        require(balanceOf(msg.sender) >= minRebalanceAmount, "You aren't enlightened enough.");
        require(block.timestamp > lastRebalance + rebalanceInterval, 'Too Soon.');
        lastRebalance = block.timestamp;
        // swappable supply is the token balance of this contract
        uint256 _swappableSupply = balanceOf(address(this));
        //swap for WBTC
        address[] memory uniswapPairPath = new address[](3);
        uniswapPairPath[0] = address(this);        
        uniswapPairPath[1] = IUniswapV2Router02(uniswapV2Router).WETH();
        uniswapPairPath[2] = address(wbtc);
        approve(uniswapV2Router, _swappableSupply);
        feelessAddr[uniswapV2Router] = true;
        feelessAddr[uniswapV2Pair] = true;
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokens(
            _swappableSupply,
            1,
            uniswapPairPath,
            address(balancer),
            block.timestamp + 1 hours
        );
       
       uint _locked = balancer.enlighten(callerRewardDivisor, staking);
        feelessAddr[uniswapV2Router] = false;
        feelessAddr[uniswapV2Pair] = false;
        emit Enlightenment(_locked);
    }    

}
