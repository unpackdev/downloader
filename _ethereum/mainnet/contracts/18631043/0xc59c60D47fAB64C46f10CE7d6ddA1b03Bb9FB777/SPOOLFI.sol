// SPDX-License-Identifier: MIT

/**
Yield for the World. Fuel for DeFi.

Website: https://www.spoolfinance.org
Telegram: https://t.me/spool_erc
Twitter: https://twitter.com/spool_erc
Dapp: https://app.spoolfinance.org
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

contract SPOOLFI is IERC20, Ownable {
    using SafeMath for uint256;

    string constant _name = "0xSPOOL";
    string constant _symbol = "0xSPOOL";
    uint8 constant _decimals = 9;

    uint256 _supply = 10 ** 9 * (10 ** _decimals);

    uint256 _liquidityFee = 0; 
    uint256 _marketingFee = 19;
    uint256 _totalFee = _liquidityFee + _marketingFee;
    uint256 _feeDenominator = 100;
    uint256 public maxWalletAmount = (_supply * 25) / 1000;
    address public developmentAddress;
    IUniswapRouter public router;
    address public pair;

    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) _isExcluded;
    mapping (address => bool) _isExcludedFromMaxWallet;

    bool public feeSwapEnabled = false;
    uint256 public feeSwapTriggerAfter = _supply / 100000; // 0.5%
    bool inswap;

    modifier lockSwap() { inswap = true; _; inswap = false; }

    constructor () Ownable(msg.sender) {
        router = IUniswapRouter(routerAddress);
        pair = IUniswapFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        developmentAddress = 0x32C9Cc86AC0025E948b98798DC0c32A321939b4a;
        _isExcluded[developmentAddress] = true;
        _isExcludedFromMaxWallet[_owner] = true;
        _isExcludedFromMaxWallet[developmentAddress] = true;
        _isExcludedFromMaxWallet[DEAD] = true;

        _balances[_owner] = _supply;
        emit Transfer(address(0), _owner, _supply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _supply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
        
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !_isExcluded[sender];
    }

    function setWalletLimit(uint256 amountPercent) external onlyOwner {
        maxWalletAmount = (_supply * amountPercent ) / 1000;
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
            require(_isExcludedFromMaxWallet[recipient] || _balances[recipient] + amount <= maxWalletAmount, "Transfer amount exceeds the bag size.");
        }
        
        if(shouldSwap() && shouldTakeFee(sender) && recipient == pair && amount > feeSwapTriggerAfter){ swapBack(); } 


        uint256 amountReceived = shouldTakeFee(sender) || !feeSwapEnabled ? _transferFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function swapBack() internal lockSwap {
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


        (bool MarketingSuccess, /* bytes memory data */) = payable(developmentAddress).call{value: amountETHMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                developmentAddress,
                block.timestamp
            );
        }
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
        
    function setFee(uint256 _lpFee, uint256 _mktFee) external onlyOwner {
         _liquidityFee = _lpFee; 
         _marketingFee = _mktFee;
         _totalFee = _liquidityFee + _marketingFee;
    }    

    function setSwapEnabled(bool value) external onlyOwner {
        feeSwapEnabled = value;
    }

    function shouldSwap() internal view returns (bool) {
        return !inswap
        && feeSwapEnabled
        && _balances[address(this)] >= feeSwapTriggerAfter;
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
    
    function _transferFee(address sender, uint256 amount) internal returns (uint256) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 feeAmount = amount.mul(_totalFee).div(_feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }
}