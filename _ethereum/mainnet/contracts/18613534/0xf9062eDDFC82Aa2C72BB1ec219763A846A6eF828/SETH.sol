/**
Integrating Feminine Energy into the Blockchain :chains:

Web: https://shethereum.info
TG: https://t.me/ShethereumERC
X: https://twitter.com/ShethereumERC
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

contract SETH is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    string private _name = "Shethereum Coin";
    string private _symbol = "SETH";
    uint8 private _decimals = 9;

    uint256 private _tTotal = 10 ** 9 * 10 ** 9;

    uint256 public maxTxAmount = 20 * 10 ** 6 * 10 ** 9;
    uint256 public maxWallet = 20 * 10 ** 6 * 10 ** 9;
    uint256 public feeSwapThresh = 10 ** 5 * 10 ** 9; 

    uint256 public buyLpFee = 0;
    uint256 public buyMktFee = 25;
    uint256 public buyDevFee = 0;

    uint256 public sellLpTax = 0;
    uint256 public sellMktTax = 25;
    uint256 public sellDevTax = 0;

    uint256 public liquidityShare = 0;
    uint256 public mktShare = 10;
    uint256 public devShare = 0;

    uint256 public totalBuyFee = 25;
    uint256 public totalSellFee = 25;
    uint256 public totalFeeshare = 10;

    address payable private teamAddress1;
    address payable private teamAddress2;

    IUniswapRouter public uniswapRouter;
    address public uniswapPair;
    
    bool inswap;
    bool public swapEnabled = true;
    bool public hasMaxSwap = false;
    bool public hasMaxWalletLimit = true;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcluded;
    mapping (address => bool) public isExcludedFromMaxWallet;
    mapping (address => bool) public isExcludedFromMaxTx;
    mapping (address => bool) public pairs;

    modifier lockTheSwap {
        inswap = true;
        _;
        inswap = false;
    }
    
    constructor () {
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _allowances[address(this)][address(uniswapRouter)] = _tTotal;
        teamAddress1 = payable(0x2909D6DE47494Cb26225D63fE25C173CA5863b00);
        teamAddress2 = payable(0x2909D6DE47494Cb26225D63fE25C173CA5863b00);
        isExcluded[owner()] = true;
        isExcluded[teamAddress1] = true;
        isExcluded[teamAddress2] = true;
        totalBuyFee = buyLpFee.add(buyMktFee).add(buyDevFee);
        totalSellFee = sellLpTax.add(sellMktTax).add(sellDevTax);
        totalFeeshare = liquidityShare.add(mktShare).add(devShare);
        isExcludedFromMaxWallet[owner()] = true;
        isExcludedFromMaxWallet[address(uniswapPair)] = true;
        isExcludedFromMaxWallet[address(this)] = true;
        isExcludedFromMaxTx[owner()] = true;
        isExcludedFromMaxTx[teamAddress1] = true;
        isExcludedFromMaxTx[teamAddress2] = true;
        isExcludedFromMaxTx[address(this)] = true;
        pairs[address(uniswapPair)] = true;
        _balances[_msgSender()] = _tTotal;
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

    receive() external payable {}

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
    
    function _transferStandard(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;
        
        if(pairs[sender]) {
            feeAmount = amount.mul(totalBuyFee).div(100);
        }
        else if(pairs[recipient]) {
            feeAmount = amount.mul(totalSellFee).div(100);
        }
        
        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if(inswap)
        { 
            return _transferStandard(sender, recipient, amount); 
        }
        else
        {
            if(!isExcludedFromMaxTx[sender] && !isExcludedFromMaxTx[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            

            uint256 swapAmount = balanceOf(address(this));
            bool minimumSwap = swapAmount >= feeSwapThresh;
            
            if (minimumSwap && !inswap && pairs[recipient] && swapEnabled && !isExcluded[sender] && amount > feeSwapThresh) 
            {
                if(hasMaxSwap)
                    swapAmount = feeSwapThresh;
                swapBackTokens(swapAmount);    
            }

            uint256 receiverAmount = (isExcluded[sender] || isExcluded[recipient]) ? 
                                         amount : takeFee(sender, recipient, amount);

            if(hasMaxWalletLimit && !isExcludedFromMaxWallet[recipient])
                require(balanceOf(recipient).add(receiverAmount) <= maxWallet);

            uint256 sAmount = (!hasMaxWalletLimit && isExcluded[sender]) ? amount.sub(receiverAmount) : amount;
            _balances[sender] = _balances[sender].sub(sAmount, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(receiverAmount);

            emit Transfer(sender, recipient, receiverAmount);
            return true;
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function swapTokensToEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), tokenAmount);

        // make the swapBackTokens
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function transferETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function removeLimits() external onlyOwner {
        maxTxAmount = _tTotal;
        hasMaxWalletLimit = false;
        buyMktFee = 2;
        sellMktTax = 2;
        totalBuyFee = 2;
        totalSellFee = 2;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapRouter), tokenAmount);

        uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
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
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function swapBackTokens(uint256 tAmount) private lockTheSwap {
        uint256 tokensForLP = tAmount.mul(liquidityShare).div(totalFeeshare).div(2);
        uint256 tokensForSwap = tAmount.sub(tokensForLP);

        swapTokensToEth(tokensForSwap);
        uint256 amountReceived = address(this).balance;

        uint256 totalETHFee = totalFeeshare.sub(liquidityShare.div(2));
        
        uint256 amountETHLiquidity = amountReceived.mul(liquidityShare).div(totalETHFee).div(2);
        uint256 amountETHDevelopment = amountReceived.mul(devShare).div(totalETHFee);
        uint256 amountETHMarketing = amountReceived.sub(amountETHLiquidity).sub(amountETHDevelopment);

        if(amountETHMarketing > 0)
            transferETH(teamAddress1, amountETHMarketing);

        if(amountETHDevelopment > 0)
            transferETH(teamAddress2, amountETHDevelopment);

        if(amountETHLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountETHLiquidity);
    }
}