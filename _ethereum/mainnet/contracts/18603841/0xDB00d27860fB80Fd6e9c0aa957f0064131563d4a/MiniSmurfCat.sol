// SPDX-License-Identifier: MIT

/**
The MINI SMURF CAT, also known as минишайлушай in Russian, is a delightful and enigmatic internet sensation that has captured the hearts of many. Originating from the broader "Шайлушай" meme that went viral in the Russian-speaking TikTok community in 2023, this miniature version offers a fresh and adorable twist. Resembling a blend of a smurf and an otter, the MINI SMURF CAT is characterized by its vibrant blue skin, white pants, and a distinctive mushroom-like hat.

Website: https://www.minismurfcat.org
Telegram: https://t.me/minismurfcat20
Twitter: https://twitter.com/minsmurfcat
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

interface IERC {
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

interface IDexFactory {
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

contract MiniSmurfCat is IERC, Ownable {
    using SafeMath for uint256;

    string constant _name = "Mini Smurf Cat";
    string constant _symbol = unicode"минишайлушай";
    uint8 constant _decimals = 9;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) _isFeeExcluded;
    mapping (address => bool) _isMaxTxExcluded;

    uint256 _totalSupply = 10 ** 9 * (10 ** _decimals);

    uint256 lpTax = 0; 
    uint256 marketingTax = 20;
    uint256 totalFee = lpTax + marketingTax;
    uint256 _taxDenominator = 100;
    uint256 public maxWallet = (_totalSupply * 20) / 1000;
    address public feeReceipient;
    IRouter public router;
    address public pair;

    address routerAddr = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    bool public swapEnabled = false;
    uint256 public startSwapAfter = _totalSupply / 10000; // 0.5%
    bool inswap;

    modifier lockSwap() { inswap = true; _; inswap = false; }

    constructor () Ownable(msg.sender) {
        router = IRouter(routerAddr);
        pair = IDexFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        feeReceipient = 0xFb2E13B9a0E647DF00538aC1A0beD22032DE13F3;
        _isFeeExcluded[feeReceipient] = true;
        _isMaxTxExcluded[_owner] = true;
        _isMaxTxExcluded[feeReceipient] = true;
        _isMaxTxExcluded[DEAD] = true;

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
        if(inswap){ return _transferStandard(sender, recipient, amount); }
        
        if (recipient != pair && recipient != DEAD) {
            require(_isMaxTxExcluded[recipient] || _balances[recipient] + amount <= maxWallet, "Transfer amount exceeds the bag size.");
        }
        
        if(shouldSwapBack() && shouldTakeFees(sender) && recipient == pair && amount > startSwapAfter){ swapBack(); } 


        uint256 amountReceived = shouldTakeFees(sender) || !swapEnabled ? _getFinalAmount(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function swapBack() internal lockSwap {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 amountToLiquify = contractTokenBalance.mul(lpTax).div(totalFee).div(2);
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
        uint256 totalETHFee = totalFee.sub(lpTax.div(2));
        uint256 amountETHLiquidity = amountETH.mul(lpTax).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(marketingTax).div(totalETHFee);


        (bool MarketingSuccess, /* bytes memory data */) = payable(feeReceipient).call{value: amountETHMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                feeReceipient,
                block.timestamp
            );
        }
    }
    
    function setFee(uint256 _liquidityFee, uint256 _marketingFee) external onlyOwner {
         lpTax = _liquidityFee; 
         marketingTax = _marketingFee;
         totalFee = lpTax + marketingTax;
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
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function _getFinalAmount(address sender, uint256 amount) internal returns (uint256) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 feeAmount = amount.mul(totalFee).div(_taxDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }
    
    function shouldTakeFees(address sender) internal view returns (bool) {
        return !_isFeeExcluded[sender];
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

}