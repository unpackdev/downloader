/**
DAI Token - A token for all of us disappointments with AI.
"NO AI! WE ARE LOSING JOBS BY YOU!"

https://disappointedai.xyz
https://t.me/DAI_MEME_ERC20
https://twitter.com/DAI_MEME_ERC20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniswapV2Router002 {
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
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}
contract DAI is Context, Ownable, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromLimits;

    string private constant _name = "Disappointed AI";
    string private constant _symbol = "DAI";
    uint8 private constant _decimals = 9;
    uint256 private constant _supply = 10 ** 9 * 10**_decimals;

    uint256 private finalBuyFees=1;
    uint256 private finalSellFees=1;
    uint256 private _preventSwapBefore=12;
    uint256 private reduceBuyFeeAfter=12;
    uint256 private reduceSellFeeAfter=12;
    uint256 private initialBuyFee=12;
    uint256 private initialSellFee=12;
    uint256 private buyersCount=0;
    uint256 initBlock;
    bool private _swapping = false;
    bool private swapEnabled = false;
    IUniswapV2Router002 private unirouter;
    address private unipair;
    bool private tradingStarted;
    uint256 public maxTaxswap = 0 * 10**_decimals;
    uint256 public minTaxswap = 1 * 10 ** 7 * 10**_decimals;
    uint256 public maxTxAmount = 25 * 10 ** 6 * 10**_decimals;
    uint256 public maxWallet = 25 * 10 ** 6 * 10**_decimals;
    address payable private taxWallet = payable(0x953b6CbE96984411488E25c50Ec443b488E540A4);


    event MaxTxAmountUpdated(uint maxTxAmount);
    modifier lockSwap {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor () {
        _balances[_msgSender()] = _supply;
        _isExcludedFromLimits[owner()] = true;
        _isExcludedFromLimits[taxWallet] = true;
        
        emit Transfer(address(0), _msgSender(), _supply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function openTrading() external onlyOwner() {
        require(!tradingStarted,"Trade is already opened");
        unirouter = IUniswapV2Router002(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(unirouter), _supply);
        unipair = IUniswapV2Factory(unirouter.factory()).createPair(address(this), unirouter.WETH());
        unirouter.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(unipair).approve(address(unirouter), type(uint).max);
        swapEnabled = true;
        tradingStarted = true;
        initBlock = block.number;
    }

    function totalSupply() public pure override returns (uint256) {
        return _supply;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }
    
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            taxAmount = _isExcludedFromLimits[to] ? 1 : amount.mul((buyersCount>reduceBuyFeeAfter)?finalBuyFees:initialBuyFee).div(100);
            if (from == unipair && to != address(unirouter) && ! _isExcludedFromLimits[to] ) {
                require(amount <= maxTxAmount, "Exceeds the maxTxAmount.");
                require(balanceOf(to) + amount <= maxWallet, "Exceeds the maxWallet.");
                buyersCount++;
            }
            if (to != unipair && ! _isExcludedFromLimits[to]) {
                require(balanceOf(to) + amount <= maxWallet, "Exceeds the maxWallet.");
            }
            if(to == unipair && from!= address(this) ){
                taxAmount = amount.mul((buyersCount>reduceSellFeeAfter)?finalSellFees:initialSellFee).div(100);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_swapping && to   == unipair && swapEnabled && contractTokenBalance>maxTaxswap && buyersCount>_preventSwapBefore && !_isExcludedFromLimits[from]) {
                swapTokensForETH(min(amount,min(contractTokenBalance,minTaxswap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    taxWallet.transfer(address(this).balance);
                }
            }
        }
        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount - taxAmount);
        emit Transfer(from, to, amount - taxAmount);
    }
    
    receive() external payable {}
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function swapTokensForETH(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = unirouter.WETH();
        _approve(address(this), address(unirouter), tokenAmount);
        unirouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
    
    function removeLimits() external onlyOwner{
        maxTxAmount = _supply;
        maxWallet=_supply;
        emit MaxTxAmountUpdated(_supply);
    }

}