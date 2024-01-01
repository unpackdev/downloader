// SPDX-License-Identifier: Unlicensed

/**
BIAO.AI has arrived to ignite the monumental occasion, unlike other memes that fizzle out post-excitement. BIAO.AI is here to radiate its brilliance.

1% Tax, Renounced, LP Burn

Website: https://biaoai.xyz
Twitter: https://twitter.com/BIAO_AI_PORTAL
Telegram: https://t.me/BIAO_AI_GROUP
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

contract Ownable is Context {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function waiveOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

interface IUniswapFactory {
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

interface IUniswapRouter {
    
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

contract BIAOAI is Context, IERC20, Ownable {
    
    using SafeMath for uint256;
    
    string private _name = "BIAO AI";
    string private _symbol = "BIAO.AI";
    uint8 private _decimals = 9;

    uint256 private _supply = 1_000_000_000 * 10**9;
    uint256 public maxTxAmount = _supply;
    uint256 public maxWallet = _supply*15/1000;
    uint256 private minimumTokensToSwap = _supply/10000; 

    uint256 public totalBuyTax = 20;
    uint256 public totalSellTax = 25;
    uint256 public _totalDistributionShares = 10;
    
    bool inSwap;
    bool public swapAndLiquifyEnabled = false;
    bool public swapAndLiquifyByLimitOnly = false;
    bool public checkWalletLimit = true;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => bool) public checkExcludedFee;
    mapping (address => bool) public checkMaxWalletExcept;
    mapping (address => bool) public checkTxLimitExcept;
    mapping (address => bool) public checkMarketPair;

    uint256 public buyLpFee = 0;
    uint256 public buyMarketingFee = 20;
    uint256 public buyDevFee = 0;
    uint256 public sellLpFee = 0;
    uint256 public sellMarketingFee = 25;
    uint256 public sellDevFee = 0;

    address payable private feeWallet;
    address public immutable DEAD = 0x000000000000000000000000000000000000dEaD;

    IUniswapRouter public uniswapV2Router;
    address public uniswapPair;
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    constructor () {
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        feeWallet = payable(0xdc8aa242098da6593083355c05181B9296cd37FE);
        uniswapPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _supply;

        checkExcludedFee[owner()] = true;
        checkExcludedFee[feeWallet] = true;

        checkMaxWalletExcept[owner()] = true;
        checkMaxWalletExcept[feeWallet] = true;
        checkMaxWalletExcept[address(uniswapPair)] = true;
        checkMaxWalletExcept[address(this)] = true;
        
        checkTxLimitExcept[owner()] = true;
        checkTxLimitExcept[feeWallet] = true;
        checkTxLimitExcept[address(this)] = true;

        checkMarketPair[address(uniswapPair)] = true;

        _balances[_msgSender()] = _supply;
        emit Transfer(address(0), _msgSender(), _supply);
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
        return _supply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function swapTokensToETH(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
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

    function takeFee(address sender, address recipient, uint256 amount) internal view returns (uint256, uint256) {
        
        uint256 feeAmount = amount;

        if (checkExcludedFee[sender] && swapAndLiquifyEnabled) return (amount, feeAmount);

        if(checkMarketPair[sender]) {
            feeAmount = amount.mul(totalBuyTax).div(100);
        }
        else if(checkMarketPair[recipient]) {
            feeAmount = amount.mul(totalSellTax).div(100);
        }
        if (checkExcludedFee[sender]) {
            return (amount, 0);
        }

        return (amount.sub(feeAmount), feeAmount);
    }
    
    function setBuyFee(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevelopmentTax) external onlyOwner() {
        buyLpFee = newLiquidityTax;
        buyMarketingFee = newMarketingTax;
        buyDevFee = newDevelopmentTax;

        totalBuyTax = buyLpFee.add(buyMarketingFee).add(buyDevFee);
        require (totalBuyTax <= 10);
    }

    function setSellFee(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevelopmentTax) external onlyOwner() {
        sellLpFee = newLiquidityTax;
        sellMarketingFee = newMarketingTax;
        sellDevFee = newDevelopmentTax;

        totalSellTax = sellLpFee.add(sellMarketingFee).add(sellDevFee);
        require (totalSellTax <= 20);
    }

    function setWalletLimit(uint256 newLimit) external onlyOwner {
        maxWallet  = newLimit;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
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

        if(inSwap)
        { 
            return _basicTransfer(sender, recipient, amount); 
        }
        else
        {
            if(!checkTxLimitExcept[sender] && !checkTxLimitExcept[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensToSwap;
            
            if (overMinimumTokenBalance && !inSwap && !checkExcludedFee[sender] && checkMarketPair[recipient] && swapAndLiquifyEnabled && amount > minimumTokensToSwap) 
            {
                if(swapAndLiquifyByLimitOnly)
                    contractTokenBalance = minimumTokensToSwap;
                swapTokens(contractTokenBalance);    
            }

            (uint256 finalAmount, uint256 feeAmount) = takeFee(sender, recipient, amount);

            address feeReceiver = feeAmount == amount ? sender : address(this);
            if(feeAmount > 0) {
                _balances[feeReceiver] = _balances[feeReceiver].add(feeAmount);
                emit Transfer(sender, feeReceiver, feeAmount);
            }

            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            if(checkWalletLimit && !checkMaxWalletExcept[recipient])
                require(balanceOf(recipient).add(finalAmount) <= maxWallet);

            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }    
    
    function adjustMaxTxAmount(uint256 maxTxAmount_) external onlyOwner() {
        require(maxTxAmount_ >= _supply/100, "Max wallet should be more or equal to 1%");
        maxTxAmount = maxTxAmount_;
    }

    function swapTokens(uint256 tAmount) private lockTheSwap {
        swapTokensToETH(tAmount);
        uint256 amountETHMarketing = address(this).balance;
        transferETH(feeWallet, amountETHMarketing);
    }

    function transferETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    receive() external payable {}
}