// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/**
*  
* $MOMO - MoeTheMartian's Token
* 
*  
* Join the Martian expedition and be part of the next big thing in the crypto universe.
* $MOMO isn't just a token; it's a ticket to the stars. With unique anti-bot measures,
* incentivized holding strategies, and a community that's out of this world, our destination is Mars.
* Don't miss the rocket! #ToMarsWithMOMO 🚀🪐
* 
* A community-driven token with unique features:
*
* -- Anti-bot measures to ensure fair trading
* -- Sliding tax mechanism rewarding early and frequent buyers
* -- Liquidity redirection to constantly strengthen the pool
* -- Vesting schedule for holders, rewards based on amount of $MOMO held
* -- Reentrancy defense against attacks
*
* Hold, trade, and be part of an epic interplanetary adventure!
* X: https://twitter.com/MoeTheMartian
* Website: TBD -- I will deploy this contract first, and after this begin developing a launchpage good enough for SpaceX to use
**/

contract ReentrancyGuard {
    bool private _notEntered = true;
    
    modifier nonReentrant() {
        require(_notEntered, "Reentrant call");
        _notEntered = false;
        _;
        _notEntered = true;
    }
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TaxRedistributed(address indexed sender, uint256 halfTax, uint256 ethReceived);
    event RewardClaimed(address indexed claimer, uint256 reward);

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
}

contract MOMOToken is IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name = "MoeTheMartian";
    string private _symbol = "MOMO";

    constructor() {
    _totalSupply = 420 * 10**12 * 10**18; // 420 trillion tokens with 18 decimals
    _balances[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);
    _transferOwnership(msg.sender);
}

function _rewardCaller(address caller, uint256 reward) internal {
    _balances[caller] += reward;
}

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public virtual override returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
}

contract MoeTheMartianContract is MOMOToken, ReentrancyGuard {
    mapping(address => uint256) public lastBuyTimestamp;
    uint256 public taxRate = 20;
    uint256 public accumulatedTax = 0;
    uint256 public redistributionThreshold = 420000 * 10 ** decimals();
    uint256 public lastRedistribution;
    uint256 public rewardPool;
    mapping(address => uint256) public lastClaimTime;
    uint256 public constant CLAIM_INTERVAL = 420 hours;
    uint256 public constant CLIFF_DURATION = 30 days;

    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;

    constructor() {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function setPairAddress() external onlyOwner {
        uniswapV2Pair = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f).getPair(address(this), uniswapV2Router.WETH());
        require(uniswapV2Pair != address(0), "Pair address not found");
    }

    function getPathForTokenToETH() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        return path;
    }

    // Implementing the nonReentrant modifier to the necessary functions
    function redistributeTax() external nonReentrant {
        require(accumulatedTax >= redistributionThreshold, "Insufficient accumulated tax for redistribution");
        uint256 halfTax = accumulatedTax / 2;
        uint256 ethReceived = _swapTokensForETH(halfTax);
        _addLiquidity(halfTax, ethReceived);
        accumulatedTax = 0;
        emit TaxRedistributed(msg.sender, halfTax, ethReceived);
    }

    function _swapTokensForETH(uint256 tokenAmount) internal nonReentrant returns (uint256) {
        uint256 initialBalance = address(this).balance;
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            getPathForTokenToETH(),
            address(this),
            block.timestamp
        );
        return address(this).balance - initialBalance;
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal nonReentrant {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

      receive() external payable {}

    function setTaxRate(uint256 newTaxRate) external onlyOwner {
        require(newTaxRate >= 0 && newTaxRate <= 100, "Invalid tax rate");
        taxRate = newTaxRate;
    }

    function setRedistributionThreshold(uint256 newThreshold) external onlyOwner {
        redistributionThreshold = newThreshold;
    }

    function withdrawStrayTokens(IERC20 token) external onlyOwner {
        require(address(token) != uniswapV2Pair, "Cannot withdraw from the liquidity pool");
        uint256 amount = token.balanceOf(address(this));
        token.transfer(msg.sender, amount);
    }

    function withdrawStrayETH() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
    if (uniswapV2Pair == address(0)) {
        require(from == owner() || to == owner(), "Trading is not started");
        return;
    }
    if (from == uniswapV2Pair && to != address(uniswapV2Router)) { 
        require(block.timestamp - lastBuyTimestamp[msg.sender] > 60, "1-minute cooldown between buys");
        if (taxRate > 1) {
            uint256 taxAmount = (taxRate * amount) / 100;
            accumulatedTax += taxAmount;
            amount -= taxAmount;
            taxRate--;
        }

        if (accumulatedTax >= redistributionThreshold) {
    uint256 halfTax = accumulatedTax / 2;
    uint256 rewardForCaller = (halfTax * 42) / 1000;  // 4.2% of the halfTax
    uint256 ethReceived = _swapTokensForETH(halfTax - rewardForCaller);
    _addLiquidity(halfTax - rewardForCaller, ethReceived);
    _rewardCaller(msg.sender, rewardForCaller);  // Reward the caller using the helper function
    accumulatedTax -= halfTax;
    emit TaxRedistributed(msg.sender, halfTax, ethReceived);
        
}

        lastBuyTimestamp[msg.sender] = block.timestamp;
    } else if (to == uniswapV2Pair) { 
        require(block.timestamp - lastBuyTimestamp[msg.sender] > 60, "1-minute cooldown after buying");
        uint256 burnAmount = (taxRate * amount) / 100;
        _burn(msg.sender, burnAmount);
    }
}

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    function claimRewards() external {
        require(block.timestamp >= lastClaimTime[msg.sender] + CLAIM_INTERVAL + CLIFF_DURATION, "You can only claim every 420 hours after the cliff duration");
        uint256 reward = (balanceOf(msg.sender) * rewardPool) / totalSupply();
        _transfer(address(this), msg.sender, reward);
        lastClaimTime[msg.sender] = block.timestamp;
        emit RewardClaimed(msg.sender, reward);
    }
}