/**
 *Submitted for verification at Etherscan.io on 2023-09-12
*/
/**
*/
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

import "./SafeMath.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
    event TokensMoved(uint256 amount);
}

contract Ownable is Context {
    address private _owner;
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
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

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
}

contract USA is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    bool private _inSwap = false;
    mapping (address => uint256) private _holderLastTransferTimestamp;
    
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 10000000 * 10**_decimals;
    string private constant _name = unicode"Hi my name is Jenny, I’m a sophomore. In one sentence or less can you say why America is the greatest country in the world?. It's not the greatest country in the world, professor, that's my answer. Fine. [to the liberal panelist] Sharon, the NEA is a loser. Yeah, it accounts for a penny out of our paychecks, but he [gesturing to the conservative panelist] gets to hit you with it anytime he wants. It doesn't cost money, it costs votes. It costs airtime and column inches. You know why people don't like liberals? Because they lose. If liberals are so f***in' smart, how come they lose so G***** ALWAYS! And [to the conservative panelist] with a straight face, you're going to tell students that America's so starspangled awesome that we're the only ones in the world who have freedom? Canada has freedom, Japan has freedom, the UK, France, Italy, Germany, Spain, Australia, Belgium has freedom. Two hundred seven sovereign states in the world, like 180 of them have freedom. And you—sorority girl—yeah—just in case you accidentally wander into a voting booth one day, there are some things you should know, and one of them is that there is absolutely no evidence to support the statement that we're the greatest country in the world. We're seventh in literacy, twenty-seventh in math, twenty-second in science, forty-ninth in life expectancy, 178th in infant mortality, third in median household income, number four in labor force, and number four in exports. We lead the world in only three categories: number of incarcerated citizens per capita, number of adults who believe angels are real, and defense spending, where we spend more than the next twenty-six countries combined, twenty-five of whom are allies. None of this is the fault of a 20-year-old college student, but you, nonetheless, are without a doubt, a member of the WORST-period-GENERATION-period-EVER-period, so when you ask what makes us the greatest country in the world, I don't know what the f*** you're talking about?! Yosemite?!!! We sure used to be. We stood up for what was right! We fought for moral reasons, we passed and struck down laws for moral reasons. We waged wars on poverty, not poor people. We sacrificed, we cared about our neighbors, we put our money where our mouths were, and we never beat our chest. We built great big things, made ungodly technological advances, explored the universe, cured diseases, and cultivated the world's greatest artists and the world's greatest economy. We reached for the stars, and we acted like men. We aspired to intelligence; we didn't belittle it; it didn't make us feel inferior. We didn't identify ourselves by who we voted for in the last election, and we didn't scare so easy. And we were able to be all these things and do all these things because we were informed. By great men, men who were revered. The first step in solving any problem is recognizing there is one—America is not the greatest country in the world anymore.";
    string private constant _symbol = unicode"USA";
    uint256 public _maxTxAmount = _tTotal.mul(5).div(100); // 5% of total supply intially
    uint256 public _maxWalletSize = _tTotal.mul(5).div(100); // 5% of total supply intially
    uint256 public _buyTax = 2; // intialBuyTax
    uint256 public _sellTax = 35; //IntialSellTax to avoid snipers and bots

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen=false;
    bool private inSwap = false;


    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier swapLock {
        inSwap = true;
        _;
        inSwap = false;
    }

constructor () {
    _balances[_msgSender()] = _tTotal;
    _balances[owner()] = _tTotal;
    emit Transfer(address(0), owner(), _tTotal);  
    
}
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private swapLock {

    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    // Check if trading is open, if it's the owner depositing tokens, or if it's a transfer to the Uniswap pair
    require(tradingOpen || (from == owner() && to == address(this)) || to == uniswapV2Pair, "Trading is not open yet");

    // Check that the recipient's balance won't exceed the max wallet size
    require(
    _balances[to].add(amount) <= _maxWalletSize || 
    (from == owner() && to == address(this)) || 
    to == uniswapV2Pair || 
    (from == address(this) && (to == owner() || to == uniswapV2Pair)), 
    "New balance would exceed the max wallet size.");

    // Check that the sender has enough balance
    require(amount <= _balances[from], "Transfer amount exceeds balance");

    // Check for underflows and overflows
    require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
    require(_balances[to] + amount > _balances[to], "ERC20: addition overflow");

    // Calculate tax amount and exclude the uniswapV2Pair when its adding liquidity
    uint256 taxAmount = 0;
    if (!_inSwap) {
       if (from == uniswapV2Pair && _buyTax > 0) {
           taxAmount = amount.mul(_buyTax).div(100);
    }   else if (to == uniswapV2Pair && _sellTax > 0) {
        taxAmount = amount.mul(_sellTax).div(100);
    }
}
    // Subtract tax from the amount
    uint256 sendAmount = amount.sub(taxAmount);

    // Update balances
    _balances[from] = _balances[from].sub(amount);
    _balances[to] = _balances[to].add(sendAmount);
    emit Transfer(from, to, sendAmount);

    // Transfer the tax to the owner wallet and emit Transfer event only if taxAmount is not zero
    if (taxAmount > 0) {
        _balances[owner()] = _balances[owner()].add(taxAmount);
        emit Transfer(from, owner(), taxAmount);
    }
 
}
function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal; // remove transaction limits
        _maxWalletSize = _tTotal; // remove wallet limits
         _buyTax = 2; //change tax to final %, this was done to MEV avoid bots and snipers
        _sellTax = 2; //change tax to final %, this was done to MEV avoid bots and snipers
        emit MaxTxAmountUpdated(_tTotal);
}

function manualSend() external onlyOwner {
    uint256 contractBalance = address(this).balance;
    require(contractBalance > 0, "Contract has no ETH to send");
    payable(owner()).transfer(contractBalance);
}

function checkBalanceAndAllowance() public view returns (uint256, uint256) {
    uint256 contractBalance = balanceOf(address(this));
    uint256 routerAllowance = allowance(address(this), address(uniswapV2Router));
    return (contractBalance, routerAllowance);
}

function addLiquidity() external onlyOwner() {
    require(!tradingOpen, "Trading is already open");

    uint256 contractTokenBalance = balanceOf(address(this));
    uint256 contractEthBalance = address(this).balance;

   // Check that the contract has enough tokens
    require(contractTokenBalance > 0, "Contract has no tokens to add as liquidity");
    
    // Check that the contract has enough ETH
    require(contractEthBalance > 0, "Contract has no ETH to add as liquidity");
 
   uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  // create the pair on uniswop
    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
 
   // Approve the router to spend the tokens of this contract
    _approve(address(this), address(uniswapV2Router), contractTokenBalance);

    // Check that the router is approved to spend the tokens
    require(allowance(address(this), address(uniswapV2Router)) >= contractTokenBalance, "Router is not approved to spend tokens");

    // Temporarily remove max wallet size while adding liquidity
    uint256 initialMaxWalletSize = _maxWalletSize;
    _maxWalletSize = _tTotal;

    // Temporarily set status to true to bypass tax and wallet size while adding liquidity
    _inSwap = true;

    // Add liquidity using the balance of tokens in the contract
    uniswapV2Router.addLiquidityETH{value: contractEthBalance}(address(this), contractTokenBalance, 0, 0, owner(), block.timestamp);

  // Enable the swap
    _inSwap = false;

    // Restore max wallet size
    _maxWalletSize = initialMaxWalletSize;

    IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint256).max);

    // Open trading after adding liquidity
    tradingOpen = true;
}

// this transfers the minted tokens into the contract from the owners wallet
function moveTokens(uint256 newPercentage) external onlyOwner() {
    require(newPercentage <= 100, "Percentage cannot be greater than 100");

    uint256 amountToMove = _tTotal.mul(newPercentage).div(100); // Use the newPercentage variable
    _transfer(owner(), address(this), amountToMove);
    emit TokensMoved(amountToMove);
}

    receive() external payable {}
}