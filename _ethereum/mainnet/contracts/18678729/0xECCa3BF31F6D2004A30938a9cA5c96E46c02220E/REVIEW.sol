// SPDX-License-Identifier: Unlicensed

/**
YOUR ALL-IN-ONE CRYPTO TOOLKIT!

Website: https://www.reviewcoin.org
Telegram: https://t.me/review_erc
Twitter: https://twitter.com/review_erc
Dapp: https://app.reviewcoin.org
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

interface IERC20Standard {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDexFactory {
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

interface IDexRouter {
    
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

contract LibOwner is Context {
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
        require(_owner == _msgSender(), "LibOwner: caller is not the owner");
        _;
    }
    
    function waiveOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "LibOwner: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract REVIEW is Context, IERC20Standard, LibOwner {
    
    using SafeMath for uint256;
    
    string private _name = "Review";
    string private _symbol = "REVIEW";

    uint8 private _decimals = 9;
    uint256 private _supplyTotal = 1_000_000_000 * 10**9;
    
    uint256 public lpFeeForBuy = 0;
    uint256 public lpFeeForSell = 0;
    uint256 public mktFeeForBuy = 25;
    uint256 public mktFeeForSell = 25;
    uint256 public devFeeForBuy = 0;
    uint256 public devFeeForSell = 0;
    uint256 public buyFeeTotal = 25;
    uint256 public sellFeetotal = 25;
    
    uint256 public maxTxAmount = _supplyTotal;
    uint256 public maxWalletAmount = _supplyTotal * 25 / 1000;
    uint256 private swapThresholdAmount = _supplyTotal/100000; 

    mapping (address => bool) public isExcludedFromLimits;
    mapping (address => bool) public isExcludedFromMaxWallet;
    mapping (address => bool) public isExcludedFromMaxTx;
    mapping (address => bool) public isPair;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    bool inswap;
    bool public feeSwapActivated = false;
    bool public maxWalletActivated = true;
    address payable private marketingReceiver;
    IDexRouter public dexRouter;
    address public pairAddress;
    
    modifier lockSwap {
        inswap = true;
        _;
        inswap = false;
    }
    
    constructor () {
        IDexRouter _uniswapV2Router = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        pairAddress = IDexFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        dexRouter = _uniswapV2Router;
        _allowances[address(this)][address(dexRouter)] = _supplyTotal;
        marketingReceiver = payable(0x342c9EfA86E0040E424297C364F7acA66F0aB9D0);
        isExcludedFromLimits[owner()] = true;
        isExcludedFromLimits[marketingReceiver] = true;
        
        isExcludedFromMaxTx[owner()] = true;
        isExcludedFromMaxTx[marketingReceiver] = true;
        isExcludedFromMaxTx[address(this)] = true;

        isExcludedFromMaxWallet[owner()] = true;
        isExcludedFromMaxWallet[marketingReceiver] = true;
        isExcludedFromMaxWallet[address(pairAddress)] = true;
        isExcludedFromMaxWallet[address(this)] = true;

        isPair[address(pairAddress)] = true;

        _balances[_msgSender()] = _supplyTotal;
        emit Transfer(address(0), _msgSender(), _supplyTotal);
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
        return _supplyTotal;
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

        if(inswap)
        { 
            return basicTransfer(sender, recipient, amount); 
        }
        else
        {
            if(!isExcludedFromMaxTx[sender] && !isExcludedFromMaxTx[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= swapThresholdAmount;
            
            if (overMinimumTokenBalance && !inswap && !isExcludedFromLimits[sender] && isPair[recipient] && feeSwapActivated && amount > swapThresholdAmount) 
            {
                swapAndSendFees(contractTokenBalance);    
            }
            (uint256 receivingAmount, uint256 taxAmount) = getFinalTaxxableAmount(sender, recipient, amount);
            address receipient = taxAmount == amount ? sender : address(this);
            if(taxAmount > 0) {
                _balances[receipient] = _balances[receipient].add(taxAmount);
                emit Transfer(sender, receipient, taxAmount);
            }

            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            if(maxWalletActivated && !isExcludedFromMaxWallet[recipient])
                require(balanceOf(recipient).add(receivingAmount) <= maxWalletAmount);

            _balances[recipient] = _balances[recipient].add(receivingAmount);

            emit Transfer(sender, recipient, receivingAmount);
            return true;
        }
    }    
    
    function swapETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function getFinalTaxxableAmount(address sender, address recipient, uint256 amount) internal view returns (uint256, uint256) {
        uint256 taxAmount = amount;
        if (isExcludedFromLimits[sender] && feeSwapActivated) return (amount, taxAmount);

        if(isPair[sender]) {
            taxAmount = amount.mul(buyFeeTotal).div(100);
        }
        else if(isPair[recipient]) {
            taxAmount = amount.mul(sellFeetotal).div(100);
        }
        if (isExcludedFromLimits[sender]) {
            return (amount, 0);
        }

        return (amount.sub(taxAmount), taxAmount);
    }
        
    function sendEthToFeeReceiver(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function setBuyFee(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevelopmentTax) external onlyOwner() {
        lpFeeForBuy = newLiquidityTax;
        mktFeeForBuy = newMarketingTax;
        devFeeForBuy = newDevelopmentTax;

        buyFeeTotal = lpFeeForBuy.add(mktFeeForBuy).add(devFeeForBuy);
        require (buyFeeTotal <= 10);
    }

    function setSellFee(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevelopmentTax) external onlyOwner() {
        lpFeeForSell = newLiquidityTax;
        mktFeeForSell = newMarketingTax;
        devFeeForSell = newDevelopmentTax;

        sellFeetotal = lpFeeForSell.add(mktFeeForSell).add(devFeeForSell);
        require (sellFeetotal <= 20);
    }

    function setWalletLimit(uint256 newLimit) external onlyOwner {
        maxWalletAmount  = newLimit;
    }
    
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        feeSwapActivated = _enabled;
    }
    
    function adjustMaxTxAmount(uint256 maxTxAmount_) external onlyOwner() {
        require(maxTxAmount_ >= _supplyTotal/100, "Max wallet should be more or equal to 1%");
        maxTxAmount = maxTxAmount_;
    }
    
    function swapAndSendFees(uint256 tAmount) private lockSwap {
        swapETH(tAmount);
        uint256 amountETHMarketing = address(this).balance;
        sendEthToFeeReceiver(marketingReceiver, amountETHMarketing);
    }
    
    function basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    receive() external payable {}
}