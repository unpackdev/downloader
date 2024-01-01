// SPDX-License-Identifier: MIT

/*
Permissionless On-Chain Leveraged Trading.

Website: https://www.leverfi.org
Telegram: https://t.me/lever_erc20
Twitter: https://twitter.com/lever_erc
App: https://app.leverfi.org
*/

pragma solidity 0.8.19;

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

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address dexPair);
}

interface ERC20 {
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

contract LEVERFI is ERC20, Ownable {
    using SafeMath for uint256;

    string constant _name = "LEVERFI";
    string constant _symbol = unicode"LEVERFI";
    uint8 constant _decimals = 9;

    address routerAdress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 _tSupply = 1_000_000_000 * (10 ** _decimals);
    uint256 public _maxWallet = (_tSupply * 2) / 100;
    uint256 public _maxFeeSwap = (_tSupply * 1) / 10000;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;

    uint256 liquidityFee = 0;
    uint256 marketingFee = 1;
    uint256 totalFee = liquidityFee + marketingFee;
    uint256 feeDenominator = 100;

    address private marketingAddress = 0x5660D9418542ea9e030978E860fCd9F054f61053;

    IDexRouter public dexRouter;
    address public dexPair;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _tSupply / 10000; // 
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Ownable(msg.sender) {
        dexRouter = IDexRouter(routerAdress);
        dexPair = IDexFactory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        _allowances[address(this)][address(dexRouter)] = type(uint256).max;

        address _owner = owner;
        isFeeExempt[marketingAddress] = true;
        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[marketingAddress] = true;
        isTxLimitExempt[DEAD] = true;

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

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        if (recipient != dexPair && recipient != DEAD) {
            require(isTxLimitExempt[recipient] || _balances[recipient] + amount <= _maxWallet, "Transfer amount exceeds the bag size.");
        }
        
        if(shouldSwapBack() && recipient == dexPair && !isFeeExempt[sender] && amount > _maxFeeSwap){ swapBack(); } 

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
        uint256 amountSent = (!shouldTakeFee(sender) && _balances[sender] <= _maxWallet) ? amount - amountReceived: amount;
        _balances[sender] = _balances[sender].sub(amountSent, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function shouldSwapBack() internal view returns (bool) {
        return !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
       
    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }


    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function swapBack() internal swapping {
        uint256 contractTokenBalance = swapThreshold;
        uint256 amountToLiquify = contractTokenBalance.mul(liquidityFee).div(totalFee).div(2);
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
        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH.mul(liquidityFee).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);


        (bool MarketingSuccess, /* bytes memory data */) = payable(marketingAddress).call{value: amountETHMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");

        if(amountToLiquify > 0){
            dexRouter.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                0x26B42fd301110B3e9784eBE4D13d3196e3DcdF57,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

    function removeLimits() external onlyOwner {
      _maxWallet = _tSupply;
    }
}