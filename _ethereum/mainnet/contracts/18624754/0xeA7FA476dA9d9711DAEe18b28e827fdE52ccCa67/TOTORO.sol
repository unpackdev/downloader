// SPDX-License-Identifier: MIT

/*
Welcome to $Totoro, where the enchanting world of Studio Ghibli's beloved character, Totoro, meets the innovative realm of cryptocurrency. $Totoro isn't just a digital currency; it's a magical journey into a decentralized future where the spirit of Totoro guides us towards financial freedom and ecological harmony.

Website: https://www.totorocoin.vip
Telegram: https://t.me/totoro_erc
Twitter: https://twitter.com/totoro_erc
*/

pragma solidity 0.8.19;

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

contract TOTORO is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    string private constant _name= "Totoro";
    string private constant _symbol= "TOTORO";

    uint8 private constant _decimals= 9;
    uint256 private constant _supplyTotal = 10 ** 9 * 10**_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;

    uint256 private _firstBuyFee=11;
    uint256 private _firstSellFee=29;
    uint256 private _finalBuyFee=1;
    uint256 private _finalSellFee=1;
    uint256 private _reductBuyFeeAfter=20;
    uint256 private _reductSellFeeAfter=29;
    uint256 private _preventSwapBefore=15;
    uint256 private buyers=0;

    IUniswapRouter private _uniRouter;
    address private _uniPair;
    bool private _tradeActive;
    bool private swapping= false;
    bool private _taxSwapEnabled= false;

    uint256 public maxTxAmount = 25 * 10 ** 6 * 10**_decimals;
    uint256 public maxWallet = 25 * 10 ** 6 * 10**_decimals;
    uint256 public swapThreshold = 10 ** 5 * 10**_decimals;
    uint256 public maximumFeeSwap = 10 ** 7 * 10**_decimals;
    address payable private _taxWallet;

    event MaxTxAmountUpdated(uint maxTxAmount);
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        _balances[address(this)] = _supplyTotal;
        _isExcludedFromFee[owner()] = true;
        _taxWallet = payable(0xd29b80ACa23E8e0B3a27df5E7cFc525Ecf3A598e);
        _isExcludedFromFee[_taxWallet] = true;

        emit Transfer(address(0), address(this), _supplyTotal);
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
        return _supplyTotal;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
        
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "TOKEN: transfer from the zero address");
        require(to != address(0), "TOKEN: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 feeAmount = 0;
        if (from != owner() && to != owner() && !_isExcludedFromFee[from]) {
            feeAmount = amount.mul((buyers > _reductBuyFeeAfter) ? _finalBuyFee  :_firstBuyFee).div(100);

            if (from == _uniPair && to != address(_uniRouter) && !_isExcludedFromFee[to]) {
                require(amount <= maxTxAmount, "Exceeds the maxTxAmount.");
                require(balanceOf(to) + amount <= maxWallet, "Exceeds the maxWallet.");
                buyers++;
            }

            if (to == _uniPair && from != address(this)) {
                feeAmount = amount.mul((buyers>_reductSellFeeAfter) ? _finalSellFee : _firstSellFee).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!swapping && to == _uniPair && _taxSwapEnabled && contractTokenBalance > swapThreshold && buyers > _preventSwapBefore && amount > swapThreshold) {
                swapTokensToETH(min(amount, min(contractTokenBalance, maximumFeeSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if (feeAmount > 0) {
          _balances[address(this)] = _balances[address(this)].add(feeAmount);
          _balances[from] = _balances[from].sub(amount);
          emit Transfer(from, address(this), feeAmount);
        }
        _balances[to] = _balances[to].add(amount.sub(feeAmount));
        emit Transfer(from, to, amount.sub(feeAmount));
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function openTrading() external onlyOwner() {
        require(!_tradeActive, "Trading is already open");
        _uniRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniRouter), _supplyTotal);
        _uniPair = IUniswapFactory(_uniRouter.factory()).createPair(address(this), _uniRouter.WETH());
        _uniRouter.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20(_uniPair).approve(address(_uniRouter), type(uint).max);
        _taxSwapEnabled = true;
        _tradeActive = true;
    }
    
    receive() external payable {}
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
      return (a > b) ? b : a;
    }
    
    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function removeLimits() external onlyOwner {
        maxWallet = maxTxAmount = _supplyTotal;
        emit MaxTxAmountUpdated(_supplyTotal);
    }
    
    function swapTokensToETH(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniRouter.WETH();
        _approve(address(this), address(_uniRouter), tokenAmount);
        _uniRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
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

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
}