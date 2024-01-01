// SPDX-License-Identifier: MIT

/*
Connecting decentralized insurance
Individual protection, collective growth

Website: https://www.bunion.tech
Dapp: https://app.bunion.tech
Telegram: https://t.me/bunion_erc
Twitter: https://twitter.com/bunion_erc
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
abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function renounceOwnership() public onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}
interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pairAddress);
}

contract BRIGHT is IERC20Standard, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"BrighUnion";
    string private constant _symbol = unicode"BRIGHT";
    uint8 private constant _decimals = 9;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 private _tTotals = 1000000000 * (10 ** _decimals);
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private isSpecial;
    uint256 public maxTxAmt = ( _tTotals * 200 ) / 10000;
    uint256 public maxBuy = ( _tTotals * 200 ) / 10000;
    uint256 public maxWallet = ( _tTotals * 200 ) / 10000;

    uint256 private countOnSwap;
    bool private swapping;
    uint256 swapAt;
    IDexRouter router;
    address public pairAddress;
    bool private tradeOpened = false;
    bool private swapEnabled = true;
    uint256 private swapMax = ( _tTotals * 1000 ) / 100000;
    uint256 private swapMin = ( _tTotals * 10 ) / 100000;
    modifier lockTheSwap {swapping = true; _; swapping = false;}
    uint256 private lpRate = 0;
    uint256 private mktDivision = 0;
    uint256 private devDivision = 100;
    uint256 private burnDivision = 0;
    uint256 private buyTax = 1400;
    uint256 private sellTax = 2400;
    uint256 private transferTax = 1200;
    uint256 private denominator = 10000;
    address internal devAddy = 0x87E3c1c4a693A534548EE35D9A868347a745a0eC; 
    address internal mktAddy = 0x87E3c1c4a693A534548EE35D9A868347a745a0eC;
    address internal lpAddy = 0x87E3c1c4a693A534548EE35D9A868347a745a0eC;

    constructor() Ownable(msg.sender) {
        IDexRouter _router = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IDexFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router; pairAddress = _pair;
        isSpecial[lpAddy] = true;
        isSpecial[mktAddy] = true;
        isSpecial[devAddy] = true;
        isSpecial[msg.sender] = true;
        _balances[msg.sender] = _tTotals;
        emit Transfer(address(0), msg.sender, _tTotals);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _tTotals.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function decimals() public pure returns (uint8) {return _decimals;}    
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function getOwner() external view override returns (address) { return owner; }
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isSpecial[sender] && !isSpecial[recipient]){require(tradeOpened, "tradeOpened");}
        if(!isSpecial[sender] && !isSpecial[recipient] && recipient != address(pairAddress) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= maxWallet, "Exceeds maximum wallet amount.");}
        if(sender != pairAddress){require(amount <= maxBuy || isSpecial[sender] || isSpecial[recipient], "TX Limit Exceeded");}
        require(amount <= maxTxAmt || isSpecial[sender] || isSpecial[recipient], "TX Limit Exceeded"); 
        if(recipient == pairAddress && !isSpecial[sender]){countOnSwap += uint256(1);}
        if(canSwapTax(sender, recipient, amount)){swapBackToken(swapMax); countOnSwap = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isSpecial[sender] ? getAmountAfterFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    function canSwapTax(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= swapMin;
        bool aboveThreshold = balanceOf(address(this)) >= swapMax;
        return !swapping && swapEnabled && tradeOpened && aboveMin && !isSpecial[sender] && recipient == pairAddress && countOnSwap >= swapAt && aboveThreshold;
    }
    function swapBackToken(uint256 tokens) private lockTheSwap {
        uint256 _denominator = (lpRate.add(1).add(mktDivision).add(devDivision)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(lpRate).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokens(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(lpRate));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(lpRate);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(mktDivision);
        if(marketingAmt > 0){payable(mktAddy).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devAddy).transfer(contractBalance);}
    }
    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _tTotals.mul(_buy).div(10000); uint256 newTransfer = _tTotals.mul(_sell).div(10000); uint256 newWallet = _tTotals.mul(_wallet).div(10000);
        maxTxAmt = newTx; maxBuy = newTransfer; maxWallet = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }
    function getAmountAfterFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isSpecial[recipient]) {return maxTxAmt;}
        if(getTransferFees(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTransferFees(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnDivision > uint256(0) && getTransferFees(sender, recipient) > burnDivision){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnDivision));}
        return amount.sub(feeAmount);} return amount;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _devAddresselopment, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        lpRate = _liquidity; mktDivision = _marketing; burnDivision = _burn; devDivision = _devAddresselopment; buyTax = _total; sellTax = _sell; transferTax = _trans;
        require(buyTax <= denominator.div(1) && sellTax <= denominator.div(1) && transferTax <= denominator.div(1), "buyTax and sellTax cannot be more than 20%");
    }
    function swapTokens(uint256 tokenAmount) private {
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
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpAddy,
            block.timestamp);
    }
    function getTransferFees(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pairAddress){return sellTax;}
        if(sender == pairAddress){return buyTax;}
        return transferTax;
    }
    function startTrading() external onlyOwner {tradeOpened = true;}
}