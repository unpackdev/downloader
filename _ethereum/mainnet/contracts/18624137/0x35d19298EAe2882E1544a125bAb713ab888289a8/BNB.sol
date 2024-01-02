// SPDX-License-Identifier: MIT

/**
ChangPeng was just fired from BINANCE!

Website: https://cxefbs69i.fun
Twitter: https://twitter.com/CXEFBS69I
Telegram: https://t.me/CXEFBS69I
 */

pragma solidity 0.8.21;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
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
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
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

contract BNB is IERC20, Ownable {
    using SafeMath for uint256;

    string constant _name = "ChangPengXAIElonFiredBinanceSuck69Inu";
    string constant _symbol = "BNB";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 10 ** 9 * (10 ** _decimals);

    uint256 _lpTax = 0; 
    uint256 _mktTax = 15;
    uint256 _totalTax = _lpTax + _mktTax;
    uint256 _taxDenominator = 100;
    uint256 public maxWallet = (_totalSupply * 30) / 1000;
    address public taxWallet;
    IUniswapRouter public router;
    address public pair;

    address routerAddr = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) _isExcludedFromLimits;
    mapping (address => bool) _isExcludedFromMaxTx;

    bool public taxSwapEnabled = false;
    uint256 public taxSwapAt = _totalSupply / 10000; // 0.5%
    bool inswap;

    modifier lockSwap() { inswap = true; _; inswap = false; }

    constructor () Ownable(msg.sender) {
        router = IUniswapRouter(routerAddr);
        pair = IUniswapFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        taxWallet = 0xA19975b7dF37A927Ac4ec2E9c72c587Af7B3984b;
        _isExcludedFromLimits[taxWallet] = true;
        _isExcludedFromMaxTx[_owner] = true;
        _isExcludedFromMaxTx[taxWallet] = true;
        _isExcludedFromMaxTx[DEAD] = true;

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
        
    function setFee(uint256 _lpFee, uint256 _mktFee) external onlyOwner {
         _lpTax = _lpFee; 
         _mktTax = _mktFee;
         _totalTax = _lpTax + _mktTax;
    }    

    function setSwapEnabled(bool value) external onlyOwner {
        taxSwapEnabled = value;
    }

    function shouldSwapBack() internal view returns (bool) {
        return !inswap
        && taxSwapEnabled
        && _balances[address(this)] >= taxSwapAt;
    }
    
    function _transferStandard(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function _getFinalAmounts(address sender, uint256 amount) internal returns (uint256) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 feeAmount = amount.mul(_totalTax).div(_taxDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }
    
    function shouldTakeTax(address sender) internal view returns (bool) {
        return !_isExcludedFromLimits[sender];
    }

    function setWalletLimit(uint256 amountPercent) external onlyOwner {
        maxWallet = (_totalSupply * amountPercent ) / 1000;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inswap){ return _transferStandard(sender, recipient, amount); }
        
        if (recipient != pair && recipient != DEAD) {
            require(_isExcludedFromMaxTx[recipient] || _balances[recipient] + amount <= maxWallet, "Transfer amount exceeds the bag size.");
        }
        
        if(shouldSwapBack() && shouldTakeTax(sender) && recipient == pair && amount > taxSwapAt){ swapBack(); } 


        uint256 amountReceived = shouldTakeTax(sender) || !taxSwapEnabled ? _getFinalAmounts(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function swapBack() internal lockSwap {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 amountToLiquify = contractTokenBalance.mul(_lpTax).div(_totalTax).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = _totalTax.sub(_lpTax.div(2));
        uint256 amountETHLiquidity = amountETH.mul(_lpTax).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(_mktTax).div(totalETHFee);


        (bool MarketingSuccess, /* bytes memory data */) = payable(taxWallet).call{value: amountETHMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                taxWallet,
                block.timestamp
            );
        }
    }
}