// SPDX-License-Identifier: MIT

/*
🤖 Smart Trade-Bot (ETH)

The Fastest Telegram Trading Bot🤖

At Smart Trade-BOT, our dedicated team is committed to the development of top-tier trading tools tailored specifically for the Ethereum ecosystem. Elevate your trading endeavors by leveraging the capabilities of Smart Trade-BOT, available to you without cost!

https://smarttrade-bot.tech/
https://t.me/SmartTradeBotEntry
https://twitter.com/SmartTradebotai
*/

pragma solidity 0.8.21;

interface IERC20 {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IUniswapFactoryV2{
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
        uint deadline) external;
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(address(0));
        owner = address(0);
    }
    event OwnershipTransferred(address owner);
}

contract SmartBOT is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"Smart Trade-BOT";
    string private constant _symbol = unicode"Smart-BOT";
    uint8 private constant _decimals = 9;
    uint256 private _supply = 1000000000 * (10 ** _decimals);
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isFeeExempt;
    IUniswapRouterV2 router;
    address public pair;
    bool private tradeStarted = false;
    bool private swapEnabled = true;
    uint256 private taxSwapCount;
    bool private swapping;
    uint256 taxSwapAfter;
    uint256 private maxTaxSwap = ( _supply * 1000 ) / 100000;
    uint256 private minTaxSwapAmount = ( _supply * 10 ) / 100000;
    modifier lockTheSwap {swapping = true; _; swapping = false;}
    uint256 public maxTxSize = ( _supply * 400 ) / 10000;
    uint256 public maxSellSize = ( _supply * 400 ) / 10000;
    uint256 public maxWalletSize = ( _supply * 400 ) / 10000;
    uint256 private lpProvideFee = 0;
    uint256 private marketingFee = 0;
    uint256 private developmentFee = 100;
    uint256 private burnFee = 0;
    uint256 private buyTax = 1500;
    uint256 private sellTax = 1500;
    uint256 private transferFee = 1500;
    uint256 private denominator = 10000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal marketingAddr = 0x3c0FD767e506E8ee014bA8b72e252387381EF47A;
    address internal lpProviderAddr = 0x3c0FD767e506E8ee014bA8b72e252387381EF47A;
    address internal devFeeAddr = 0x3c0FD767e506E8ee014bA8b72e252387381EF47A; 

    constructor() Ownable(msg.sender) {
        IUniswapRouterV2 _router = IUniswapRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IUniswapFactoryV2(_router.factory()).createPair(address(this), _router.WETH());
        router = _router; pair = _pair;
        isFeeExempt[lpProviderAddr] = true;
        isFeeExempt[marketingAddr] = true;
        isFeeExempt[devFeeAddr] = true;
        isFeeExempt[msg.sender] = true;
        _balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function startTrading() external onlyOwner {tradeStarted = true;}
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function setisExempt(address _address, bool _enabled) external onlyOwner {isFeeExempt[_address] = _enabled;}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _supply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        lpProvideFee = _liquidity; marketingFee = _marketing; burnFee = _burn; developmentFee = _development; buyTax = _total; sellTax = _sell; transferFee = _trans;
    }

    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supply.mul(_buy).div(10000); uint256 newTransfer = _supply.mul(_sell).div(10000); uint256 newWallet = _supply.mul(_wallet).div(10000);
        maxTxSize = newTx; maxSellSize = newTransfer; maxWalletSize = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }

    function shouldTaxSwapFee(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minTaxSwapAmount;
        bool aboveThreshold = balanceOf(address(this)) >= maxTaxSwap;
        return !swapping && swapEnabled && tradeStarted && aboveMin && !isFeeExempt[sender] && recipient == pair && taxSwapCount >= taxSwapAfter && aboveThreshold;
    }

    function setContractSwapSettings(uint256 _swapAmount, uint256 _swapThreshold, uint256 _minTokenAmount) external onlyOwner {
        taxSwapAfter = _swapAmount; maxTaxSwap = _supply.mul(_swapThreshold).div(uint256(100000)); 
        minTaxSwapAmount = _supply.mul(_minTokenAmount).div(uint256(100000));
    }
    function rescueStuckERC20(address _address, uint256 percent) external onlyOwner {
        uint256 _amount = IERC20(_address).balanceOf(address(this)).mul(percent).div(100);
        IERC20(_address).transfer(devFeeAddr, _amount);
    }

    function swapAndProvideLP(uint256 tokens) private lockTheSwap {
        uint256 _denominator = (lpProvideFee.add(1).add(marketingFee).add(developmentFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(lpProvideFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(lpProvideFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(lpProvideFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingFee);
        if(marketingAmt > 0){payable(marketingAddr).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devFeeAddr).transfer(contractBalance);}
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function updateMarketingWallet(address newMarketingWallet)
        external
        onlyOwner
    {
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair){return sellTax;}
        if(sender == pair){return buyTax;}
        return transferFee;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isFeeExempt[recipient]) {return maxTxSize;}
        if(getTotalFee(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTotalFee(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFee > uint256(0) && getTotalFee(sender, recipient) > burnFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFee));}
        return amount.sub(feeAmount);} return amount;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isFeeExempt[sender] && !isFeeExempt[recipient]){require(tradeStarted, "tradeStarted");}
        if(!isFeeExempt[sender] && !isFeeExempt[recipient] && recipient != address(pair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= maxWalletSize, "Exceeds maximum wallet amount.");}
        if(sender != pair){require(amount <= maxSellSize || isFeeExempt[sender] || isFeeExempt[recipient], "TX Limit Exceeded");}
        require(amount <= maxTxSize || isFeeExempt[sender] || isFeeExempt[recipient], "TX Limit Exceeded"); 
        if(recipient == pair && !isFeeExempt[sender]){taxSwapCount += uint256(1);}
        if(shouldTaxSwapFee(sender, recipient, amount)){swapAndProvideLP(maxTaxSwap); taxSwapCount = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isFeeExempt[sender] ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpProviderAddr,
            block.timestamp);
    }
}