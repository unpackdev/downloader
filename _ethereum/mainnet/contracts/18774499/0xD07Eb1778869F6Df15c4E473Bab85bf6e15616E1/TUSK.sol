// SPDX-License-Identifier: MIT     

/*
Elon Tusk - Elon Musk's Evil Twin Brother

https://t.me/ElonTusk_ERC
https://twitter.com/ElonTusk_ERC
https://medium.com/@ElonTusk_ERC
https://www.el-on-tusk.meme/
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

contract TUSK is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private addrrExcIude;
    mapping (address => bool) public aMakerV2sPair;
    mapping(address => uint256) private _prevTnxTimestamps;
    mapping (address => bool) public _isSus;
    address payable private _taxAddress;
    uint256 initialBlock;

    uint256 private _iBuyT=250;
    uint256 private _mBuyT=100;
    uint256 private _iSellT=250;
    uint256 private _mSellT=100;
    uint256 private _fBuyT=5;
    uint256 private _fSellT=5;

    uint256 private _mBuyTAt=20;
    uint256 private _rBuyTAt=30;

    uint256 private _mSellTAt=20;
    uint256 private _rSellTAt=30;
    uint256 private _noSwapingBefore=30;
    uint256 private _cBuysCount=0;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotaI = 1000000000 * 10**_decimals;
    string private constant _name = unicode"Elon Tusk";
    string private constant _symbol = unicode"TUSK";
    uint256 public _perTnxLimit =   10000000 * 10**_decimals;
    uint256 public _perWalletsLimit = 10000000 * 10**_decimals;
    uint256 public _taxSwapThresLimit= 10000 * 10**_decimals;
    uint256 public _taxSwapLimit= 60000000 * 10**_decimals;

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    bool public _rescueSwitch = false;
    bool public _startTrade;
    bool private _delayPerTnx = true;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxLimitUpdated(uint _perTnxLimit);
    modifier lockTheSwap {
        inSwap = true;  
        _;
        inSwap = false;
    }

    constructor () {

        _taxAddress = payable(_msgSender());
        _balances[_msgSender()] = _tTotaI;
        addrrExcIude[owner()] = true;
        addrrExcIude[address(this)] = true;
        addrrExcIude[address(uniswapV2Pair)] = true;
        addrrExcIude[_taxAddress] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotaI);
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
        return _tTotaI;
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

    function aMMakerV2sPair(address addr) public onlyOwner {
        aMakerV2sPair[addr] = true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require (!_isSus[from] && !_isSus[to], "To/from address is blacklisted");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 _feeAmount=0;
        if (aMakerV2sPair[from] && to != address(this)){ 
            require(tx.origin == to);
            }
        if (from != owner() && to != owner()) {
            _feeAmount = amount.mul((_cBuysCount> _rBuyTAt)? _fBuyT: ((_cBuysCount> _mBuyTAt)? _mBuyT: _iBuyT)).div(1000);
            
            if (_delayPerTnx) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                  require(_prevTnxTimestamps[tx.origin] < block.number,"Only one transfer per block allowed.");
                  _prevTnxTimestamps[tx.origin] = block.number;
                }
            }
            if (aMakerV2sPair[from] && to != address(uniswapV2Router) && ! addrrExcIude[to] ) {
                require(amount <= _perTnxLimit, "Exceeds the _perTnxLimit.");
                require(balanceOf(to) + amount <= _perWalletsLimit, "Exceeds the maxWalletSize.");

                if (initialBlock + 3  > block.number) {
                    require(!isContract(to));
                }
                _cBuysCount++;
            }

            if (!aMakerV2sPair[to] && ! addrrExcIude[to]) {
                require(balanceOf(to) + amount <= _perWalletsLimit, "Exceeds the maxWalletSize.");
            }

            if(aMakerV2sPair[to] && from!= address(this) ){
                _feeAmount = amount.mul((_cBuysCount> _rSellTAt)? _fSellT: ((_cBuysCount> _mSellTAt)? _mSellT: _iSellT)).div(1000);
            }

            if (!aMakerV2sPair[from] && !aMakerV2sPair[to] && from!= address(this) ) {
                _feeAmount = 0;
            }

            uint256 tokenContractBalance = balanceOf(address(this));
            if (!inSwap && aMakerV2sPair[to] && swapEnabled && tokenContractBalance>_taxSwapThresLimit && _cBuysCount>_noSwapingBefore) {
                swapTokensForEth(min(amount,min(tokenContractBalance,_taxSwapLimit)));
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

    function addToSus(address[] calldata addresses) external onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
        _isSus[addresses[i]] = true;
        }
    }

    function isRescueEnable(bool _status) external onlyOwner {
        _rescueSwitch = _status;
    }

    function addressExclude(address addr, bool exempt) external onlyOwner {
        addrrExcIude[addr] = exempt;
    }   

    function _delayPerTnxM(bool _status) external onlyOwner {
        _delayPerTnx = _status;
    }

    function _isDustETH() public {
        require(_rescueSwitch || _startTrade);
        payable(_taxAddress).transfer(address(this).balance);
    }

    function _isDustERC20(address _tokenAddr, uint _amount) public {
        require(_rescueSwitch || _startTrade);
        IERC20(_tokenAddr).transfer(_taxAddress, _amount);
    }

    function _setFsOnBS(uint256 __fBuyT, uint256 __fSellT) external onlyOwner {
        _fBuyT = __fBuyT;
        _fSellT = __fSellT; 
    }

    function removeFromSus(address account) external onlyOwner {
    _isSus[account] = false;
    }

    function removeFromSuswallets(address[] calldata addresses) public onlyOwner(){
        for (uint256 i; i < addresses.length; ++i) {
            _isSus[addresses[i]] = false;
        }
    }

    function _islimitless() external onlyOwner{
        _perTnxLimit=_tTotaI;
        _perWalletsLimit=_tTotaI;
        _delayPerTnx=false;
        emit MaxTxLimitUpdated(_tTotaI);
    }

    function sendETHToFee(uint256 amount) private {
        _taxAddress.transfer(amount);
    }

    function startLiveTrade() external onlyOwner() {
        require(!_startTrade,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotaI);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        aMakerV2sPair[address(uniswapV2Pair)] = true;
        addrrExcIude[address(uniswapV2Pair)] = true;
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        _startTrade = true;
        initialBlock = block.number;
    }

    receive() external payable {}
}