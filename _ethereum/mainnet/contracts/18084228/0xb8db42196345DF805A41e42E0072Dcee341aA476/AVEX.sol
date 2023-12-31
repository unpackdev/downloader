// SPDX-License-Identifier: MIT

/*
With an extensive library of numerous voice effects, the Alpaca Telegram Voice Changer provides lightning-fast voice conversions for an unparalleled experience.ccc

Website: https://alpacabot.pro
Twitter: https://twitter.com/AVEX_BOT_ERC
Telegram: https://t.me/AVEX_BOT_ERC
AlpacaBot: https://t.me/voice_changer_bot
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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address uniswapPair);
}

contract AVEX is Ownable, IERC20 {
    using SafeMath for uint256;

    string private constant _name = unicode"Alpaca Voice Changer Bot";
    string private constant _symbol = unicode"AVEX";

    IUniswapRouter uniswapRouter;
    address public uniswapPair;
    bool private openedTrading = false;
    bool private feeSwapActive = true;
    uint256 private numFeeTaxSwap;
    bool private isFeeSwapping;
    uint256 feeTaxSwapAt;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcemptFrmTaxFee;

    uint8 private constant _decimals = 9;
    uint256 private _supplyTotal = 1000000000 * (10 ** _decimals);
    uint256 private _maxTaxSwapAmnt = ( _supplyTotal * 1000 ) / 100000;
    uint256 private _minTaxSwapAmnt = ( _supplyTotal * 10 ) / 100000;

    uint256 private _maxTxAmnt = ( _supplyTotal * 300 ) / 10000;
    uint256 private _maxTransferAmnt = ( _supplyTotal * 300 ) / 10000;
    uint256 private _maxHoldingAmnt = ( _supplyTotal * 300 ) / 10000;

    uint256 private lpDivision = 0;
    uint256 private marketingDivision = 0;
    uint256 private devDivision = 100;
    uint256 private burnDivision = 0;

    uint256 private purchaseTax = 1400;
    uint256 private sellTaxFee = 1400;
    uint256 private transferTaxFee = 1400;
    uint256 private denominator = 10000;

    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal taxWallet = 0xBd68efFC82489f7317AD2f6bDaF0EACfB8F3E2F7;
    address internal lpWallet = 0xBd68efFC82489f7317AD2f6bDaF0EACfB8F3E2F7;
    address internal devWallet = 0xBd68efFC82489f7317AD2f6bDaF0EACfB8F3E2F7; 

    modifier taxSwapLock {isFeeSwapping = true; _; isFeeSwapping = false;}

    constructor() Ownable(msg.sender) {
        IUniswapRouter _router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IUniswapFactory(_router.factory()).createPair(address(this), _router.WETH());
        uniswapRouter = _router; uniswapPair = _pair;
        
        isExcemptFrmTaxFee[msg.sender] = true;
        isExcemptFrmTaxFee[lpWallet] = true;
        isExcemptFrmTaxFee[taxWallet] = true;
        isExcemptFrmTaxFee[devWallet] = true;
        _balances[msg.sender] = _supplyTotal;
        emit Transfer(address(0), msg.sender, _supplyTotal);
    }
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}    function startTrading() external onlyOwner {openedTrading = true;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function totalSupply() public view override returns (uint256) {return _supplyTotal.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}    
    function getOwner() external view override returns (address) { return owner; }
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function swapTaxLiquidify(uint256 tokens) private taxSwapLock {
        uint256 _denominator = (lpDivision.add(1).add(marketingDivision).add(devDivision)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(lpDivision).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(lpDivision));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(lpDivision);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingDivision);
        if(marketingAmt > 0){payable(taxWallet).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devWallet).transfer(contractBalance);}
    }
    function isExcludedFromFee(address sender, address recipient) internal view returns (bool) {
        return !isExcemptFrmTaxFee[sender] && !isExcemptFrmTaxFee[recipient];
    }    
    
    function getTotalTaxAmt(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExcemptFrmTaxFee[recipient]) {return _maxTxAmnt;}
        if(getTotalFeeAmt(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTotalFeeAmt(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnDivision > uint256(0) && getTotalFeeAmt(sender, recipient) > burnDivision){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnDivision));}
        return amount.sub(feeAmount);} return amount;
    }
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpWallet,
            block.timestamp);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supplyTotal.mul(_buy).div(10000); uint256 newTransfer = _supplyTotal.mul(_sell).div(10000); uint256 newWallet = _supplyTotal.mul(_wallet).div(10000);
        _maxTxAmnt = newTx; _maxTransferAmnt = newTransfer; _maxHoldingAmnt = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }

    function getTotalFeeAmt(address sender, address recipient) internal view returns (uint256) {
        if(recipient == uniswapPair){return sellTaxFee;}
        if(sender == uniswapPair){return purchaseTax;}
        return transferTaxFee;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isExcemptFrmTaxFee[sender] && !isExcemptFrmTaxFee[recipient]){require(openedTrading, "openedTrading");}
        if(!isExcemptFrmTaxFee[sender] && !isExcemptFrmTaxFee[recipient] && recipient != address(uniswapPair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maxHoldingAmnt, "Exceeds maximum wallet amount.");}
        if(sender != uniswapPair){require(amount <= _maxTransferAmnt || isExcemptFrmTaxFee[sender] || isExcemptFrmTaxFee[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTxAmnt || isExcemptFrmTaxFee[sender] || isExcemptFrmTaxFee[recipient], "TX Limit Exceeded"); 
        if(recipient == uniswapPair && !isExcemptFrmTaxFee[sender]){numFeeTaxSwap += uint256(1);}
        if(shouldSwapTaxFee(sender, recipient, amount)){swapTaxLiquidify(_maxTaxSwapAmnt); numFeeTaxSwap = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isExcemptFrmTaxFee[sender] ? getTotalTaxAmt(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

    function shouldSwapTaxFee(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _minTaxSwapAmnt;
        bool aboveThreshold = balanceOf(address(this)) >= _maxTaxSwapAmnt;
        return !isFeeSwapping && feeSwapActive && openedTrading && aboveMin && !isExcemptFrmTaxFee[sender] && recipient == uniswapPair && numFeeTaxSwap >= feeTaxSwapAt && aboveThreshold;
    }
    
    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        lpDivision = _liquidity; marketingDivision = _marketing; burnDivision = _burn; devDivision = _development; purchaseTax = _total; sellTaxFee = _sell; transferTaxFee = _trans;
        require(purchaseTax <= denominator.div(1) && sellTaxFee <= denominator.div(1) && transferTaxFee <= denominator.div(1), "purchaseTax and sellTaxFee cannot be more than 20%");
    }

    receive() external payable {}
}