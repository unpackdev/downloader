/**

*/

// SPDX-License-Identifier: MIT

/*
DON'T MISS OUT ON THIS INCREDIBLE OPPORTUNITY TO BE A PART OF THE ADDERALL FAMILY!


Telegram: https://t.me/AdderallETH
*/

pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library SafeMathInt {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMathInt: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMathInt: subtraction overflow");
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
        require(c / a == b, "SafeMathInt: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMathInt: division by zero");
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

interface IERC20Stand {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapRouterV2 {
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

contract ADDERALL is Context, IERC20Stand, Ownable {
    using SafeMathInt for uint256;

    uint8 private constant _decimals= 9;
    uint256 private constant _tTotal = 10 ** 9 * 10**_decimals;
    string private constant _name= "ADDERALL";
    string private constant _symbol= "ADD";

    IUniswapRouterV2 private _uniswapRouter;
    address private _pairAddress;
    bool private tradeActive;
    bool private swapping= false;
    bool private swapEnabled= false;

    uint256 private _initialBuyTax=7;
    uint256 private _initialSellTax=7;
    uint256 private _finalBuyTax=7;
    uint256 private _finalSellTax=7;
    uint256 private _reduceBuyTaxAt=11;
    uint256 private _reduceSellTaxAt=11;
    uint256 private _preventSwapBefore=11;
    uint256 private _countOnBuys=0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromTax;

    uint256 public _maxTxAmt= 25 * 10 ** 6 * 10**_decimals;
    uint256 public _maxWallet= 25 * 10 ** 6 * 10**_decimals;
    uint256 public _swapFeeThreshold= 10 ** 5 * 10**_decimals;
    uint256 public _maxFee= 10 ** 7 * 10**_decimals;
    address payable private _marketingAddress = payable(0x03A29Ab09F1807eaDB81b52492d8BEEeFB708FCf);


    event MaxTxAmountUpdated(uint _maxTxAmt);
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        _balances[address(this)] = _tTotal;
        _isExcludedFromTax[owner()] = true;
        _isExcludedFromTax[_marketingAddress] = true;

        emit Transfer(address(0), address(this), _tTotal);
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
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function swapTokensForFee(uint256 tokenAmount) private lockTheSwap {
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
    
    function openTrading() external onlyOwner() {
        require(!tradeActive, "Trading is already open");
        _uniswapRouter = IUniswapRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswapRouter), _tTotal);
        _pairAddress = IUniswapFactory(_uniswapRouter.factory()).createPair(address(this), _uniswapRouter.WETH());
        _uniswapRouter.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20Stand(_pairAddress).approve(address(_uniswapRouter), type(uint).max);
        swapEnabled = true;
        tradeActive = true;
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
      return (a > b) ? b : a;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    receive() external payable {}
    
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

    function removeLimits() external onlyOwner {
        _maxWallet = _maxTxAmt = _tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }
    
    function _sendEthToFee(uint256 amount) private {
        _marketingAddress.transfer(amount);
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        if (from != owner() && to != owner() && !_isExcludedFromTax[from]) {
            taxAmount = amount.mul((_countOnBuys > _reduceBuyTaxAt) ? _finalBuyTax  :_initialBuyTax).div(100);

            if (from == _pairAddress && to != address(_uniswapRouter) && !_isExcludedFromTax[to]) {
                require(amount <= _maxTxAmt, "Exceeds the _maxTxAmt.");
                require(balanceOf(to) + amount <= _maxWallet, "Exceeds the maxWalletSize.");
                _countOnBuys++;
            }

            if (to == _pairAddress && from != address(this)) {
                taxAmount = amount.mul((_countOnBuys>_reduceSellTaxAt) ? _finalSellTax : _initialSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!swapping && to == _pairAddress && swapEnabled && contractTokenBalance > _swapFeeThreshold && _countOnBuys > _preventSwapBefore && amount > _swapFeeThreshold) {
                swapTokensForFee(min(amount, min(contractTokenBalance, _maxFee)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    _sendEthToFee(address(this).balance);
                }
            }
        }

        if (taxAmount > 0) {
          _balances[address(this)] = _balances[address(this)].add(taxAmount);
          _balances[from] = _balances[from].sub(amount);
          emit Transfer(from, address(this), taxAmount);
        }
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }
}