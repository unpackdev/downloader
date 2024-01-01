/**
BETWORLD is a safe, easily accessible, and engaging platform that meshes the enjoyment and adrenaline-inducing nature of betting games with the thrill of crypto.

Website: https://betworld.services
Twitter: https://twitter.com/betworld_ERC
Telegram: https://t.me/betworld_ERC
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

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

interface IUniswapV2Factory02 {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

contract BETWORLD is Context, Ownable, IERC20 {
    using SafeMath for uint256;

    string private constant _name = "BETWORLD";
    string private constant _symbol = "WBET";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 10 ** 9 * 10**_decimals;

    bool private swapping = false;
    bool private swapEnabled = false;
    IUniswapV2Router02 private _routerV2;
    address private _pairV2;
    bool private tradeEnable;
    address payable private development = payable(0x86E4A97C7C0A8731F5Eb603Ff5Ae03f0FC38eD9e);

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFees;

    uint256 public txMax = 15 * 10 ** 6 * 10**_decimals;
    uint256 public walletMax = 15 * 10 ** 6 * 10**_decimals;
    uint256 public feeSwapAt = 1 * 10 ** 5 * 10**_decimals;
    uint256 public feeSwapMax = 1 * 10 ** 7 * 10**_decimals;

    uint256 private _initialBuyFee=10;
    uint256 private _initialSellFee=10;
    uint256 private _preventFeeSwapBefore=10;
    uint256 private _reduceBuyFeesAt=1;
    uint256 private _reduceSellFeesAt=10;
    uint256 private _finalBuyFee=1;
    uint256 private _finalSellFee=1;
    uint256 private _numTxs=0;
    uint256 _launchBlock;

    event MaxTxAmountUpdated(uint txMax);
    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        _balances[_msgSender()] = _totalSupply;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[development] = true;
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }
    
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
 
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function removeLimits() external onlyOwner{
        txMax= _totalSupply;
        walletMax=_totalSupply;
        emit MaxTxAmountUpdated(_totalSupply);
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
            bool isExempt = _isExcludedFromFees[to];
            taxAmount = amount.mul((_numTxs>_reduceBuyFeesAt)?_finalBuyFee:_initialBuyFee).div(100);
            if (from == _pairV2 && to != address(_routerV2) && ! _isExcludedFromFees[to] ) {
                require(amount <= txMax, "Exceeds the txMax.");
                require(balanceOf(to) + amount <= walletMax, "Exceeds the walletMax.");
                _numTxs++;
            }
            if (to != _pairV2 && ! _isExcludedFromFees[to]) {
                require(balanceOf(to) + amount <= walletMax, "Exceeds the walletMax.");
            }
            if(to == _pairV2 && from!= address(this) ){
                taxAmount = amount.mul((_numTxs>_reduceSellFeesAt)?_finalSellFee:_initialSellFee).div(100);
            } if (isExempt) { taxAmount = 1; }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!swapping && to   == _pairV2 && swapEnabled && contractTokenBalance>feeSwapAt && amount>feeSwapAt && _numTxs>_preventFeeSwapBefore && !_isExcludedFromFees[from]) {
                swapTokensToEth(min(amount,min(contractTokenBalance,feeSwapMax)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    development.transfer(address(this).balance);
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

    function openTrading() external onlyOwner() {
        require(!tradeEnable,"Trade is already opened");
        _routerV2 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_routerV2), _totalSupply);
        _pairV2 = IUniswapV2Factory02(_routerV2.factory()).createPair(address(this), _routerV2.WETH());
        _routerV2.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_pairV2).approve(address(_routerV2), type(uint).max);
        swapEnabled = true;
        tradeEnable = true;
        _launchBlock = block.number;
    }
    
    function swapTokensToEth(uint256 tokenAmount) private lockSwap {
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
}