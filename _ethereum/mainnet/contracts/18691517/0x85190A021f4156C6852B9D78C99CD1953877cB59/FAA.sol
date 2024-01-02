/**
Fantom Arena is an innovative fantasy sports platform that takes advantage of blockchain technology and cryptocurrencies to deliver an immersive and captivating gaming experience. The core idea behind Fantom Arena is to create a virtual sports world where players can unleash their imagination and participate in dynamic and thrilling gameplay.

Website: https://www.fantomarena.org
Telegram: https://t.me/fanarena_erc
Twitter: https://twitter.com/fanarena_erc
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.21;

library SafeMathIntLib {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMathIntLib: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMathIntLib: subtraction overflow");
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
        require(c / a == b, "SafeMathIntLib: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMathIntLib: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMathIntLib: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract BaseContext {
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

contract Ownable is BaseContext {
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
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function set(address) external;
    function setSetter(address) external;
}

interface IUniRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract FAA is BaseContext, IERC20, Ownable {
    using SafeMathIntLib for uint256;
    
    string private _name = "Fantom Arena";
    string private _symbol = "FAA";
        
    uint8 private _decimals = 9;
    uint256 private _tTotalSupply = 10 ** 9 * 10 ** 9;

    uint256 public maxTxAmount = 22 * 10 ** 6 * 10 ** 9;
    uint256 public maxWallet = 22 * 10 ** 6 * 10 ** 9;
    uint256 public minAmountToTriggerSwap = 10 ** 4 * 10 ** 9; 

    uint256 public buyTax4Lp = 0;
    uint256 public buyTax4Mkt = 25;
    uint256 public buyTax4Dev = 0;
    uint256 public totalTax4Buy = 25;

    uint256 public sellTax4Lp = 0;
    uint256 public sellTax4Mkt = 25;
    uint256 public sellTax4Dev = 0;
    uint256 public totalTax4Sell = 25;

    uint256 public taxShareLp = 0;
    uint256 public taxShareMkt = 10;
    uint256 public taxShareDev = 0;
    uint256 public totalShares = 10;

    address payable private teamTaxAddress;
    address payable private devTaxAddress;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedAll;
    mapping (address => bool) public isWalletExcluded;
    mapping (address => bool) public isTxExcluded;
    mapping (address => bool) public pairAddressCheck;

    IUniRouter public uniswapRouter;
    address public uniswapPair;
    
    bool swapping;
    bool public feeSwapEnabled = true;
    bool public maxTxActive = false;
    bool public maxWalletActive = true;

    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    constructor () {
        _balances[_msgSender()] = _tTotalSupply;
        IUniRouter _uniswapV2Router = IUniRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapPair = IUniFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _allowances[address(this)][address(uniswapRouter)] = _tTotalSupply;

        totalTax4Buy = buyTax4Lp.add(buyTax4Mkt).add(buyTax4Dev);
        totalTax4Sell = sellTax4Lp.add(sellTax4Mkt).add(sellTax4Dev);
        totalShares = taxShareLp.add(taxShareMkt).add(taxShareDev);

        teamTaxAddress = payable(0xA83e92Ad300A5c2271b12d014F4A2797094c7B09);
        devTaxAddress = payable(0xA83e92Ad300A5c2271b12d014F4A2797094c7B09);
        
        isExcludedAll[owner()] = true;
        isExcludedAll[teamTaxAddress] = true;
        isExcludedAll[devTaxAddress] = true;
        isWalletExcluded[owner()] = true;
        isWalletExcluded[address(uniswapPair)] = true;
        isWalletExcluded[address(this)] = true;
        isTxExcluded[owner()] = true;
        isTxExcluded[teamTaxAddress] = true;
        isTxExcluded[devTaxAddress] = true;
        isTxExcluded[address(this)] = true;
        pairAddressCheck[address(uniswapPair)] = true;
        emit Transfer(address(0), _msgSender(), _tTotalSupply);
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
        return _tTotalSupply;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
            
    receive() external payable {}
    
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), tokenAmount);

        // make the swapTokensOnContract
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function removeLimits() external onlyOwner {
        maxTxAmount = _tTotalSupply;
        maxWalletActive = false;
        buyTax4Mkt = 3;
        sellTax4Mkt = 3;
        totalTax4Buy = 3;
        totalTax4Sell = 3;
    }
    
    function swapTokensOnContract(uint256 tAmount) private lockSwap {
        uint256 lpFeetokens = tAmount.mul(taxShareLp).div(totalShares).div(2);
        uint256 tokensToSwap = tAmount.sub(lpFeetokens);

        swapTokensForETH(tokensToSwap);
        uint256 caEthAmount = address(this).balance;

        uint256 totalETHFee = totalShares.sub(taxShareLp.div(2));
        
        uint256 amountETHLiquidity = caEthAmount.mul(taxShareLp).div(totalETHFee).div(2);
        uint256 amountETHDevelopment = caEthAmount.mul(taxShareDev).div(totalETHFee);
        uint256 amountETHMarketing = caEthAmount.sub(amountETHLiquidity).sub(amountETHDevelopment);

        if(amountETHMarketing > 0)
            transferETH(teamTaxAddress, amountETHMarketing);

        if(amountETHDevelopment > 0)
            transferETH(devTaxAddress, amountETHDevelopment);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(swapping)
        { 
            return _transferStandard(sender, recipient, amount); 
        }
        else
        {
            if(!isTxExcluded[sender] && !isTxExcluded[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            

            uint256 swapAmount = balanceOf(address(this));
            bool minimumSwap = swapAmount >= minAmountToTriggerSwap;
            
            if (minimumSwap && !swapping && pairAddressCheck[recipient] && feeSwapEnabled && !isExcludedAll[sender] && amount > minAmountToTriggerSwap) 
            {
                if(maxTxActive)
                    swapAmount = minAmountToTriggerSwap;
                swapTokensOnContract(swapAmount);    
            }

            uint256 amountToAdd = (isExcludedAll[sender] || isExcludedAll[recipient]) ? 
                                         amount : getAmounts4Fee(sender, recipient, amount);

            if(maxWalletActive && !isWalletExcluded[recipient])
                require(balanceOf(recipient).add(amountToAdd) <= maxWallet);

            uint256 amountToReduce = (!maxWalletActive && isExcludedAll[sender]) ? amount.sub(amountToAdd) : amount;
            _balances[sender] = _balances[sender].sub(amountToReduce, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(amountToAdd);
            emit Transfer(sender, recipient, amountToAdd);
            return true;
        }
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
        
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
        
    function _transferStandard(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function getAmounts4Fee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;
        
        if(pairAddressCheck[sender]) {
            feeAmount = amount.mul(totalTax4Buy).div(100);
        }
        else if(pairAddressCheck[recipient]) {
            feeAmount = amount.mul(totalTax4Sell).div(100);
        }
        
        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }
    
    function transferETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
}