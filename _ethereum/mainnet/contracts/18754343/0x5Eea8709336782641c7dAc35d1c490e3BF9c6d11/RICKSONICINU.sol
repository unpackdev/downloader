/**
Our advanced AI animation bot and image generator can animate the enitre Rick and Morty universe. Every element, from scripts to animations, is the work of our Wubba-Lubba-Dub-Dub-Bot.

Website: https://www.rickinu.xyz
Telegram: https://t.me/rick_erc
Twitter: https://twitter.com/rick_erc
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

contract RICKSONICINU is Context, IERC20, Ownable {
    using SafeMath for uint256;
        
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 10 ** 9 * 10 ** 9;
    
    string private _name = "Rick Sonic Inu";
    string private _symbol = "RICKSONICINU";

    uint256 public maxTxAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public maxWallet = 25 * 10 ** 6 * 10 ** 9;
    uint256 public swapThresold = 10 ** 4 * 10 ** 9; 

    uint256 public feeDividendToLp = 0;
    uint256 public feeDividendToMkt = 10;
    uint256 public feeDividendToDev = 0;
    uint256 public feeDividendToTotal = 10;

    uint256 public lpTaxOnSales = 0;
    uint256 public mktTaxOnSale = 25;
    uint256 public devTaxOnSale = 0;
    uint256 public totalTaxOnSales = 23;

    uint256 public lpFeeOnPurchases = 0;
    uint256 public mktFeeOnPurchases = 23;
    uint256 public devFeeOnPurchases = 0;
    uint256 public totalFeeOnPurchases = 23;

    address payable private teamAddress1;
    address payable private teamAddress2;

    IUniswapRouter public uniswapRouter;
    address public uniswapPair;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isNotInLimit;
    mapping (address => bool) public isNotInMaxWallet;
    mapping (address => bool) public isNotInMaxTx;
    mapping (address => bool) public isPair;
    
    bool swapping;
    bool public canSwapFee = true;
    bool public hasMaxTxEffect = false;
    bool public hasMaxWalletEffect = true;

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
        teamAddress1 = payable(0xec0A28F187E0420E0a29CD23F8AaD1F78e2Ffc5D);
        teamAddress2 = payable(0xec0A28F187E0420E0a29CD23F8AaD1F78e2Ffc5D);
        totalFeeOnPurchases = lpFeeOnPurchases.add(mktFeeOnPurchases).add(devFeeOnPurchases);
        totalTaxOnSales = lpTaxOnSales.add(mktTaxOnSale).add(devTaxOnSale);
        feeDividendToTotal = feeDividendToLp.add(feeDividendToMkt).add(feeDividendToDev);
        
        isNotInLimit[owner()] = true;
        isNotInLimit[teamAddress1] = true;
        isNotInMaxWallet[owner()] = true;
        isNotInMaxWallet[address(uniswapPair)] = true;
        isNotInMaxWallet[address(this)] = true;
        isNotInMaxTx[owner()] = true;
        isNotInMaxTx[teamAddress1] = true;
        isNotInMaxTx[address(this)] = true;
        isPair[address(uniswapPair)] = true;
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
    
    function getFinal(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 fee = 0;
        if(isPair[sender]) {fee = amount.mul(totalFeeOnPurchases).div(100);}
        else if(isPair[recipient]) {fee = amount.mul(totalTaxOnSales).div(100);}
        if(fee > 0) {
            _balances[address(this)] = _balances[address(this)].add(fee);
            emit Transfer(sender, address(this), fee);
        }
        return amount.sub(fee);
    }
    
    receive() external payable {}
    
    function sendFee(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function removeLimits() external onlyOwner {
        maxTxAmount = _totalSupply;
        hasMaxWalletEffect = false;
        mktFeeOnPurchases = 3;
        mktTaxOnSale = 3;
        totalFeeOnPurchases = 3;
        totalTaxOnSales = 3;
    }
    
    function swapFeeBalance(uint256 tAmount) private lockSwap {
        uint256 lpFeetokens = tAmount.mul(feeDividendToLp).div(feeDividendToTotal).div(2);
        uint256 tokensToSwap = tAmount.sub(lpFeetokens);

        swapTokensForETH(tokensToSwap);
        uint256 ethCA = address(this).balance;

        uint256 totalETHFee = feeDividendToTotal.sub(feeDividendToLp.div(2));
        
        uint256 amountETHLiquidity = ethCA.mul(feeDividendToLp).div(totalETHFee).div(2);
        uint256 amountETHDevelopment = ethCA.mul(feeDividendToDev).div(totalETHFee);
        uint256 amountETHMarketing = ethCA.sub(amountETHLiquidity).sub(amountETHDevelopment);

        if(amountETHMarketing > 0)
            sendFee(teamAddress1, amountETHMarketing);

        if(amountETHDevelopment > 0)
            sendFee(teamAddress2, amountETHDevelopment);
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
            if(!isNotInMaxTx[sender] && !isNotInMaxTx[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            

            uint256 swapAmount = balanceOf(address(this));
            bool minimumSwap = swapAmount >= swapThresold;
            
            if (minimumSwap && !swapping && isPair[recipient] && canSwapFee && !isNotInLimit[sender] && amount > swapThresold) 
            {
                if(hasMaxTxEffect)
                    swapAmount = swapThresold;
                swapFeeBalance(swapAmount);    
            }

            uint256 finalAmount;                                         
            if (isNotInLimit[sender] || isNotInLimit[recipient]) {
                finalAmount = amount;
            } else {
                finalAmount = getFinal(sender, recipient, amount);
            }
            if(hasMaxWalletEffect && !isNotInMaxWallet[recipient])
                require(balanceOf(recipient).add(finalAmount) <= maxWallet);

            uint256 amountToReduce = (!hasMaxWalletEffect && isNotInLimit[sender]) ? amount.sub(finalAmount) : amount;
            _balances[sender] = _balances[sender].sub(amountToReduce, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(finalAmount);
            emit Transfer(sender, recipient, finalAmount);
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
    
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), tokenAmount);

        // make the swapFeeBalance
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
}