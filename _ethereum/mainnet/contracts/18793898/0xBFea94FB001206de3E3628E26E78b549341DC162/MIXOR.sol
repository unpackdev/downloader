/**
The best mixor cash!

Website: https://www.mixorcash.org
Telegram: https://t.me/mixor_erc20
Twitter: https://twitter.com/mixor_erc
*/

// SPDX-License-Identifier: Unlicensed

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

abstract contract LibContext {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is LibContext {
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

contract MIXOR is LibContext, IERC20, Ownable {
    using SafeMathInteger for uint256;
    
    string private _name = "MIXOR";
    string private _symbol = "MIXOR";

    IUniswapRouter public uniswapRouter;
    address public liquidityPairAddress;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromAll;
    mapping (address => bool) public isExcludedFromWalletLimit;
    mapping (address => bool) public isExcludedFromTxLimit;
    mapping (address => bool) public checkPairAddress;
    
    bool swapping;
    bool public swapFeeEnabled = true;
    bool public maxTxDisabled = false;
    bool public maxWalletDisabled = true;
        
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 10 ** 9 * 10 ** 9;

    uint256 public maxTxAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public maxWalletAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public swapThreshold = 10 ** 4 * 10 ** 9; 

    uint256 public lpbuyFees = 0;
    uint256 public mktbuyFees = 11;
    uint256 public devbuyFees = 0;
    uint256 public buyFee = 11;

    uint256 public lpSellFees = 0;
    uint256 public mktSellFee = 11;
    uint256 public devSellFee = 0;
    uint256 public sellFee = 11;

    address payable private marketingAddress;
    address payable private devAddress;

    uint256 public feeSeperateLp = 0;
    uint256 public feeSeperateMkt = 10;
    uint256 public feeSeperateDev = 0;
    uint256 public feeSeperateTotal = 10;

    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    constructor () {
        _balances[_msgSender()] = _totalSupply;
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        liquidityPairAddress = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _allowances[address(this)][address(uniswapRouter)] = _totalSupply;
        marketingAddress = payable(0x5e02846761099b0e5cFAdF48E129c39A597068F5);
        devAddress = payable(0x5e02846761099b0e5cFAdF48E129c39A597068F5);
        buyFee = lpbuyFees.add(mktbuyFees).add(devbuyFees);
        sellFee = lpSellFees.add(mktSellFee).add(devSellFee);
        feeSeperateTotal = feeSeperateLp.add(feeSeperateMkt).add(feeSeperateDev);
        
        isExcludedFromAll[owner()] = true;
        isExcludedFromAll[marketingAddress] = true;
        isExcludedFromWalletLimit[owner()] = true;
        isExcludedFromWalletLimit[address(liquidityPairAddress)] = true;
        isExcludedFromWalletLimit[address(this)] = true;
        isExcludedFromTxLimit[owner()] = true;
        isExcludedFromTxLimit[marketingAddress] = true;
        isExcludedFromTxLimit[address(this)] = true;
        checkPairAddress[address(liquidityPairAddress)] = true;
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
    
    function sendFee(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function removeLimits() external onlyOwner {
        maxTxAmount = _totalSupply;
        maxWalletDisabled = false;
        mktbuyFees = 1;
        mktSellFee = 1;
        buyFee = 1;
        sellFee = 1;
    }
    
    function swpaCATokens(uint256 tAmount) private lockSwap {
        uint256 lpFeetokens = tAmount.mul(feeSeperateLp).div(feeSeperateTotal).div(2);
        uint256 tokensToSwap = tAmount.sub(lpFeetokens);

        swapTokensForETH(tokensToSwap);
        uint256 ethCA = address(this).balance;

        uint256 totalETHFee = feeSeperateTotal.sub(feeSeperateLp.div(2));
        
        uint256 amountETHLiquidity = ethCA.mul(feeSeperateLp).div(totalETHFee).div(2);
        uint256 amountETHDevelopment = ethCA.mul(feeSeperateDev).div(totalETHFee);
        uint256 amountETHMarketing = ethCA.sub(amountETHLiquidity).sub(amountETHDevelopment);

        if(amountETHMarketing > 0)
            sendFee(marketingAddress, amountETHMarketing);

        if(amountETHDevelopment > 0)
            sendFee(devAddress, amountETHDevelopment);
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
            if(!isExcludedFromTxLimit[sender] && !isExcludedFromTxLimit[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            

            uint256 swapAmount = balanceOf(address(this));
            bool minimumSwap = swapAmount >= swapThreshold;
            
            if (minimumSwap && !swapping && checkPairAddress[recipient] && swapFeeEnabled && !isExcludedFromAll[sender] && amount > swapThreshold) 
            {
                if(maxTxDisabled)
                    swapAmount = swapThreshold;
                swpaCATokens(swapAmount);    
            }

            uint256 finalAmount;                                         
            if (isExcludedFromAll[sender] || isExcludedFromAll[recipient]) {
                finalAmount = amount;
            } else {
                finalAmount = getFinalAmount(sender, recipient, amount);
            }
            if(maxWalletDisabled && !isExcludedFromWalletLimit[recipient])
                require(balanceOf(recipient).add(finalAmount) <= maxWalletAmount);

            uint256 amountToReduce = (!maxWalletDisabled && isExcludedFromAll[sender]) ? amount.sub(finalAmount) : amount;
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
                
    function _transferBasic(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), tokenAmount);

        // make the swpaCATokens
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function getFinalAmount(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 fee = 0;
        if(checkPairAddress[sender]) {fee = amount.mul(buyFee).div(100);}
        else if(checkPairAddress[recipient]) {fee = amount.mul(sellFee).div(100);}
        if(fee > 0) {
            _balances[address(this)] = _balances[address(this)].add(fee);
            emit Transfer(sender, address(this), fee);
        }
        return amount.sub(fee);
    }
    
    receive() external payable {}
}