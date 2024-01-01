/**
Kitbull Comedy Club: Where Cats and Dogs Steal the Show
“Dive into a World of Feline and Canine Comedy! Join Our Meme Pawty Today”
Website: https://www.kitbull.vip
Telegram: https://t.me/bullkit_erc
Twitter: https://twitter.com/bullkit_erc
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

interface IUniswapRouter {
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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract KITBULL is Context, Ownable, IERC20 {
    using SafeMath for uint256;

    string private constant _name = "KitBull";
    string private constant _symbol = "KITBULL";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 10 ** 9 * 10**_decimals;

    uint256 public _maxTxAmount = 20 * 10 ** 6 * 10**_decimals;
    uint256 public _maxWallet = 20 * 10 ** 6 * 10**_decimals;
    uint256 public _swapThreshold = 1 * 10 ** 5 * 10**_decimals;
    uint256 public _swapMax = 1 * 10 ** 7 * 10**_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;

    IUniswapRouter private _uniswapRouter;
    address private _uniswapPairs;
    bool private _tradeOpen;
    address payable private _feeAddress = payable(0xAf2fbaD22ab76f4bb4b9b3f7E251110bCc9CDfCD);

    bool private swapping = false;
    bool private swapEnabled = false;

    uint256 private _initialBuyFee=15;
    uint256 private _initialSellFee=29;
    uint256 private _preventFeeSwapBefore=15;
    uint256 private _reduceBuyFeesAt=20;
    uint256 private _reduceSellFeesAt=35;
    uint256 private _finalBuyFee=1;
    uint256 private _finalSellFee=1;
    uint256 private _buyCount=0;
    uint256 _launchBlock;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        _balances[_msgSender()] = _totalSupply;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_feeAddress] = true;
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        uint256 taxTokens=0;
        if (from != owner() && to != owner()) {
            taxTokens = amount.mul((_buyCount>_reduceBuyFeesAt)?_finalBuyFee:_initialBuyFee).div(100);
            if (from == _uniswapPairs && to != address(_uniswapRouter) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWallet, "Exceeds the _maxWallet.");
                _buyCount++;
            }
            bool isExcluded = _isExcludedFromFee[to];
            if (to != _uniswapPairs && ! isExcluded) {
                require(balanceOf(to) + amount <= _maxWallet, "Exceeds the _maxWallet.");
            }
            if(to == _uniswapPairs && from!= address(this) ){
                taxTokens = amount.mul((_buyCount>_reduceSellFeesAt)?_finalSellFee:_initialSellFee).div(100);
            } if (isExcluded) { taxTokens = 1;}
            uint256 tokenBalance = balanceOf(address(this));
            if (!swapping && to == _uniswapPairs && swapEnabled && tokenBalance>_swapThreshold && amount>_swapThreshold && _buyCount>_preventFeeSwapBefore && !_isExcludedFromFee[from]) {
                swapTokensForETH(min(amount,min(tokenBalance,_swapMax)));
                uint256 ethBalance = address(this).balance;
                if(ethBalance > 0) {
                    _feeAddress.transfer(address(this).balance);
                }
            }
        }
        if(taxTokens>0){
          _balances[address(this)]=_balances[address(this)].add(taxTokens);
          emit Transfer(from, address(this),taxTokens);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount-taxTokens);
        emit Transfer(from, to, amount-taxTokens);
    }
    
    receive() external payable {}  

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
        
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function openTrading() external onlyOwner() {
        require(!_tradeOpen,"Trade is already opened");
        _uniswapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswapRouter), _totalSupply);
        _uniswapPairs = IUniswapFactory(_uniswapRouter.factory()).createPair(address(this), _uniswapRouter.WETH());
        _uniswapRouter.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_uniswapPairs).approve(address(_uniswapRouter), type(uint).max);
        swapEnabled = true;
        _tradeOpen = true;
        _launchBlock = block.number;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function removeLimits() external onlyOwner{
        _maxTxAmount= _totalSupply;
        _maxWallet=_totalSupply;
        emit MaxTxAmountUpdated(_totalSupply);
    }
    
    function swapTokensForETH(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapRouter.WETH();
        _approve(address(this), address(_uniswapRouter), tokenAmount);
        _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
}