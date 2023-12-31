/**
Dear meme dreamers, it is now the moment to cast your sparkle upon the world!

Website: https://waifus.site
Twitter: https://twitter.com/waifu_ru
Telegram: https://t.me/xwaifu_ru
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

interface IRouterV2 {
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

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

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

contract WAIFU is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "Waifu";
    string private constant _symbol = unicode"Вайфу";

    uint8 private constant _decimals = 9;
    uint256 private constant _supplyTotal = 10 ** 9 * 10**_decimals;

    uint256 private _buyers=0;
    uint256 private _initialBuyTax=4;
    uint256 private _initialSellTax=4;
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;
    uint256 private _reduceBuyTaxAt=11;
    uint256 private _reduceSellTaxAt=11;
    uint256 private _preventSwapBefore=11;

    IRouterV2 private _router;
    address private _pair;
    bool private startedTrading;

    bool private inswap = false;
    bool private swapEnabled = false;
    address payable private taxWallet = payable(0xA2F498e3a3b3C4fa1C540DD17b2E47749592826E);
    uint256 launchBlock;

    uint256 public maxTxAmount = 5 * 10 ** 7 * 10**_decimals;
    uint256 public maxWallet = 5 * 10 ** 7 * 10**_decimals;
    uint256 public swapTriggerAmount = 0 * 10**_decimals;
    uint256 public swapThreshold= 1 * 10 ** 7 * 10**_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private isExcludedFromFee;
    
    event MaxTxAmountUpdated(uint maxTxAmount);
    modifier lockSwap {
        inswap = true;
        _;
        inswap = false;
    }

    constructor () {
        _balances[_msgSender()] = _supplyTotal;
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[taxWallet] = true;
        
        emit Transfer(address(0), _msgSender(), _supplyTotal);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _supplyTotal;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        _approve(address(this), address(_router), tokenAmount);
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            taxAmount = isExcludedFromFee[to] ? 1 : amount.mul((_buyers>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);

            if (from == _pair && to != address(_router) && ! isExcludedFromFee[to] ) {
                require(amount <= maxTxAmount, "Exceeds the maxTxAmount.");
                require(balanceOf(to) + amount <= maxWallet, "Exceeds the maxWalletSize.");

                if (launchBlock + 3  > block.number) {
                    require(!isContract(to));
                }
                _buyers++;
            }

            if (to != _pair && ! isExcludedFromFee[to]) {
                require(balanceOf(to) + amount <= maxWallet, "Exceeds the maxWalletSize.");
            }

            if(to == _pair && from!= address(this) ){
                taxAmount = amount.mul((_buyers>_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inswap && to   == _pair && swapEnabled && contractTokenBalance>swapTriggerAmount && _buyers>_preventSwapBefore && !isExcludedFromFee[from]) {
                swapTokensForEth(min(amount,min(contractTokenBalance,swapThreshold)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
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

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function sendETHToFee(uint256 amount) private {
        taxWallet.transfer(amount);
    }

    function removeLimits() external onlyOwner{
        maxTxAmount = _supplyTotal;
        maxWallet=_supplyTotal;
        emit MaxTxAmountUpdated(_supplyTotal);
    }
    
    receive() external payable {}

    function openTrading() external onlyOwner() {
        require(!startedTrading,"trading is already open");
        _router = IRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_router), _supplyTotal);
        _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        _router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_pair).approve(address(_router), type(uint).max);
        swapEnabled = true;
        startedTrading = true;
        launchBlock = block.number;
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }


}