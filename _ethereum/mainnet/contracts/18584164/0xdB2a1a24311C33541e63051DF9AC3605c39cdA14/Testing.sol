// SPDX-License-Identifier: MIT
/*

Hey it's a test token

Website: https://www.fast.com

*/
pragma solidity ^0.8.0;

// ERC20 standard interface
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Uniswap V2 Router and Factory interfaces for creating pairs and adding liquidity
interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// Testing token with basic ERC20 functionalities and Uniswap integration
contract Testing is IERC20 {
    string private constant _name = "Testing";
    string private constant _symbol = "TST";
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply = 100000000 * 10**uint256(_decimals);
    uint256 public maxWalletSize = (_totalSupply * 50) / (100);
    mapping(address => bool) public isExcludedFromMaxWalletSize;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address private _owner;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    event OwnershipRenounced(address indexed previousOwner);
    event LiquidityAdded(uint256 tokenAmount, uint256 ethAmount);
    event LiquidityBurned(uint256 lpTokenAmount);

    constructor() {
        _balances[msg.sender] = _totalSupply;
        _owner = msg.sender;
        // Set Uniswap V2 Router address
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        isExcludedFromMaxWalletSize[address(this)] = true;
        isExcludedFromMaxWalletSize[_owner] = true;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0), "Transfer to the zero address");
        require(_balances[msg.sender] >= amount, "Insufficient balance");

        if (!isExcludedFromMaxWalletSize[recipient]) {
            require(_balances[recipient] + amount <= maxWalletSize, "Transfer exceeds the max wallet size");
        }

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view override returns (uint256) {
        return _allowances[tokenOwner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "Approve to the zero address");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(_balances[sender] >= amount, "Insufficient balance");
        require(_allowances[sender][msg.sender] >= amount, "Transfer amount exceeds allowance");

        if (!isExcludedFromMaxWalletSize[recipient]) {
            require(_balances[recipient] + amount <= maxWalletSize, "Transfer exceeds the max wallet size");
        }

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _allowances[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Decreased allowance below zero");
        _allowances[msg.sender][spender] = currentAllowance - subtractedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function approveUniswapRouter() external onlyOwner {
        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;
        emit Approval(address(this), address(uniswapV2Router), _totalSupply);
    }

    function createTradingPair() external onlyOwner {
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        require(uniswapV2Pair != address(0), "Failed to create the trading pair");

        isExcludedFromMaxWalletSize[uniswapV2Pair] = true;
    }

    function addLiquidity(uint256 ethAmount, uint256 tokenAmount) external onlyOwner {
        // Pre-conditions: Check for sufficient ETH and token balances
        require(address(this).balance >= ethAmount, "Insufficient ETH balance");
        require(balanceOf(address(this)) >= tokenAmount, "Insufficient token balance");

        // Capture initial balances
        uint256 initialEthBalance = address(this).balance;
        uint256 initialTokenBalance = balanceOf(address(this));

        // Add liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, address(this), block.timestamp);

        // Post-conditions: Check the balances after adding liquidity
        require(address(this).balance <= initialEthBalance - ethAmount, "Failed to add ETH to the liquidity pool");
        require(balanceOf(address(this)) < initialTokenBalance, "Failed to add tokens to the liquidity pool");

        // Emit event for liquidity addition
        emit LiquidityAdded(tokenAmount, ethAmount);
    }

    function burnLiquidity() external onlyOwner {
        IERC20 lpToken = IERC20(uniswapV2Pair);
        uint256 balance = lpToken.balanceOf(address(this));

        bool lpTransferSuccess = lpToken.transfer(address(0), balance);
        require(lpTransferSuccess, "Failed to burn liquidity");

        emit LiquidityBurned(balance);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public {
        require(_owner == msg.sender, "Not the contract owner");
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Not the contract owner");
        _;
    }

    receive() external payable {}
}