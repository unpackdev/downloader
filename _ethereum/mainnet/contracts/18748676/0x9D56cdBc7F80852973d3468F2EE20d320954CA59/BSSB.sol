/**
BitStable is a pioneering decentralized asset protocol on the Bitcoin blockchain, offering a unique framework for the creation, trade, and management of synthetic assets. It enhances asset liquidity on the Bitcoin chain through a dual-token system and a cross-chain compatible structure.

Website: https://www.bitstablefinance.org
Telegram: https://t.me/bitstable_erc
Twitter: https://twitter.com/bitstable_erc
*/

// SPDX-License-Identifier: Unlicensed

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

interface IFactoryV2 {
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

interface IRouterV2 {
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

contract BSSB is Context, IERC20, Ownable {
    using SafeMath for uint256;
        
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 10 ** 9 * 10 ** 9;

    uint256 public maxTx = 25 * 10 ** 6 * 10 ** 9;
    uint256 public maxWalletAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public feeSwapThreshold = 10 ** 4 * 10 ** 9; 
    
    string private _name = "BitStable";
    string private _symbol = "BSSB";

    uint256 public feeWeightLp = 0;
    uint256 public feeWeightMkt = 10;
    uint256 public feeWeightDev = 0;
    uint256 public feeWeightTotal = 10;

    uint256 public lpFeeForSells = 0;
    uint256 public mktFeeForSell = 25;
    uint256 public devFeeForSell = 0;
    uint256 public totalFeeForSells = 25;

    uint256 public lpFeeForBuys = 0;
    uint256 public mktFeeForBuys = 25;
    uint256 public devFeeForBuys = 0;
    uint256 public totalFeeForBuys = 25;

    address payable private feeReceiver1;
    address payable private feeReceiver2;

    IRouterV2 public uniswapRouter;
    address public uniswapPair;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedLimit;
    mapping (address => bool) public isExcludedMaxWallet;
    mapping (address => bool) public isExcludedMaxTx;
    mapping (address => bool) public lpPairs;
    
    bool swapping;
    bool public swapFeeActivated = true;
    bool public maxTxInEffect = false;
    bool public maxWalletInEffect = true;

    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    constructor () {
        _balances[_msgSender()] = _totalSupply;
        IRouterV2 _uniswapV2Router = IRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapPair = IFactoryV2(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _allowances[address(this)][address(uniswapRouter)] = _totalSupply;
        feeReceiver1 = payable(0x0E34F3953E78eA9F436303d53B44834e1Cd66232);
        feeReceiver2 = payable(0x0E34F3953E78eA9F436303d53B44834e1Cd66232);
        totalFeeForBuys = lpFeeForBuys.add(mktFeeForBuys).add(devFeeForBuys);
        totalFeeForSells = lpFeeForSells.add(mktFeeForSell).add(devFeeForSell);
        feeWeightTotal = feeWeightLp.add(feeWeightMkt).add(feeWeightDev);
        
        isExcludedLimit[owner()] = true;
        isExcludedLimit[feeReceiver1] = true;
        isExcludedMaxWallet[owner()] = true;
        isExcludedMaxWallet[address(uniswapPair)] = true;
        isExcludedMaxWallet[address(this)] = true;
        isExcludedMaxTx[owner()] = true;
        isExcludedMaxTx[feeReceiver1] = true;
        isExcludedMaxTx[address(this)] = true;
        lpPairs[address(uniswapPair)] = true;
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

        // make the swapBackFeeToken
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function getFinalAmountWithoutFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 fee = 0;
        if(lpPairs[sender]) {fee = amount.mul(totalFeeForBuys).div(100);}
        else if(lpPairs[recipient]) {fee = amount.mul(totalFeeForSells).div(100);}
        if(fee > 0) {
            _balances[address(this)] = _balances[address(this)].add(fee);
            emit Transfer(sender, address(this), fee);
        }
        return amount.sub(fee);
    }
    
    receive() external payable {}
    
    function sendETHToFee(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function removeLimits() external onlyOwner {
        maxTx = _totalSupply;
        maxWalletInEffect = false;
        mktFeeForBuys = 3;
        mktFeeForSell = 3;
        totalFeeForBuys = 3;
        totalFeeForSells = 3;
    }
    
    function swapBackFeeToken(uint256 tAmount) private lockSwap {
        uint256 lpFeetokens = tAmount.mul(feeWeightLp).div(feeWeightTotal).div(2);
        uint256 tokensToSwap = tAmount.sub(lpFeetokens);

        swapTokensForETH(tokensToSwap);
        uint256 ethCA = address(this).balance;

        uint256 totalETHFee = feeWeightTotal.sub(feeWeightLp.div(2));
        
        uint256 amountETHLiquidity = ethCA.mul(feeWeightLp).div(totalETHFee).div(2);
        uint256 amountETHDevelopment = ethCA.mul(feeWeightDev).div(totalETHFee);
        uint256 amountETHMarketing = ethCA.sub(amountETHLiquidity).sub(amountETHDevelopment);

        if(amountETHMarketing > 0)
            sendETHToFee(feeReceiver1, amountETHMarketing);

        if(amountETHDevelopment > 0)
            sendETHToFee(feeReceiver2, amountETHDevelopment);
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
            if(!isExcludedMaxTx[sender] && !isExcludedMaxTx[recipient]) {
                require(amount <= maxTx, "Transfer amount exceeds the maxTx.");
            }            

            uint256 swapAmount = balanceOf(address(this));
            bool minimumSwap = swapAmount >= feeSwapThreshold;
            
            if (minimumSwap && !swapping && lpPairs[recipient] && swapFeeActivated && !isExcludedLimit[sender] && amount > feeSwapThreshold) 
            {
                if(maxTxInEffect)
                    swapAmount = feeSwapThreshold;
                swapBackFeeToken(swapAmount);    
            }

            uint256 finalAmount;                                         
            if (isExcludedLimit[sender] || isExcludedLimit[recipient]) {
                finalAmount = amount;
            } else {
                finalAmount = getFinalAmountWithoutFee(sender, recipient, amount);
            }
            if(maxWalletInEffect && !isExcludedMaxWallet[recipient])
                require(balanceOf(recipient).add(finalAmount) <= maxWalletAmount);

            uint256 amountToReduce = (!maxWalletInEffect && isExcludedLimit[sender]) ? amount.sub(finalAmount) : amount;
            _balances[sender] = _balances[sender].sub(amountToReduce, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(finalAmount);
            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }
}