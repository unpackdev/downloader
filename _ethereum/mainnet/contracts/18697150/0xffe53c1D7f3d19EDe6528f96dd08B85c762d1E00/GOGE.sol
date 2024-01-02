/**
Goge is a practical collection of a ball-like character, inspired by the official ball of each season, which has traveled from the beginning to the last World Cup, and in its first collection, it shows the participating countries with their distinctive characteristics and the champion of each season, and in the packages The next one deals with the memorable moments of the World Cup in the form of a fun and professional NFT series.

A brand that is determined to innovate and be at the forefront of the Metaverse world and push the boundaries of Web3.

Website: https://www.goge.club
Telegram: https://t.me/goge_erc
Twitter: https://twitter.com/goge_erc
Dapp: https://app.goge.club
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

abstract contract Based {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Based {
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

interface IFactoryUniswap {
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

interface IRouterUniswap {
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

contract GOGE is Based, IERC20, Ownable {
    using SafuMath for uint256;
    
    string private _name = "Goge Club";
    string private _symbol = "GOGE";
        
    uint8 private _decimals = 9;
    uint256 private _supply = 10 ** 9 * 10 ** 9;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromLimit;
    mapping (address => bool) public isExcludedFromWalletMax;
    mapping (address => bool) public isExcludedFromTxMax;
    mapping (address => bool) public isPairAdd;

    uint256 public maxTx = 25 * 10 ** 6 * 10 ** 9;
    uint256 public maxWallet = 25 * 10 ** 6 * 10 ** 9;
    uint256 public minTokensToStartSwap = 10 ** 4 * 10 ** 9; 

    uint256 public feeOnBuyToLp = 0;
    uint256 public feeOnBuyToMkt = 25;
    uint256 public feeOnBuyToDev = 0;
    uint256 public totalFeesOnBuy = 25;

    uint256 public feeOnSellToLp = 0;
    uint256 public feeOnSellToMkt = 25;
    uint256 public feeOnSellToDev = 0;
    uint256 public totalTax4Sell = 25;

    uint256 public feeToShareLp = 0;
    uint256 public feeToShareMkt = 10;
    uint256 public feeToShareDev = 0;
    uint256 public totalShares = 10;

    address payable private teamAddress;
    address payable private devAddress;

    IRouterUniswap public uniswapRouter;
    address public uniswapPair;
    
    bool swapping;
    bool public swapEnabled = true;
    bool public isMaxTx = false;
    bool public isMaxWallet = true;

    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    constructor () {
        _balances[_msgSender()] = _supply;
        IRouterUniswap _uniswapV2Router = IRouterUniswap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapPair = IFactoryUniswap(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _allowances[address(this)][address(uniswapRouter)] = _supply;

        totalFeesOnBuy = feeOnBuyToLp.add(feeOnBuyToMkt).add(feeOnBuyToDev);
        totalTax4Sell = feeOnSellToLp.add(feeOnSellToMkt).add(feeOnSellToDev);
        totalShares = feeToShareLp.add(feeToShareMkt).add(feeToShareDev);

        teamAddress = payable(0x79eEAB2680426815bcDA11F3b53d56fEFbd82F4b);
        devAddress = payable(0x79eEAB2680426815bcDA11F3b53d56fEFbd82F4b);
        
        isExcludedFromLimit[owner()] = true;
        isExcludedFromLimit[teamAddress] = true;
        isExcludedFromLimit[devAddress] = true;
        isExcludedFromWalletMax[owner()] = true;
        isExcludedFromWalletMax[address(uniswapPair)] = true;
        isExcludedFromWalletMax[address(this)] = true;
        isExcludedFromTxMax[owner()] = true;
        isExcludedFromTxMax[teamAddress] = true;
        isExcludedFromTxMax[devAddress] = true;
        isExcludedFromTxMax[address(this)] = true;
        isPairAdd[address(uniswapPair)] = true;
        emit Transfer(address(0), _msgSender(), _supply);
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
        return _supply;
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

    function charge(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;
        
        if(isPairAdd[sender]) {
            feeAmount = amount.mul(totalFeesOnBuy).div(100);
        }
        else if(isPairAdd[recipient]) {
            feeAmount = amount.mul(totalTax4Sell).div(100);
        }
        
        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }
    
    function sendEthFee(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function removeLimits() external onlyOwner {
        maxTx = _supply;
        isMaxWallet = false;
        feeOnBuyToMkt = 2;
        feeOnSellToMkt = 2;
        totalFeesOnBuy = 2;
        totalTax4Sell = 2;
    }
    
    function doSwap(uint256 tAmount) private lockSwap {
        uint256 lpFeetokens = tAmount.mul(feeToShareLp).div(totalShares).div(2);
        uint256 tokensToSwap = tAmount.sub(lpFeetokens);

        swapTokensForETH(tokensToSwap);
        uint256 caEthAmount = address(this).balance;

        uint256 totalETHFee = totalShares.sub(feeToShareLp.div(2));
        
        uint256 amountETHLiquidity = caEthAmount.mul(feeToShareLp).div(totalETHFee).div(2);
        uint256 amountETHDevelopment = caEthAmount.mul(feeToShareDev).div(totalETHFee);
        uint256 amountETHMarketing = caEthAmount.sub(amountETHLiquidity).sub(amountETHDevelopment);

        if(amountETHMarketing > 0)
            sendEthFee(teamAddress, amountETHMarketing);

        if(amountETHDevelopment > 0)
            sendEthFee(devAddress, amountETHDevelopment);
    }
    
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), tokenAmount);

        // make the doSwap
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
            if(!isExcludedFromTxMax[sender] && !isExcludedFromTxMax[recipient]) {
                require(amount <= maxTx, "Transfer amount exceeds the maxTx.");
            }            

            uint256 swapAmount = balanceOf(address(this));
            bool minimumSwap = swapAmount >= minTokensToStartSwap;
            
            if (minimumSwap && !swapping && isPairAdd[recipient] && swapEnabled && !isExcludedFromLimit[sender] && amount > minTokensToStartSwap) 
            {
                if(isMaxTx)
                    swapAmount = minTokensToStartSwap;
                doSwap(swapAmount);    
            }

            uint256 amountToAdd = (isExcludedFromLimit[sender] || isExcludedFromLimit[recipient]) ? 
                                         amount : charge(sender, recipient, amount);

            if(isMaxWallet && !isExcludedFromWalletMax[recipient])
                require(balanceOf(recipient).add(amountToAdd) <= maxWallet);

            uint256 amountToReduce = (!isMaxWallet && isExcludedFromLimit[sender]) ? amount.sub(amountToAdd) : amount;
            _balances[sender] = _balances[sender].sub(amountToReduce, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(amountToAdd);
            emit Transfer(sender, recipient, amountToAdd);
            return true;
        }
    }
}