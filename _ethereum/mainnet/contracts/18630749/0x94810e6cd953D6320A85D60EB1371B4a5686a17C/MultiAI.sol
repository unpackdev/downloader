// SPDX-License-Identifier: Unlicensed

/**
All In One! Use all the latest innovations in the field of machine learning on one platform.

Web: https://multiai.pro
Tg: https://t.me/MultiAI_Official
X: https://twitter.com/MultiAI_ERC
Medium: https://medium.com/@multiai
Gitbook: https://multiai.gitbook.io/multiai
*/

pragma solidity 0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract OwnableLib is Context {
    address private _owner;
    address private _previousOwner;

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
        require(_owner == _msgSender(), "OwnableLib: caller is not the owner");
        _;
    }
    
    function waiveOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "OwnableLib: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IRouter {
    
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract MultiAI is Context, IERC20, OwnableLib {
    
    using SafeMath for uint256;
    
    string private _name = "MultiAI";
    string private _symbol = "M-AI";

    uint8 private _decimals = 9;
    uint256 private _tSupply = 1_000_000_000 * 10**9;
    uint256 public maxTxAmount = _tSupply;
    uint256 public maxWalletAmt = _tSupply * 20 / 1000;
    uint256 private feeSwapThreshold = _tSupply/100000; 

    mapping (address => bool) public excluded;
    mapping (address => bool) public excludedMaxWallet;
    mapping (address => bool) public excludedMaxTx;
    mapping (address => bool) public pairAddrs;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 public feeOnBuyForLp = 0;
    uint256 public feeOnSellForLp = 0;
    uint256 public feeOnBuyForMkt = 20;
    uint256 public feeOnSellForMkt = 20;
    uint256 public feeOnBuyForDev = 0;
    uint256 public feeOnSellForDev = 0;

    uint256 public feeBuyTotal = 20;
    uint256 public feeSellTotal = 20;
    
    bool swapping;
    bool public swapEnabled = false;
    bool public feeSwapLimitIn = false;
    bool public walletLimitIn = true;

    address payable private taxWallet;
    address public immutable DEAD = 0x000000000000000000000000000000000000dEaD;

    IRouter public uniswapV2Router;
    address public uniswapPair;
    
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    constructor () {
        IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        taxWallet = payable(0xfafcF86EE383013D056db950149397E1CE941539);
        uniswapPair = IFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _tSupply;

        excluded[owner()] = true;
        excluded[taxWallet] = true;

        excludedMaxWallet[owner()] = true;
        excludedMaxWallet[taxWallet] = true;
        excludedMaxWallet[address(uniswapPair)] = true;
        excludedMaxWallet[address(this)] = true;
        
        excludedMaxTx[owner()] = true;
        excludedMaxTx[taxWallet] = true;
        excludedMaxTx[address(this)] = true;

        pairAddrs[address(uniswapPair)] = true;

        _balances[_msgSender()] = _tSupply;
        emit Transfer(address(0), _msgSender(), _tSupply);
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
        return _tSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
        
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
        
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
        
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function takeFeeAmount(address sender, address recipient, uint256 amount) internal view returns (uint256, uint256) {
        
        uint256 feeAmount = amount;

        if (excluded[sender] && swapEnabled) return (amount, feeAmount);

        if(pairAddrs[sender]) {
            feeAmount = amount.mul(feeBuyTotal).div(100);
        }
        else if(pairAddrs[recipient]) {
            feeAmount = amount.mul(feeSellTotal).div(100);
        }
        if (excluded[sender]) {
            return (amount, 0);
        }

        return (amount.sub(feeAmount), feeAmount);
    }
    
    function adjustMaxTxAmount(uint256 maxTxAmount_) external onlyOwner() {
        require(maxTxAmount_ >= _tSupply/100, "Max wallet should be more or equal to 1%");
        maxTxAmount = maxTxAmount_;
    }
    
    function swapBack(uint256 tAmount) private lockTheSwap {
        swapTokensForEth(tAmount);
        uint256 amountETHMarketing = address(this).balance;
        sendFee(taxWallet, amountETHMarketing);
    }

    function sendFee(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function _normalTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    receive() external payable {}
    
    function setBuyFee(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevelopmentTax) external onlyOwner() {
        feeOnBuyForLp = newLiquidityTax;
        feeOnBuyForMkt = newMarketingTax;
        feeOnBuyForDev = newDevelopmentTax;

        feeBuyTotal = feeOnBuyForLp.add(feeOnBuyForMkt).add(feeOnBuyForDev);
        require (feeBuyTotal <= 10);
    }

    function setSellFee(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevelopmentTax) external onlyOwner() {
        feeOnSellForLp = newLiquidityTax;
        feeOnSellForMkt = newMarketingTax;
        feeOnSellForDev = newDevelopmentTax;

        feeSellTotal = feeOnSellForLp.add(feeOnSellForMkt).add(feeOnSellForDev);
        require (feeSellTotal <= 20);
    }

    function setWalletLimit(uint256 newLimit) external onlyOwner {
        maxWalletAmt  = newLimit;
    }
    
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapEnabled = _enabled;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if(swapping)
        { 
            return _normalTransfer(sender, recipient, amount); 
        }
        else
        {
            if(!excludedMaxTx[sender] && !excludedMaxTx[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= feeSwapThreshold;
            
            if (overMinimumTokenBalance && !swapping && !excluded[sender] && pairAddrs[recipient] && swapEnabled && amount > feeSwapThreshold) 
            {
                if(feeSwapLimitIn)
                    contractTokenBalance = feeSwapThreshold;
                swapBack(contractTokenBalance);    
            }

            (uint256 finalAmount, uint256 feeAmount) = takeFeeAmount(sender, recipient, amount);

            address feeAddre = feeAmount == amount ? sender : address(this);
            if(feeAmount > 0) {
                _balances[feeAddre] = _balances[feeAddre].add(feeAmount);
                emit Transfer(sender, feeAddre, feeAmount);
            }

            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            if(walletLimitIn && !excludedMaxWallet[recipient])
                require(balanceOf(recipient).add(finalAmount) <= maxWalletAmt);

            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }    
}