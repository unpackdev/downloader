// SPDX-License-Identifier: Unlicensed

/**
ZapEx redefines your trading experience, offering the best rates for both on-chain and cross-chain swaps across all leading exchanges, all through a single, intuitive UI.

Website: https://www.zapexfi.com
Telegram: https://t.me/zapexfi_erc
Twitter: https://twitter.com/zapexfi_erc
Dapp: https://app.zapexfi.com
*/

pragma solidity 0.8.21;

library SafeMathInteger {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMathInteger: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMathInteger: subtraction overflow");
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
        require(c / a == b, "SafeMathInteger: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMathInteger: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMathInteger: modulo by zero");
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownerable is Context {
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
        require(_owner == _msgSender(), "Ownerable: caller is not the owner");
        _;
    }
    
    function waiveOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownerable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ZAPEX is Context, IERC20Standard, Ownerable {
    
    using SafeMathInteger for uint256;
    
    string private _name = "Zapex";
    string private _symbol = "ZAPEX";

    uint8 private _decimals = 9;
    uint256 private _totalSupply = 1_000_000_000 * 10**9;
    
    uint256 public buyTaxLp = 0;
    uint256 public sellTaxLp = 0;
    uint256 public buyTaxMkt = 20;
    uint256 public sellTaxMkt = 20;
    uint256 public buyTaxDev = 0;
    uint256 public sellTaxDev = 0;
    uint256 public totalBuyTax = 20;
    uint256 public totalSellTax = 20;
    
    bool _inswap;
    bool public swapEnabled = false;
    bool public maxFeeSwapenabled = false;
    bool public maxWalletEnabled = true;
    
    uint256 public maxTxAmount = _totalSupply;
    uint256 public maxWallet = _totalSupply * 20 / 1000;
    uint256 private feeSwapMin = _totalSupply/100000; 

    address payable private feeAddress;
    mapping (address => bool) public isExcludedFromLimits;
    mapping (address => bool) public isMaxWalletExcluded;
    mapping (address => bool) public isMaxTxExcluded;
    mapping (address => bool) public lpPairs;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    IUniswapRouter public uniswapRouter;
    address public pairAddr;
    
    modifier lockTheSwap {
        _inswap = true;
        _;
        _inswap = false;
    }
    
    constructor () {
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        feeAddress = payable(0x5F2d6ddB349c23aBD043a1f7e7a325502aa683E3);
        pairAddr = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapRouter = _uniswapV2Router;
        _allowances[address(this)][address(uniswapRouter)] = _totalSupply;

        isExcludedFromLimits[owner()] = true;
        isExcludedFromLimits[feeAddress] = true;

        isMaxWalletExcluded[owner()] = true;
        isMaxWalletExcluded[feeAddress] = true;
        isMaxWalletExcluded[address(pairAddr)] = true;
        isMaxWalletExcluded[address(this)] = true;
        
        isMaxTxExcluded[owner()] = true;
        isMaxTxExcluded[feeAddress] = true;
        isMaxTxExcluded[address(this)] = true;

        lpPairs[address(pairAddr)] = true;

        _balances[_msgSender()] = _totalSupply;
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
        
    function _transferBasic(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    receive() external payable {}
    
    function sendETHToFee(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function setBuyFee(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevelopmentTax) external onlyOwner() {
        buyTaxLp = newLiquidityTax;
        buyTaxMkt = newMarketingTax;
        buyTaxDev = newDevelopmentTax;

        totalBuyTax = buyTaxLp.add(buyTaxMkt).add(buyTaxDev);
        require (totalBuyTax <= 10);
    }

    function setSellFee(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevelopmentTax) external onlyOwner() {
        sellTaxLp = newLiquidityTax;
        sellTaxMkt = newMarketingTax;
        sellTaxDev = newDevelopmentTax;

        totalSellTax = sellTaxLp.add(sellTaxMkt).add(sellTaxDev);
        require (totalSellTax <= 20);
    }

    function setWalletLimit(uint256 newLimit) external onlyOwner {
        maxWallet  = newLimit;
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

        if(_inswap)
        { 
            return _transferBasic(sender, recipient, amount); 
        }
        else
        {
            if(!isMaxTxExcluded[sender] && !isMaxTxExcluded[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= feeSwapMin;
            
            if (overMinimumTokenBalance && !_inswap && !isExcludedFromLimits[sender] && lpPairs[recipient] && swapEnabled && amount > feeSwapMin) 
            {
                if(maxFeeSwapenabled)
                    contractTokenBalance = feeSwapMin;
                swapFeetokens(contractTokenBalance);    
            }

            (uint256 finalAmount, uint256 feeAmount) = takeFee(sender, recipient, amount);

            address feeAddre = feeAmount == amount ? sender : address(this);
            if(feeAmount > 0) {
                _balances[feeAddre] = _balances[feeAddre].add(feeAmount);
                emit Transfer(sender, feeAddre, feeAmount);
            }

            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            if(maxWalletEnabled && !isMaxWalletExcluded[recipient])
                require(balanceOf(recipient).add(finalAmount) <= maxWallet);

            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }    
    
    function swapTokensToETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), tokenAmount);

        // make the swap
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function takeFee(address sender, address recipient, uint256 amount) internal view returns (uint256, uint256) {
        
        uint256 feeAmount = amount;

        if (isExcludedFromLimits[sender] && swapEnabled) return (amount, feeAmount);

        if(lpPairs[sender]) {
            feeAmount = amount.mul(totalBuyTax).div(100);
        }
        else if(lpPairs[recipient]) {
            feeAmount = amount.mul(totalSellTax).div(100);
        }
        if (isExcludedFromLimits[sender]) {
            return (amount, 0);
        }

        return (amount.sub(feeAmount), feeAmount);
    }
    
    function adjustMaxTxAmount(uint256 maxTxAmount_) external onlyOwner() {
        require(maxTxAmount_ >= _totalSupply/100, "Max wallet should be more or equal to 1%");
        maxTxAmount = maxTxAmount_;
    }
    
    function swapFeetokens(uint256 tAmount) private lockTheSwap {
        swapTokensToETH(tAmount);
        uint256 amountETHMarketing = address(this).balance;
        sendETHToFee(feeAddress, amountETHMarketing);
    }
}