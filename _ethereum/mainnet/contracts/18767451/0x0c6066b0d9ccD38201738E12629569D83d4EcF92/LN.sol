// SPDX-License-Identifier: MIT

/**
Swap Bitcoin and Stacks Safely with Lightning.

Website: https://www.lnswap.tech
Telegram: https://t.me/lnswap_erc
Twitter: https://twitter.com/lnswap_erc
Dapp: https://app.lnswap.tech
 */

pragma solidity 0.8.19;

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
    function createPair(address tokenA, address tokenB) external returns (address uniswapPair);
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

contract LN is IERC20, Ownable {
    using SafeMath for uint256;

    string constant _name = "LNSwap";
    string constant _symbol = "LN";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 10 ** 9 * (10 ** _decimals);

    uint256 liquidityFee = 0; 
    uint256 marketingFee = 18;
    uint256 _totalFee = liquidityFee + marketingFee;
    uint256 _denominator = 100;
    uint256 public _maxTxAmounts = (_totalSupply * 30) / 1000;
    address public taxWallet;
    IUniswapRouter public uniswapRouter;
    address public uniswapPair;

    bool public taxSwapEnabled = false;
    uint256 public swapFeeAt = _totalSupply / 100000; // 0.5%

    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isExcludedFromFees;
    mapping (address => bool) isExcludedFromMaxTx;
    bool _swapping;

    modifier lockSwap() { _swapping = true; _; _swapping = false; }

    constructor () Ownable(msg.sender) {
        uniswapRouter = IUniswapRouter(routerAddress);
        uniswapPair = IUniswapFactory(uniswapRouter.factory()).createPair(uniswapRouter.WETH(), address(this));
        _allowances[address(this)][address(uniswapRouter)] = type(uint256).max;

        address _owner = owner;
        taxWallet = 0x7ef29158C45a58cA06dA5A73B1F4ba528ec8F304;
        isExcludedFromFees[taxWallet] = true;
        isExcludedFromMaxTx[_owner] = true;
        isExcludedFromMaxTx[taxWallet] = true;
        isExcludedFromMaxTx[DEAD] = true;

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
                
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(_swapping){ return _basicTransfer(sender, recipient, amount); }
        
        if (recipient != uniswapPair && recipient != DEAD) {
            require(isExcludedFromMaxTx[recipient] || _balances[recipient] + amount <= _maxTxAmounts, "Transfer amount exceeds the bag size.");
        }        
        if(shouldSwapBack() && shouldTakeFee(sender) && recipient == uniswapPair && amount > swapFeeAt){ 
            swpaBack(); 
        } 
        bool shouldTax = shouldTakeFee(sender) || !taxSwapEnabled;
        if (shouldTax) {
            _balances[recipient] = _balances[recipient].add(chargeFees(sender, amount));
        } else {
            _balances[recipient] = _balances[recipient].add(amount);
        }

        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function chargeFees(address sender, uint256 amount) internal returns (uint256) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 feeAmount = amount.mul(_totalFee).div(_denominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }
        function shouldTakeFee(address sender) internal view returns (bool) {
        return !isExcludedFromFees[sender];
    }

    function setMaxTxAmount(uint256 amountPercent) external onlyOwner {
        _maxTxAmounts = (_totalSupply * amountPercent ) / 1000;
    }

    function setSwapEnabled(bool value) external onlyOwner {
        taxSwapEnabled = value;
    }

    function shouldSwapBack() internal view returns (bool) {
        return !_swapping
        && taxSwapEnabled
        && _balances[address(this)] >= swapFeeAt;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
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
    
    function swpaBack() internal lockSwap {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 amountToLiquify = contractTokenBalance.mul(liquidityFee).div(_totalFee).div(2);
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
        uint256 totalETHFee = _totalFee.sub(liquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH.mul(liquidityFee).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);


        (bool MarketingSuccess, /* bytes memory data */) = payable(taxWallet).call{value: amountETHMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");

        if(amountToLiquify > 0){
            uniswapRouter.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                taxWallet,
                block.timestamp
            );
        }
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
    
    function setTax(uint256 liquidityFee_, uint256 marketingFee_) external onlyOwner {
         liquidityFee = liquidityFee_; 
         marketingFee = marketingFee_;
         _totalFee = liquidityFee + marketingFee;
    }    
}