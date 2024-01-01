/**
Tired of the endless dog and frog memes? Tired of the (insert name) Pepe tokens or the Pepe (Insert Name) Tokens. Well the frogs have had their run and its time for the most popular fictional character to take his place as the King of the Memes!

Superman will be using his Heat Vision to burn down the supply and make this the most popular and most successful Meme token on the market!

$SUP is being launched by the team at Krypton Calls Investing, LLC. We will be using not only Krypton Calls and Squid Grow Joes YouTube Channel, but our vast connections to send $SUP far past the moon and back to Krypton!

Website: https://superfinance.finance
Telegram: https://t.me/superfi_erc20
Twitter: https://twitter.com/superfi_erc
Dapp: https://app.superfinance.finance
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

contract SUP is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    string private _name = "SuperMan Coin";
    string private _symbol = "SUP";
    uint8 private _decimals = 9;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public excludedFromAllLimits;
    mapping (address => bool) public excludedFromMaxWallet;
    mapping (address => bool) public excludedFromMaxTx;
    mapping (address => bool) public isPair;

    uint256 private _tTotal = 10 ** 9 * 10 ** 9;

    uint256 public maxTxAmount = 12 * 10 ** 6 * 10 ** 9;
    uint256 public maxWalletSize = 12 * 10 ** 6 * 10 ** 9;
    uint256 public swapThreshold = 10 ** 5 * 10 ** 9; 

    uint256 public lpBuyFee = 0;
    uint256 public marketingBuyFee = 28;
    uint256 public devBuyFee = 0;

    uint256 public lpSellFee = 0;
    uint256 public marketingSellFee = 28;
    uint256 public devSellFee = 0;

    uint256 public lpShare = 0;
    uint256 public marketingShare = 10;
    uint256 public devShare = 0;

    uint256 public tBuyFee = 28;
    uint256 public tSellFee = 28;
    uint256 public totalShare = 10;

    address payable private mktAddress;
    address payable private devAddress;

    IUniswapRouter public router;
    address public pairAddress;
    
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
        pairAddress = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        router = _uniswapV2Router;
        _allowances[address(this)][address(router)] = _tTotal;
        mktAddress = payable(0xA5d4d526156E1466AcD0368a64Eb1333568D038B);
        devAddress = payable(0xA5d4d526156E1466AcD0368a64Eb1333568D038B);
        excludedFromAllLimits[owner()] = true;
        excludedFromAllLimits[mktAddress] = true;
        excludedFromAllLimits[devAddress] = true;
        tBuyFee = lpBuyFee.add(marketingBuyFee).add(devBuyFee);
        tSellFee = lpSellFee.add(marketingSellFee).add(devSellFee);
        totalShare = lpShare.add(marketingShare).add(devShare);
        excludedFromMaxWallet[owner()] = true;
        excludedFromMaxWallet[address(pairAddress)] = true;
        excludedFromMaxWallet[address(this)] = true;
        excludedFromMaxTx[owner()] = true;
        excludedFromMaxTx[mktAddress] = true;
        excludedFromMaxTx[devAddress] = true;
        excludedFromMaxTx[address(this)] = true;
        isPair[address(pairAddress)] = true;
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
    
    function _transferBasic(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function chargeFees(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;
        
        if(isPair[sender]) {
            feeAmount = amount.mul(tBuyFee).div(100);
        }
        else if(isPair[recipient]) {
            feeAmount = amount.mul(tSellFee).div(100);
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
            return _transferBasic(sender, recipient, amount); 
        }
        else
        {
            if(!excludedFromMaxTx[sender] && !excludedFromMaxTx[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            

            uint256 swapAmount = balanceOf(address(this));
            bool minimumSwap = swapAmount >= swapThreshold;
            
            if (minimumSwap && !_swapping && isPair[recipient] && swapActive && !excludedFromAllLimits[sender] && amount > swapThreshold) 
            {
                if(maxSwapActive)
                    swapAmount = swapThreshold;
                swapBack(swapAmount);    
            }

            uint256 receiverAmount = (excludedFromAllLimits[sender] || excludedFromAllLimits[recipient]) ? 
                                         amount : chargeFees(sender, recipient, amount);

            if(maxWalletActive && !excludedFromMaxWallet[recipient])
                require(balanceOf(recipient).add(receiverAmount) <= maxWalletSize);

            uint256 sAmount = (!maxWalletActive && excludedFromAllLimits[sender]) ? amount.sub(receiverAmount) : amount;
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
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swapBack
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function sendETHToFee(address payable recipient, uint256 amount) private {
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
        marketingBuyFee = 2;
        marketingSellFee = 2;
        tBuyFee = 2;
        tSellFee = 2;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(router), tokenAmount);

        router.addLiquidityETH{value: ethAmount}(
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
        uint256 tokensForLP = tAmount.mul(lpShare).div(totalShare).div(2);
        uint256 tokensForSwap = tAmount.sub(tokensForLP);

        swapTokensToEth(tokensForSwap);
        uint256 amountReceived = address(this).balance;

        uint256 totalETHFee = totalShare.sub(lpShare.div(2));
        
        uint256 amountETHLiquidity = amountReceived.mul(lpShare).div(totalETHFee).div(2);
        uint256 amountETHDevelopment = amountReceived.mul(devShare).div(totalETHFee);
        uint256 amountETHMarketing = amountReceived.sub(amountETHLiquidity).sub(amountETHDevelopment);

        if(amountETHMarketing > 0)
            sendETHToFee(mktAddress, amountETHMarketing);

        if(amountETHDevelopment > 0)
            sendETHToFee(devAddress, amountETHDevelopment);

        if(amountETHLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountETHLiquidity);
    }
}