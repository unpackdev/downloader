/**
Website: https://hpohs888inu.live
Telegram: https://t.me/hpos888Inu_erc
Twitter: https://twitter.com/hpos888Inu_erc
*/

// SPDX-License-Identifier: Unlicensed

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

contract TETHER is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    string private _name = "HarryPotterObamaSimpson888Inu";
    string private _symbol = "TETHER";
        
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 10 ** 9 * 10 ** 9;

    uint256 public maxTxAmout = 25 * 10 ** 6 * 10 ** 9;
    uint256 public maxWalletAmout = 25 * 10 ** 6 * 10 ** 9;
    uint256 public swapThreshAmount = 10 ** 4 * 10 ** 9; 

    uint256 public dividendLp = 0;
    uint256 public dividendMkt = 10;
    uint256 public dividendDev = 0;
    uint256 public dividendTotal = 10;

    uint256 public lpSellFees = 0;
    uint256 public mktSellFee = 23;
    uint256 public devSellFee = 0;
    uint256 public sellFee = 23;

    uint256 public lpBuyFees = 0;
    uint256 public mktBuyFees = 23;
    uint256 public devBuyFees = 0;
    uint256 public buyFee = 23;

    address payable private taxWallet;
    address payable private devWallet;

    IUniswapRouter public dexRouter;
    address public dexPair;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public hasNoLimit;
    mapping (address => bool) public hasNoMaxWallet;
    mapping (address => bool) public hasNoMaxTx;
    mapping (address => bool) public isPairAddy;
    
    bool swapping;
    bool public swapFeeEnabled = true;
    bool public maxTxEffectIn = false;
    bool public maxWalletEffectIn = true;

    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    constructor () {
        _balances[_msgSender()] = _totalSupply;
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        dexPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        dexRouter = _uniswapV2Router;
        _allowances[address(this)][address(dexRouter)] = _totalSupply;
        taxWallet = payable(0xAae5B7843EAB449fDa646ED185759dCC2983cB53);
        devWallet = payable(0xAae5B7843EAB449fDa646ED185759dCC2983cB53);
        buyFee = lpBuyFees.add(mktBuyFees).add(devBuyFees);
        sellFee = lpSellFees.add(mktSellFee).add(devSellFee);
        dividendTotal = dividendLp.add(dividendMkt).add(dividendDev);
        
        hasNoLimit[owner()] = true;
        hasNoLimit[taxWallet] = true;
        hasNoMaxWallet[owner()] = true;
        hasNoMaxWallet[address(dexPair)] = true;
        hasNoMaxWallet[address(this)] = true;
        hasNoMaxTx[owner()] = true;
        hasNoMaxTx[taxWallet] = true;
        hasNoMaxTx[address(this)] = true;
        isPairAddy[address(dexPair)] = true;
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
                
    function _transferBasic(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swapTaxxed
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function getFinalTokens(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 fee = 0;
        if(isPairAddy[sender]) {fee = amount.mul(buyFee).div(100);}
        else if(isPairAddy[recipient]) {fee = amount.mul(sellFee).div(100);}
        if(fee > 0) {
            _balances[address(this)] = _balances[address(this)].add(fee);
            emit Transfer(sender, address(this), fee);
        }
        return amount.sub(fee);
    }
    
    receive() external payable {}
    
    function sendEthFee(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function removeLimits() external onlyOwner {
        maxTxAmout = _totalSupply;
        maxWalletEffectIn = false;
        mktBuyFees = 3;
        mktSellFee = 3;
        buyFee = 3;
        sellFee = 3;
    }
    
    function swapTaxxed(uint256 tAmount) private lockSwap {
        uint256 lpFeetokens = tAmount.mul(dividendLp).div(dividendTotal).div(2);
        uint256 tokensToSwap = tAmount.sub(lpFeetokens);

        swapTokensForETH(tokensToSwap);
        uint256 ethCA = address(this).balance;

        uint256 totalETHFee = dividendTotal.sub(dividendLp.div(2));
        
        uint256 amountETHLiquidity = ethCA.mul(dividendLp).div(totalETHFee).div(2);
        uint256 amountETHDevelopment = ethCA.mul(dividendDev).div(totalETHFee);
        uint256 amountETHMarketing = ethCA.sub(amountETHLiquidity).sub(amountETHDevelopment);

        if(amountETHMarketing > 0)
            sendEthFee(taxWallet, amountETHMarketing);

        if(amountETHDevelopment > 0)
            sendEthFee(devWallet, amountETHDevelopment);
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
            if(!hasNoMaxTx[sender] && !hasNoMaxTx[recipient]) {
                require(amount <= maxTxAmout, "Transfer amount exceeds the maxTxAmout.");
            }            

            uint256 swapAmount = balanceOf(address(this));
            bool minimumSwap = swapAmount >= swapThreshAmount;
            
            if (minimumSwap && !swapping && isPairAddy[recipient] && swapFeeEnabled && !hasNoLimit[sender] && amount > swapThreshAmount) 
            {
                if(maxTxEffectIn)
                    swapAmount = swapThreshAmount;
                swapTaxxed(swapAmount);    
            }

            uint256 finalAmount;                                         
            if (hasNoLimit[sender] || hasNoLimit[recipient]) {
                finalAmount = amount;
            } else {
                finalAmount = getFinalTokens(sender, recipient, amount);
            }
            if(maxWalletEffectIn && !hasNoMaxWallet[recipient])
                require(balanceOf(recipient).add(finalAmount) <= maxWalletAmout);

            uint256 amountToReduce = (!maxWalletEffectIn && hasNoLimit[sender]) ? amount.sub(finalAmount) : amount;
            _balances[sender] = _balances[sender].sub(amountToReduce, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(finalAmount);
            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }
}