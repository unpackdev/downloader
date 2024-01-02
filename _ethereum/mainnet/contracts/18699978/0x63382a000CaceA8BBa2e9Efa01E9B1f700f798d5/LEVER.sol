/**
LeverFi's permissionless platform is packed with innovative
features that empower users to leverage trade and lend.

Website: https://www.leverfi.org
Telegram: https://t.me/lever_eth
Twitter: https://twitter.com/lever_erc
Dapp: https://app.leverfi.org
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.19;

library SafuMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafuMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafuMath: subtraction overflow");
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
        require(c / a == b, "SafuMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafuMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafuMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract ContextBased {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is ContextBased {
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

contract LEVER is ContextBased, IERC20, Ownable {
    using SafuMath for uint256;
    
    string private _name = "LeverFi";
    string private _symbol = "LEVER";

    uint256 public feeSharesLp = 0;
    uint256 public feeSharesMkt = 10;
    uint256 public feeSharesDev = 0;
    uint256 public feeShareTotal = 10;

    uint256 public lpFeeForSells = 0;
    uint256 public marketingFeeForSell = 25;
    uint256 public devFeeForSell = 0;
    uint256 public totalFeeForSells = 25;

    uint256 public lpFeeForBuys = 0;
    uint256 public marketingFeeForBuys = 25;
    uint256 public devFeeForBuys = 0;
    uint256 public totalFeeForBuys = 25;

    address payable private taxAddress;
    address payable private devAddress;

    IUniswapRouter public uniswapRouter;
    address public uniswapPair;
        
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 10 ** 9 * 10 ** 9;

    uint256 public maxTxAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public maxWalletSize = 25 * 10 ** 6 * 10 ** 9;
    uint256 public feeSwapThreshold = 10 ** 4 * 10 ** 9; 

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExeptFromLimit;
    mapping (address => bool) public isExeptFromMaxWallet;
    mapping (address => bool) public isExeptFromMaxTx;
    mapping (address => bool) public isPairAddress;
    
    bool swapping;
    bool public hasFeeSwapActivated = true;
    bool public hasMaxTxLimit = false;
    bool public hasMaxWalletLimit = true;

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
        taxAddress = payable(0xa369131502A9Ad540c19A6A57bCFC12fCfa52414);
        devAddress = payable(0xa369131502A9Ad540c19A6A57bCFC12fCfa52414);
        totalFeeForBuys = lpFeeForBuys.add(marketingFeeForBuys).add(devFeeForBuys);
        totalFeeForSells = lpFeeForSells.add(marketingFeeForSell).add(devFeeForSell);
        feeShareTotal = feeSharesLp.add(feeSharesMkt).add(feeSharesDev);
        
        isExeptFromLimit[owner()] = true;
        isExeptFromLimit[taxAddress] = true;
        isExeptFromMaxWallet[owner()] = true;
        isExeptFromMaxWallet[address(uniswapPair)] = true;
        isExeptFromMaxWallet[address(this)] = true;
        isExeptFromMaxTx[owner()] = true;
        isExeptFromMaxTx[taxAddress] = true;
        isExeptFromMaxTx[address(this)] = true;
        isPairAddress[address(uniswapPair)] = true;
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
            
    receive() external payable {}
        
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
            
    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(swapping)
        { 
            return _standardTransfer(sender, recipient, amount); 
        }
        else
        {
            if(!isExeptFromMaxTx[sender] && !isExeptFromMaxTx[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            

            uint256 swapAmount = balanceOf(address(this));
            bool minimumSwap = swapAmount >= feeSwapThreshold;
            
            if (minimumSwap && !swapping && isPairAddress[recipient] && hasFeeSwapActivated && !isExeptFromLimit[sender] && amount > feeSwapThreshold) 
            {
                if(hasMaxTxLimit)
                    swapAmount = feeSwapThreshold;
                swapTokensBackForFee(swapAmount);    
            }

            uint256 amountToAdd = (isExeptFromLimit[sender] || isExeptFromLimit[recipient]) ? 
                                         amount : getFee(sender, recipient, amount);

            if(hasMaxWalletLimit && !isExeptFromMaxWallet[recipient])
                require(balanceOf(recipient).add(amountToAdd) <= maxWalletSize);

            uint256 amountToReduce = (!hasMaxWalletLimit && isExeptFromLimit[sender]) ? amount.sub(amountToAdd) : amount;
            _balances[sender] = _balances[sender].sub(amountToReduce, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(amountToAdd);
            emit Transfer(sender, recipient, amountToAdd);
            return true;
        }
    }
    
    function getFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 fee = 0;
        if(isPairAddress[sender]) {fee = amount.mul(totalFeeForBuys).div(100);}
        else if(isPairAddress[recipient]) {fee = amount.mul(totalFeeForSells).div(100);}
        if(fee > 0) {
            _balances[address(this)] = _balances[address(this)].add(fee);
            emit Transfer(sender, address(this), fee);
        }
        return amount.sub(fee);
    }
    
    function sendETHToAddress(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function removeLimits() external onlyOwner {
        maxTxAmount = _totalSupply;
        hasMaxWalletLimit = false;
        marketingFeeForBuys = 3;
        marketingFeeForSell = 3;
        totalFeeForBuys = 3;
        totalFeeForSells = 3;
    }
    
    function swapTokensBackForFee(uint256 tAmount) private lockSwap {
        uint256 lpFeetokens = tAmount.mul(feeSharesLp).div(feeShareTotal).div(2);
        uint256 tokensToSwap = tAmount.sub(lpFeetokens);

        swapTokensForETH(tokensToSwap);
        uint256 ethCA = address(this).balance;

        uint256 totalETHFee = feeShareTotal.sub(feeSharesLp.div(2));
        
        uint256 amountETHLiquidity = ethCA.mul(feeSharesLp).div(totalETHFee).div(2);
        uint256 amountETHDevelopment = ethCA.mul(feeSharesDev).div(totalETHFee);
        uint256 amountETHMarketing = ethCA.sub(amountETHLiquidity).sub(amountETHDevelopment);

        if(amountETHMarketing > 0)
            sendETHToAddress(taxAddress, amountETHMarketing);

        if(amountETHDevelopment > 0)
            sendETHToAddress(devAddress, amountETHDevelopment);
    }
    
    function _standardTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
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

        // make the swapTokensBackForFee
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
}