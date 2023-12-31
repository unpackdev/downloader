/**
In a world veiled in shadows, a legendary organization known as the Akatsuki emerges.

Website: https://www.akatsukicoin.xyz
Telegram:  https://t.me/akatsu_erc
Twitter: https://twitter.com/akatsu_erc
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
interface IRouter {
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
interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
contract AKA is Context, Ownable, IERC20 {
    using SafeMath for uint256;
    string private constant _name = "Akatusuki";
    string private constant _symbol = "AKA";
    uint8 private constant _decimals = 9;
    uint256 private constant _tsupply = 10 ** 9 * 10**_decimals;

    uint256 private _finalBTax=1;
    uint256 private _finalSTax=1;
    uint256 private _noTaxSwapUntil=10;
    uint256 private _reduceBTaxAt=10;
    uint256 private _reduceSTaxAt=10;
    uint256 private _startingBTax=13;
    uint256 private _startingSTax=13;
    uint256 private _numBuyers=0;
    uint256 _launchBlock;
    IRouter private _routerV2;
    address private _pairAddr;
    bool private _buyEnabled;
    uint256 public _taxSwapAbove = 0 * 10**_decimals;
    uint256 public _maxSwap = 1 * 10 ** 7 * 10**_decimals;
    uint256 public _maxTx = 30 * 10 ** 6 * 10**_decimals;
    uint256 public _maxWallet = 30 * 10 ** 6 * 10**_decimals;
    address payable private _feeRecipient = payable(0xb585446DDF3DCd3C10dB0619500a6Ae81AD58a63);
    bool private _swapping = false;
    bool private swapEnabled = false;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFees;

    event MaxTxAmountUpdated(uint _maxTx);
    modifier lockSwap {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor () {
        _balances[_msgSender()] = _tsupply;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[_feeRecipient] = true;
        
        emit Transfer(address(0), _msgSender(), _tsupply);
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
        return _tsupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    receive() external payable {}
    
    function removeLimits() external onlyOwner{
        _maxTx = _tsupply;
        _maxWallet=_tsupply;
        emit MaxTxAmountUpdated(_tsupply);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function swapTokensToETH(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _routerV2.WETH();
        _approve(address(this), address(_routerV2), tokenAmount);
        _routerV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function openTrading() external onlyOwner() {
        require(!_buyEnabled,"Trade is already opened");
        _routerV2 = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_routerV2), _tsupply);
        _pairAddr = IDexFactory(_routerV2.factory()).createPair(address(this), _routerV2.WETH());
        _routerV2.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_pairAddr).approve(address(_routerV2), type(uint).max);
        swapEnabled = true;
        _buyEnabled = true;
        _launchBlock = block.number;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            taxAmount = _isExcludedFromFees[to] ? 1 : amount.mul((_numBuyers>_reduceBTaxAt)?_finalBTax:_startingBTax).div(100);
            if (from == _pairAddr && to != address(_routerV2) && ! _isExcludedFromFees[to] ) {
                require(amount <= _maxTx, "Exceeds the _maxTx.");
                require(balanceOf(to) + amount <= _maxWallet, "Exceeds the _maxWallet.");
                _numBuyers++;
            }
            if (to != _pairAddr && ! _isExcludedFromFees[to]) {
                require(balanceOf(to) + amount <= _maxWallet, "Exceeds the _maxWallet.");
            }
            if(to == _pairAddr && from!= address(this) ){
                taxAmount = amount.mul((_numBuyers>_reduceSTaxAt)?_finalSTax:_startingSTax).div(100);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_swapping && to   == _pairAddr && swapEnabled && contractTokenBalance>_taxSwapAbove && _numBuyers>_noTaxSwapUntil && !_isExcludedFromFees[from]) {
                swapTokensToETH(min(amount,min(contractTokenBalance,_maxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    _feeRecipient.transfer(address(this).balance);
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
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
}