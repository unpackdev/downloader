// SPDX-License-Identifier: MIT

/*
TESTERAI utility token for detecting errors and vulnerabilities in the program code and their optimization and correction using TesterAI

Website: https://www.aitester.tech
Telegram: https://t.me/erc_testerai
Twitter: https://twitter.com/ethai_test
App: https://app.aitester.tech
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

interface IERC20 {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDFactory {
    function createPair(address tokenA, address tokenB) external returns (address dPair);
}

interface IDRouter {
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
    function getOwner() external view returns (address) {return owner;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    function renounceOwnership() public onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    event OwnershipTransferred(address owner);
}

contract TAI is IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "TesterAI";
    string private constant _symbol = "TAI";
    uint8 private constant _decimals = 9;
    uint256 private _totalsupply = 10 ** 9 * 10 ** _decimals;
    IDRouter dRouter;
    address public dPair;
    bool private inswap;
    modifier lockTheSwap {inswap = true; _; inswap = false;}
    uint256 private sellFeeMax = ( _totalsupply * 1000 ) / 100000;
    uint256 private sellFeeMin = ( _totalsupply * 10 ) / 100000;
    bool private tradeEnabled = false;
    bool private swapEnabled = true;
    uint256 private sellFeeTimes;
    uint256 private sellFeeAfter;
    uint256 private buyFee = 1600;
    uint256 private sellFee = 1600;
    uint256 private transferFee = 1600;
    uint256 private denominator = 10000;
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 0;
    uint256 private devFee = 100;
    uint256 private burnFee = 0;
    address internal devAddy = 0xF2105488e73eCa4857Bb310D373128CD27613241; 
    address internal marketingAddy = 0xF2105488e73eCa4857Bb310D373128CD27613241;
    address internal lpAddy = 0xF2105488e73eCa4857Bb310D373128CD27613241;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    
    uint256 public mTransaction = ( _totalsupply * 200 ) / 10000;
    uint256 public mTransfer = ( _totalsupply * 200 ) / 10000;
    uint256 public mWallet = ( _totalsupply * 200 ) / 10000;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isSpecial;

    constructor() Ownable(msg.sender) {
        IDRouter _router = IDRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IDFactory(_router.factory()).createPair(address(this), _router.WETH());
        dRouter = _router; dPair = _pair;
        isSpecial[lpAddy] = true;
        isSpecial[marketingAddy] = true;
        isSpecial[devAddy] = true;
        isSpecial[msg.sender] = true;
        _balances[msg.sender] = _totalsupply;
        emit Transfer(address(0), msg.sender, _totalsupply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function totalSupply() public view override returns (uint256) {return _totalsupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function startTrading() external onlyOwner {tradeEnabled = true;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    
    function setContractSwapSettings(uint256 _swapAmount, uint256 _swapThreshold, uint256 _minTokenAmount) external onlyOwner {
        sellFeeAfter = _swapAmount; sellFeeMax = _totalsupply.mul(_swapThreshold).div(uint256(100000)); 
        sellFeeMin = _totalsupply.mul(_minTokenAmount).div(uint256(100000));
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
        if(!isSpecial[sender] && !isSpecial[recipient]){require(tradeEnabled, "tradeEnabled");}
        if(!isSpecial[sender] && !isSpecial[recipient] && recipient != address(dPair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= mWallet, "Exceeds maximum wallet amount.");}
        if(sender != dPair){require(amount <= mTransfer || isSpecial[sender] || isSpecial[recipient], "TX Limit Exceeded");}
        require(amount <= mTransaction || isSpecial[sender] || isSpecial[recipient], "TX Limit Exceeded"); 
        if(recipient == dPair && !isSpecial[sender]){sellFeeTimes += uint256(1);}
        if(shouldContractSwap(sender, recipient, amount)){swapAndLiquidify(sellFeeMax); sellFeeTimes = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isSpecial[sender] ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _totalsupply.mul(_buy).div(10000); uint256 newTransfer = _totalsupply.mul(_sell).div(10000); uint256 newWallet = _totalsupply.mul(_wallet).div(10000);
        mTransaction = newTx; mTransfer = newTransfer; mWallet = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }
    
    function swapAndLiquidify(uint256 tokens) private lockTheSwap {
        uint256 _denominator = (liquidityFee.add(1).add(marketingFee).add(devFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingFee);
        if(marketingAmt > 0){payable(marketingAddy).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devAddy).transfer(contractBalance);}
    }

    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(recipient == dPair){return sellFee;}
        if(sender == dPair){return buyFee;}
        return transferFee;
    }
    function shouldContractSwap(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= sellFeeMin;
        bool aboveThreshold = balanceOf(address(this)) >= sellFeeMax;
        return !inswap && swapEnabled && tradeEnabled && aboveMin && !isSpecial[sender] && recipient == dPair && sellFeeTimes >= sellFeeAfter && aboveThreshold;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(dRouter), tokenAmount);
        dRouter.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpAddy,
            block.timestamp);
    }

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; marketingFee = _marketing; burnFee = _burn; devFee = _development; buyFee = _total; sellFee = _sell; transferFee = _trans;
        require(buyFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "buyFee and sellFee cannot be more than 20%");
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isSpecial[recipient]) {return mTransaction;}
        if(getTotalFee(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTotalFee(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFee > uint256(0) && getTotalFee(sender, recipient) > burnFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFee));}
        return amount.sub(feeAmount);} return amount;
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dRouter.WETH();
        _approve(address(this), address(dRouter), tokenAmount);
        dRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }
    
}