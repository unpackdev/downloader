// SPDX-License-Identifier: MIT

/**
Welcome to Quiz AI - An AI Powered Quiz and Trivia Bot

Quiz AI is a Play 2 Win Trivia Competition Bot that leverages AI and gamification. Bet someone 1 on 1. Bet a group of friends. Or give out prizes and rewards in your crypto project.

Quiz AI gives you the ability to choose from our preselected trivia topics or you can create ANY trivia topic you want and our AI-powered bot will  generate a challenging trivia quiz tailored just for you, your friends or your crypto project's community.

Web: https://quizai.fun
Tg: https://t.me/Quiz_AI_ERC
X: https://twitter.com/Quiz_AI_ERC
Bot: https://t.me/QuizBot
 */

pragma solidity 0.8.21;

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

interface IRouter {
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

contract QUIZAI is IERC20, Ownable {
    using SafeMath for uint256;

    string constant _name = "Quiz AI Bot";
    string constant _symbol = "QUIZ-AI";
    uint8 constant _decimals = 9;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) _isFeeExempt;
    mapping (address => bool) _isMaxTxExempt;

    uint256 _tTotal = 10 ** 9 * (10 ** _decimals);

    uint256 _liquidityFee = 0; 
    uint256 _marketingFee = 25;
    uint256 _totalFee = _liquidityFee + _marketingFee;
    uint256 _denominator = 100;
    uint256 public maxWalletsize = (_tTotal * 30) / 1000;
    address public feeAddress;
    IRouter public router;
    address public pair;

    address routerAddr = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    bool public swapEnabled = false;
    uint256 public startSwapAfter = _tTotal / 10000; // 0.5%
    bool inswap;

    modifier lockSwap() { inswap = true; _; inswap = false; }

    constructor () Ownable(msg.sender) {
        router = IRouter(routerAddr);
        pair = IUniswapFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        feeAddress = 0x13b48B5e7b6ab0554d8E8B9f4e30d03bd4b93D78;
        _isFeeExempt[feeAddress] = true;
        _isMaxTxExempt[_owner] = true;
        _isMaxTxExempt[feeAddress] = true;
        _isMaxTxExempt[DEAD] = true;

        _balances[_owner] = _tTotal;
        emit Transfer(address(0), _owner, _tTotal);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _tTotal; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
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
    
    function _getTAmount(address sender, uint256 amount) internal returns (uint256) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 feeAmount = amount.mul(_totalFee).div(_denominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }
    
    function shouldCharge(address sender) internal view returns (bool) {
        return !_isFeeExempt[sender];
    }

    function setWalletLimit(uint256 amountPercent) external onlyOwner {
        maxWalletsize = (_tTotal * amountPercent ) / 1000;
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
            require(_isMaxTxExempt[recipient] || _balances[recipient] + amount <= maxWalletsize, "Transfer amount exceeds the bag size.");
        }
        
        if(shouldSwapBack() && shouldCharge(sender) && recipient == pair && amount > startSwapAfter){ swapTokens(); } 


        uint256 amountReceived = shouldCharge(sender) || !swapEnabled ? _getTAmount(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function swapTokens() internal lockSwap {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 amountToLiquify = contractTokenBalance.mul(_liquidityFee).div(_totalFee).div(2);
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
        uint256 totalETHFee = _totalFee.sub(_liquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH.mul(_liquidityFee).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(_marketingFee).div(totalETHFee);


        (bool MarketingSuccess, /* bytes memory data */) = payable(feeAddress).call{value: amountETHMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                feeAddress,
                block.timestamp
            );
        }
    }
    
    function setFee(uint256 _lpFee, uint256 _mktFee) external onlyOwner {
         _liquidityFee = _lpFee; 
         _marketingFee = _mktFee;
         _totalFee = _liquidityFee + _marketingFee;
    }    

    function setSwapEnabled(bool value) external onlyOwner {
        swapEnabled = value;
    }

    function shouldSwapBack() internal view returns (bool) {
        return !inswap
        && swapEnabled
        && _balances[address(this)] >= startSwapAfter;
    }
}