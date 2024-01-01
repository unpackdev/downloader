// SPDX-License-Identifier: MIT

/*
 █████ █████ ██████████ █████   ███   █████
 ░░███ ░░███ ░░███░░░░░█░░███   ░███  ░░███ 
  ░░███ ███   ░███  █ ░  ░███   ░███   ░███ 
   ░░█████    ░██████    ░███   ░███   ░███ 
    ░░███     ░███░░█    ░░███  █████  ███  
     ░███     ░███ ░   █  ░░░█████░█████░   
     █████    ██████████    ░░███ ░░███     
     ░░░░░    ░░░░░░░░░░      ░░░   ░░░      
                                        
╦  ╔═╗'┌─┐  ╔╗ ┬┌─┐┌─┐┌─┐┌─┐┌┬┐  ╔╦╗┌─┐┌┬┐┌─┐┌─┐┌─┐┬ ┌┐|
║  ╠═╣ └─┐  ╠╩╗││ ┬│ ┬├┤ └─┐ │   ║║║├┤ │││├┤ │  │ ││ │││
╩═╝╩ ╩ └─┘  ╚═╝┴└─┘└─┘└─┘└─┘ ┴   ╩ ╩└─┘┴ ┴└─┘└─┘└─┘┴ |└┘

Website: https://yew.cool 
Telegram: https://t.me/yewcoineth
Twitter/X: https://x.com/yewcoin


I’m a fellow degen, just like you, who knows the power that
crypto holds. I’ve spoken on some of crypto's largest
 stages and now wish to present a project to 
you, fren. Key point: Beyond the revolution of blockchain tech, there lies 
one of the biggest revolutions in currency and society as a whole: the memecoin. 

Here we outline a plan to create $YEW:

3 Step Formula For $YEW

1. Understand that memecoins bring liquidity to crypto. 

It is the number one place that retail investors get involved
with crypto, and one of the major talking points and news 
headlines of the last few years in crypto. Remember how big 
Doge was when it got on SNL? 

2. LA is a $1T+ economy, and is #1 for Influence. 

It is the 3rd largest economy in the world, and it holds the
most celebrity influence in the world. I’ve even met several A-Listers
at the grocery store here! 

3. Combine Memecoins and LA and Become LA’s biggest memecoin

We’re going to guerrilla market our way into the hearts and 
minds of the city. Imagine a team of internet degens with boots
on the ground in LA. We’ll be unstoppable. 

After we accomplish our goal, we’ll set our sights on a new city.
And accomplish more together than what we could ever imagine alone.

Expect more blockchain messages. 

Your well wisher,
Yewtoshi

*/

pragma solidity 0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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


contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
}

contract YEW is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private _holderLastBuyTimestamp;
    address payable private _taxWallet;

    uint256 public MEVandJeetPROTECTION = 15;
    uint256 public SAFE_HEAVEN = 0;
    uint256 private mevAndJeetProtectionTime = 5 minutes;
   

    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 100000000 * 10**_decimals; // 100 Million max supply
    string private constant _name = "YEW COIN";
    string private constant _symbol = "YEW";
    uint256 public _maxTxAmount =   2000000 * 10**_decimals; // max tokens can be transferred per transaction (2% of the supply)
    uint256 public _maxWalletSize = 2000000 * 10**_decimals; // max tokens that can bought per wallet (2% of the supply)
    uint256 public _taxSwapThreshold = 10000 * 10**_decimals; // threshold when collected tax tokens sold for eth (0.01% of the supply)

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _taxWallet = payable(0xd852cdB79610ec221744d08922231A452Accc13c);
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0;
         if (!_isExcludedFromFee [from] && !_isExcludedFromFee[to]) {
    
            uint256 timePassed = 0;
            uint256 tax = 0;
            if(from != uniswapV2Pair){
               timePassed = block.timestamp - _holderLastBuyTimestamp[from];
            }

            if(timePassed <= mevAndJeetProtectionTime){
                tax = MEVandJeetPROTECTION;
            } else {
                tax = SAFE_HEAVEN;
            }
            
              /// buy 
              if (from == uniswapV2Pair) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                 _holderLastBuyTimestamp[to] = block.timestamp;
                 /// sell
                } else if(to == uniswapV2Pair){
                    require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                    taxAmount = amount.mul(tax).div(100);
                /// transfer    
                } else{
                 require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");   
                 taxAmount = amount.mul(tax).div(100);
                }
            

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance>_taxSwapThreshold ) {
                swapTokensForEth(contractTokenBalance);
            
            }
        }

        if(taxAmount > 0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }


   

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        if(tokenAmount==0){return;}
        if(!tradingOpen){return;}
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            _taxWallet,
            block.timestamp
        );
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function removeTaxes() external onlyOwner{
        MEVandJeetPROTECTION = 0;
    }

    function setMevAndJeetProtectionTaxAndTime(uint256 _newTax, uint256 _time) external onlyOwner{
        require(_newTax <= 30, "Max tax value can't be more than 30");
        require(_time <= 1 hours, " Max time for mev protection is 1 hour");
        MEVandJeetPROTECTION = _newTax;
        mevAndJeetProtectionTime = _time;
    }

    function setTaxWallet (address payable _newWallet) external onlyOwner {
        _taxWallet = _newWallet;
    }

    function setSwapThreshold (uint256 amount) external onlyOwner {
        require(amount <= 1e7, "threshold limit must be less than equal to 1% of the supply");
        _taxSwapThreshold = amount * 1e18;
    }


    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    receive() external payable {}

    
    function manualSwap() external {
        require(_msgSender()==_taxWallet);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapTokensForEth(tokenBalance);
        }
        
    }
    
}