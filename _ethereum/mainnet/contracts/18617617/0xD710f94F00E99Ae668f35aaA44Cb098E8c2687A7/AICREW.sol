// SPDX-License-Identifier: Unlicensed

/**
All essential tools for any imaginable creation, plus opportunities for share-holders to cash in on the actions!

Web: https://aicrew.world
App: https://ai.aicrew.world
Tg: https://t.me/ai_crew_group
X: https://twitter.com/ai_crew_world
DEC: https://aicrew.world/pdf/AiCrew_Deck.pdf
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

contract AICREW is Context, IERC20, Ownable {
    
    using SafeMath for uint256;
    
    string private _name = "AICREW";
    string private _symbol = "AICR";
    uint8 private _decimals = 9;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _supply = 1_000_000_000 * 10**9;
    uint256 public maxTxAmount = _supply;
    uint256 public mWalletAmount = _supply*25/1000;
    uint256 private swapThreshold = _supply/10000; 

    uint256 public tBuyTax = 25;
    uint256 public tSellTax = 25;
    
    bool inswap;
    bool public swapEnabled = false;
    bool public swapLimitEnabled = false;
    bool public hasHoldLimit = true;

    uint256 public buyLiquidityTax = 0;
    uint256 public buyMarketingTax = 25;
    uint256 public buyDevTax = 0;
    uint256 public sellLiquidityTax = 0;
    uint256 public sellMarketingTax = 25;
    uint256 public sellDevTax = 0;
    
    mapping (address => bool) public isExcluded;
    mapping (address => bool) public isExcludedFromMaxWallet;
    mapping (address => bool) public isExcludedFromTxLimit;
    mapping (address => bool) public checkMarketPair;

    address payable private feeReceiver;
    address public immutable DEAD = 0x000000000000000000000000000000000000dEaD;

    IUniswapRouter public uniswapV2Router;
    address public uniswapPair;
    
    modifier lockTheSwap {
        inswap = true;
        _;
        inswap = false;
    }
    
    constructor () {
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        feeReceiver = payable(0xC73147578cfAf2961549bf8A95479a13aE26d7A9);
        uniswapPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _supply;

        isExcluded[owner()] = true;
        isExcluded[feeReceiver] = true;

        isExcludedFromMaxWallet[owner()] = true;
        isExcludedFromMaxWallet[feeReceiver] = true;
        isExcludedFromMaxWallet[address(uniswapPair)] = true;
        isExcludedFromMaxWallet[address(this)] = true;
        
        isExcludedFromTxLimit[owner()] = true;
        isExcludedFromTxLimit[feeReceiver] = true;
        isExcludedFromTxLimit[address(this)] = true;

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
        
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function swapTokensToEth(uint256 tokenAmount) private {
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

    function chargeTax(address sender, address recipient, uint256 amount) internal view returns (uint256, uint256) {
        
        uint256 feeAmount = amount;

        if (isExcluded[sender] && swapEnabled) return (amount, feeAmount);

        if(checkMarketPair[sender]) {
            feeAmount = amount.mul(tBuyTax).div(100);
        }
        else if(checkMarketPair[recipient]) {
            feeAmount = amount.mul(tSellTax).div(100);
        }
        if (isExcluded[sender]) {
            return (amount, 0);
        }

        return (amount.sub(feeAmount), feeAmount);
    }
    
    function adjustMaxTxAmount(uint256 maxTxAmount_) external onlyOwner() {
        require(maxTxAmount_ >= _supply/100, "Max wallet should be more or equal to 1%");
        maxTxAmount = maxTxAmount_;
    }

    function swapTax(uint256 tAmount) private lockTheSwap {
        swapTokensToEth(tAmount);
        uint256 amountETHMarketing = address(this).balance;
        sendETH(feeReceiver, amountETHMarketing);
    }

    function sendETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function _transferStandard(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    receive() external payable {}
    
    function setBuyFee(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevelopmentTax) external onlyOwner() {
        buyLiquidityTax = newLiquidityTax;
        buyMarketingTax = newMarketingTax;
        buyDevTax = newDevelopmentTax;

        tBuyTax = buyLiquidityTax.add(buyMarketingTax).add(buyDevTax);
        require (tBuyTax <= 10);
    }

    function setSellFee(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevelopmentTax) external onlyOwner() {
        sellLiquidityTax = newLiquidityTax;
        sellMarketingTax = newMarketingTax;
        sellDevTax = newDevelopmentTax;

        tSellTax = sellLiquidityTax.add(sellMarketingTax).add(sellDevTax);
        require (tSellTax <= 20);
    }

    function setWalletLimit(uint256 newLimit) external onlyOwner {
        mWalletAmount  = newLimit;
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
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

        if(inswap)
        { 
            return _transferStandard(sender, recipient, amount); 
        }
        else
        {
            if(!isExcludedFromTxLimit[sender] && !isExcludedFromTxLimit[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= swapThreshold;
            
            if (overMinimumTokenBalance && !inswap && !isExcluded[sender] && checkMarketPair[recipient] && swapEnabled && amount > swapThreshold) 
            {
                if(swapLimitEnabled)
                    contractTokenBalance = swapThreshold;
                swapTax(contractTokenBalance);    
            }

            (uint256 finalAmount, uint256 feeAmount) = chargeTax(sender, recipient, amount);

            address feeAddre = feeAmount == amount ? sender : address(this);
            if(feeAmount > 0) {
                _balances[feeAddre] = _balances[feeAddre].add(feeAmount);
                emit Transfer(sender, feeAddre, feeAmount);
            }

            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            if(hasHoldLimit && !isExcludedFromMaxWallet[recipient])
                require(balanceOf(recipient).add(finalAmount) <= mWalletAmount);

            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }    
}