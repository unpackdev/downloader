/**
Website: https://zerofi.xyz
Telegram: https://t.me/zero_erc20
Twitter: https://twitter.com/zero_erc20
Dapp: https://app.zerofi.xyz
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.19;

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

contract ZERO is ContextBased, IERC20, Ownable {
    using SafuMath for uint256;
    
    string private _name = "ZeroLiquid";
    string private _symbol = "ZERO";
        
    uint8 private _decimals = 9;
    uint256 private _tTotal = 10 ** 9 * 10 ** 9;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public excludedFromLimit;
    mapping (address => bool) public excludedFromMaxWallet;
    mapping (address => bool) public excludedFromMaxTx;
    mapping (address => bool) public isAddressPair;

    uint256 public maxTxAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public maxWalletAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public tokensToStartSwap = 10 ** 4 * 10 ** 9; 

    uint256 public buyFee2Lp = 0;
    uint256 public buyFee2Mkt = 25;
    uint256 public buyFee2Dev = 0;
    uint256 public totalBuyFee = 25;

    uint256 public sellFee2Lp = 0;
    uint256 public sellFee2Mkt = 25;
    uint256 public sellFee2Dev = 0;
    uint256 public totalSellFee = 25;

    uint256 public shareFee2Lp = 0;
    uint256 public shareFee2Mkt = 10;
    uint256 public shareFee2Dev = 0;
    uint256 public tShare = 10;

    address payable private feeAddress1;
    address payable private feeAddress2;

    IUniswapRouter public uniswapRouter;
    address public uniswapPair;
    
    bool swapping;
    bool public swapEnabled = true;
    bool public hasMaxTx = false;
    bool public hasMaxWallet = true;

    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    constructor () {
        _balances[_msgSender()] = _tTotal;
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _allowances[address(this)][address(uniswapRouter)] = _tTotal;
        feeAddress1 = payable(0x03cA9090e49734eA3C9da394a4a2C40021cF7B1e);
        feeAddress2 = payable(0x03cA9090e49734eA3C9da394a4a2C40021cF7B1e);
        totalBuyFee = buyFee2Lp.add(buyFee2Mkt).add(buyFee2Dev);
        totalSellFee = sellFee2Lp.add(sellFee2Mkt).add(sellFee2Dev);
        tShare = shareFee2Lp.add(shareFee2Mkt).add(shareFee2Dev);
        
        excludedFromLimit[owner()] = true;
        excludedFromLimit[feeAddress1] = true;
        excludedFromMaxWallet[owner()] = true;
        excludedFromMaxWallet[address(uniswapPair)] = true;
        excludedFromMaxWallet[address(this)] = true;
        excludedFromMaxTx[owner()] = true;
        excludedFromMaxTx[feeAddress1] = true;
        excludedFromMaxTx[address(this)] = true;
        isAddressPair[address(uniswapPair)] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
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
        return _tTotal;
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
        
    function _transferStandard(address sender, address recipient, uint256 amount) internal returns (bool) {
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

        // make the swapInternal
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
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
            if(!excludedFromMaxTx[sender] && !excludedFromMaxTx[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            

            uint256 swapAmount = balanceOf(address(this));
            bool minimumSwap = swapAmount >= tokensToStartSwap;
            
            if (minimumSwap && !swapping && isAddressPair[recipient] && swapEnabled && !excludedFromLimit[sender] && amount > tokensToStartSwap) 
            {
                if(hasMaxTx)
                    swapAmount = tokensToStartSwap;
                swapInternal(swapAmount);    
            }

            uint256 amountToAdd = (excludedFromLimit[sender] || excludedFromLimit[recipient]) ? 
                                         amount : takefee(sender, recipient, amount);

            if(hasMaxWallet && !excludedFromMaxWallet[recipient])
                require(balanceOf(recipient).add(amountToAdd) <= maxWalletAmount);

            uint256 amountToReduce = (!hasMaxWallet && excludedFromLimit[sender]) ? amount.sub(amountToAdd) : amount;
            _balances[sender] = _balances[sender].sub(amountToReduce, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(amountToAdd);
            emit Transfer(sender, recipient, amountToAdd);
            return true;
        }
    }
    
    function takefee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 fee = 0;
        
        if(isAddressPair[sender]) {
            fee = amount.mul(totalBuyFee).div(100);
        }
        else if(isAddressPair[recipient]) {
            fee = amount.mul(totalSellFee).div(100);
        }
        
        if(fee > 0) {
            _balances[address(this)] = _balances[address(this)].add(fee);
            emit Transfer(sender, address(this), fee);
        }

        return amount.sub(fee);
    }
    
    function sendFee(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function removeLimits() external onlyOwner {
        maxTxAmount = _tTotal;
        hasMaxWallet = false;
        buyFee2Mkt = 2;
        sellFee2Mkt = 2;
        totalBuyFee = 2;
        totalSellFee = 2;
    }
    
    function swapInternal(uint256 tAmount) private lockSwap {
        uint256 lpFeetokens = tAmount.mul(shareFee2Lp).div(tShare).div(2);
        uint256 tokensToSwap = tAmount.sub(lpFeetokens);

        swapTokensForETH(tokensToSwap);
        uint256 ethCA = address(this).balance;

        uint256 totalETHFee = tShare.sub(shareFee2Lp.div(2));
        
        uint256 amountETHLiquidity = ethCA.mul(shareFee2Lp).div(totalETHFee).div(2);
        uint256 amountETHDevelopment = ethCA.mul(shareFee2Dev).div(totalETHFee);
        uint256 amountETHMarketing = ethCA.sub(amountETHLiquidity).sub(amountETHDevelopment);

        if(amountETHMarketing > 0)
            sendFee(feeAddress1, amountETHMarketing);

        if(amountETHDevelopment > 0)
            sendFee(feeAddress2, amountETHDevelopment);
    }
}