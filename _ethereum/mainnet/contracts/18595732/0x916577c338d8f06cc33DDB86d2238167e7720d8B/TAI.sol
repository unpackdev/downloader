// SPDX-License-Identifier: MIT

/**
Allow AI to do all the work on your behalf
The AI itself will find errors and vulnerabilities in the code and provide alternatives within seconds

Website: https://www.aitester.tech
Telegram: https://t.me/erc_testerai
Twitter: https://twitter.com/aitester_erc
App: https://app.aitester.tech
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

library SafeMathLibrary {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMathLibrary: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMathLibrary: subtraction overflow");
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
        require(c / a == b, "SafeMathLibrary: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMathLibrary: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address dexPair);
}

interface IDexRouter {
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

contract TAI is IERC20, Ownable {
    using SafeMathLibrary for uint256;

    string constant _name = "TesterAI";
    string constant _symbol = "TAI";
    uint8 constant _decimals = 9;

    uint256 _supplyTotal = 10 ** 9 * (10 ** _decimals);

    uint256 feeLP = 0; 
    uint256 feeMarketing = 29;
    uint256 feeTotal = feeLP + feeMarketing;
    uint256 feeDenominator = 100;
    uint256 public maxHold = (_supplyTotal * 20) / 1000;
    address public taxWallet;
    IDexRouter public dexRouter;
    address public dexPair;

    bool public swapEnabled = false;
    uint256 public startSwapAfter = _supplyTotal / 10000; // 0.5%
    bool inswap;

    address dexRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) _isExcludedFromFee;
    mapping (address => bool) _isExcludedFromMaxTx;

    modifier lockSwap() { inswap = true; _; inswap = false; }

    constructor () Ownable(msg.sender) {
        dexRouter = IDexRouter(dexRouterAddress);
        dexPair = IDexFactory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        _allowances[address(this)][address(dexRouter)] = type(uint256).max;

        address _owner = owner;
        taxWallet = 0x8d7B879a52389eFB33cB5Ad0082861B56526bAA6;
        _isExcludedFromFee[taxWallet] = true;
        _isExcludedFromMaxTx[_owner] = true;
        _isExcludedFromMaxTx[taxWallet] = true;
        _isExcludedFromMaxTx[DEAD] = true;

        _balances[_owner] = _supplyTotal;
        emit Transfer(address(0), _owner, _supplyTotal);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _supplyTotal; }
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
    
    function getTransferAmountAfterFee(address sender, uint256 amount) internal returns (uint256) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 feeAmount = amount.mul(feeTotal).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }
    
    function isTakeFee(address sender) internal view returns (bool) {
        return !_isExcludedFromFee[sender];
    }

    function setWalletLimit(uint256 amountPercent) external onlyOwner {
        maxHold = (_supplyTotal * amountPercent ) / 1000;
    }

    function setFee(uint256 _liquidityFee, uint256 _marketingFee) external onlyOwner {
         feeLP = _liquidityFee; 
         feeMarketing = _marketingFee;
         feeTotal = feeLP + feeMarketing;
    }    

    function setSwapEnabled(bool value) external onlyOwner {
        swapEnabled = value;
    }

    function shouldSwapBack() internal view returns (bool) {
        return !inswap
        && swapEnabled
        && _balances[address(this)] >= startSwapAfter;
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
        if(inswap){ return _transferStandard(sender, recipient, amount); }
        
        if (recipient != dexPair && recipient != DEAD) {
            require(_isExcludedFromMaxTx[recipient] || _balances[recipient] + amount <= maxHold, "Transfer amount exceeds the bag size.");
        }
        
        if(shouldSwapBack() && isTakeFee(sender) && recipient == dexPair && amount > startSwapAfter){ swapBack(); } 


        uint256 amountReceived = isTakeFee(sender) || !swapEnabled ? getTransferAmountAfterFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function swapBack() internal lockSwap {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 amountToLiquify = contractTokenBalance.mul(feeLP).div(feeTotal).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        uint256 balanceBefore = address(this).balance;

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = feeTotal.sub(feeLP.div(2));
        uint256 amountETHLiquidity = amountETH.mul(feeLP).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(feeMarketing).div(totalETHFee);


        (bool MarketingSuccess, /* bytes memory data */) = payable(taxWallet).call{value: amountETHMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");

        if(amountToLiquify > 0){
            dexRouter.addLiquidityETH{value: amountETHLiquidity}(
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