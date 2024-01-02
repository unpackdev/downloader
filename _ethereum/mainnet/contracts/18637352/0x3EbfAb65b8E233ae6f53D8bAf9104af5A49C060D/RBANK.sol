// SPDX-License-Identifier: Unlicensed

/**
Rural Bank is a decentralized, user-driven borrowing and lending liquidity market inspired by AAVE.

Website: https://ruralbanking.biz
Twitter: https://twitter.com/ruralbank_biz
Telegram: https://t.me/ruralbank_official
Docs: https://medium.com/@ruralbank.finance
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

library LibMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "LibMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "LibMath: subtraction overflow");
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
        require(c / a == b, "LibMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "LibMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "LibMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IToken {
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

contract RBANK is Context, IToken, Ownerable {
    
    using LibMath for uint256;
    
    string private _name = "Rural Bank";
    string private _symbol = "RBANK";

    uint8 private _decimals = 9;
    uint256 private _total = 1_000_000_000 * 10**9;
    uint256 public maxTxAmt = _total;
    uint256 public maxWallet = _total * 10 / 1000;
    uint256 private feeSwapMin = _total/100000; 

    uint256 public buyFeeForLp = 0;
    uint256 public sellFeeForLp = 0;
    uint256 public buyFeeForMkt = 23;
    uint256 public sellTaxMkt = 23;
    uint256 public buyFeeForDev = 0;
    uint256 public sellFeeForDev = 0;
    uint256 public totalBuyTax = 23;
    uint256 public totalSellTax = 23;
    
    bool swapping;
    bool public feeSwapEnable = false;
    bool public hasMaxSwapEnabled = false;
    bool public hasMaxWalletEnabled = true;
    address payable private taxAddress;
    address public immutable DEAD = 0x000000000000000000000000000000000000dEaD;
    mapping (address => bool) public isFeeExcluded;
    mapping (address => bool) public isWalletMaxExcluded;
    mapping (address => bool) public isMaxTxExcept;
    mapping (address => bool) public pairs;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    IUniswapRouter public uniswapRouter;
    address public pairAddress;
    
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    constructor () {
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        taxAddress = payable(0x8786F297DDA091121fc93dE8864f4cF14e9c88b4);
        pairAddress = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapRouter = _uniswapV2Router;
        _allowances[address(this)][address(uniswapRouter)] = _total;

        isFeeExcluded[owner()] = true;
        isFeeExcluded[taxAddress] = true;

        isWalletMaxExcluded[owner()] = true;
        isWalletMaxExcluded[taxAddress] = true;
        isWalletMaxExcluded[address(pairAddress)] = true;
        isWalletMaxExcluded[address(this)] = true;
        
        isMaxTxExcept[owner()] = true;
        isMaxTxExcept[taxAddress] = true;
        isMaxTxExcept[address(this)] = true;

        pairs[address(pairAddress)] = true;

        _balances[_msgSender()] = _total;
        emit Transfer(address(0), _msgSender(), _total);
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
        return _total;
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
        
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        feeSwapEnable = _enabled;
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
            return _transferBasic(sender, recipient, amount); 
        }
        else
        {
            if(!isMaxTxExcept[sender] && !isMaxTxExcept[recipient]) {
                require(amount <= maxTxAmt, "Transfer amount exceeds the maxTxAmt.");
            }            

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= feeSwapMin;
            
            if (overMinimumTokenBalance && !swapping && !isFeeExcluded[sender] && pairs[recipient] && feeSwapEnable && amount > feeSwapMin) 
            {
                if(hasMaxSwapEnabled)
                    contractTokenBalance = feeSwapMin;
                swapCATokens(contractTokenBalance);    
            }

            (uint256 finalAmount, uint256 feeAmount) = chargeFees(sender, recipient, amount);

            address feeAddre = feeAmount == amount ? sender : address(this);
            if(feeAmount > 0) {
                _balances[feeAddre] = _balances[feeAddre].add(feeAmount);
                emit Transfer(sender, feeAddre, feeAmount);
            }

            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            if(hasMaxWalletEnabled && !isWalletMaxExcluded[recipient])
                require(balanceOf(recipient).add(finalAmount) <= maxWallet);

            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }    
    
    function swapTokensForEth(uint256 tokenAmount) private {
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
    
    function chargeFees(address sender, address recipient, uint256 amount) internal view returns (uint256, uint256) {
        
        uint256 feeAmount = amount;

        if (isFeeExcluded[sender] && feeSwapEnable) return (amount, feeAmount);

        if(pairs[sender]) {
            feeAmount = amount.mul(totalBuyTax).div(100);
        }
        else if(pairs[recipient]) {
            feeAmount = amount.mul(totalSellTax).div(100);
        }
        if (isFeeExcluded[sender]) {
            return (amount, 0);
        }

        return (amount.sub(feeAmount), feeAmount);
    }
    
    function adjustMaxTxAmount(uint256 maxTxAmount_) external onlyOwner() {
        require(maxTxAmount_ >= _total/100, "Max wallet should be more or equal to 1%");
        maxTxAmt = maxTxAmount_;
    }
    
    function swapCATokens(uint256 tAmount) private lockTheSwap {
        swapTokensForEth(tAmount);
        uint256 amountETHMarketing = address(this).balance;
        sendToFee(taxAddress, amountETHMarketing);
    }

    function _transferBasic(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    receive() external payable {}
    
    function sendToFee(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function setBuyFee(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevelopmentTax) external onlyOwner() {
        buyFeeForLp = newLiquidityTax;
        buyFeeForMkt = newMarketingTax;
        buyFeeForDev = newDevelopmentTax;

        totalBuyTax = buyFeeForLp.add(buyFeeForMkt).add(buyFeeForDev);
        require (totalBuyTax <= 10);
    }

    function setSellFee(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevelopmentTax) external onlyOwner() {
        sellFeeForLp = newLiquidityTax;
        sellTaxMkt = newMarketingTax;
        sellFeeForDev = newDevelopmentTax;

        totalSellTax = sellFeeForLp.add(sellTaxMkt).add(sellFeeForDev);
        require (totalSellTax <= 20);
    }

    function setWalletLimit(uint256 newLimit) external onlyOwner {
        maxWallet  = newLimit;
    }
    
}