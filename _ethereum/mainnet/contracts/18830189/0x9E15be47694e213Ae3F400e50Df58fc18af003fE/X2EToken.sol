//SPDX-License-Identifier: Unlicensed

/**
X: https://twitter.com/x2ecosystem
Tg: https://t.me/x2ecosystem
Web: https://x2ecosystem.io
WP: https://x2eco.gitbook.io/x2e/welcome/introduction
**/

pragma solidity ^0.8.23;

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

contract X2EToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => mapping (address => uint256)) private _allowances;
    string private constant _name = unicode"X To Earn";
    string private constant _symbol = unicode"X2E";
    uint256 private constant _tTotal = 500e9 * 10 ** 9;
    uint256 private _swapTokensAtAmount = _tTotal / 1000;
    uint256 public _maxWalletAmount = _tTotal * 1 / 100;
    uint256 private _maxTaxSwap = _tTotal / 100;
    uint8 private constant _decimals = 9;
    uint256 public _totalBuyFees=20;
    uint256 public _totalSellFees=20;
    address private uniswapV2Pair;
    bool private inSwap = false;
    bool private swapEnabled = true;

    address payable _taxWallet;
    bool public tradingOpen;
    IUniswapV2Router02 uniswapV2Router;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => uint256) private _balances;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _taxWallet = payable(_msgSender());
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _isExcludedFromFee[address(this)] = true;
        _balances[msg.sender] = _tTotal;
        _isExcludedFromFee[address(uniswapV2Router)] = true;
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
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        uint256 taxAmount=0;
        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            require(tradingOpen, "Trade is not live yet!");

            taxAmount = amount.mul(_totalBuyFees).div(100);

            if (from == uniswapV2Pair) {
                require(balanceOf(to) + amount <= _maxWalletAmount, "Max wallet!");
            }

            if (to != uniswapV2Pair) {
                require(balanceOf(to) + amount <= _maxWalletAmount, "Max wallet ");
            }

            if(to == uniswapV2Pair){
                taxAmount = amount * _totalSellFees / 100;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance>_swapTokensAtAmount) {
                swapTokensForEth(min(amount,min(contractTokenBalance,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                     _taxWallet.transfer(address(this).balance);
                }
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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

    function excludeAccountFromFees(address account, bool status) external onlyOwner {
        _isExcludedFromFee[account] = status;
    }

    function startTrade() external onlyOwner {
        tradingOpen = true;
    }

    function setSwapEnabled(bool status) external onlyOwner {
        swapEnabled = status;
    }

    function setSwapTokensAtAmount(uint amount) external onlyOwner {
        _swapTokensAtAmount = amount;
    }

    function setFee(uint buy, uint sell) external onlyOwner {
        _totalBuyFees = buy;
        _totalSellFees = sell;
        require(buy <= 30 && sell <= 30);
    }

    function setMaxWalletAmount(uint amount) external onlyOwner {
        require(amount >= _tTotal / 400, "Max wallet size can't be lower than 0.2%");
        _maxWalletAmount = amount;
    }

    function _removeLimits() external onlyOwner{
        _maxWalletAmount = _tTotal;
    }

    receive() external payable {}
}