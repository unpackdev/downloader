// SPDX-License-Identifier: MIT

/*
Within the ever-evolving cosmos, a remarkable and inspiring future materializes at the juncture of artificial intelligence and blockchain technology.

Website: https://0xgenesis.org
Twitter: https://twitter.com/0XGENESIS_ERC
Telegram: https://t.me/ERC_0XGENESIS
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
interface IERC20 {
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
interface IRouterDex {
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
interface IFactoryDex {
    function createPair(address tokenA, address tokenB) external returns (address pairAddy);
}
contract GENESIS is Ownable, IERC20 {
    using SafeMath for uint256;
    string private constant _name = "0XGENESIS";
    string private constant _symbol = "0XGEN";
    uint8 private constant _decimals = 9;
    uint256 private _totalS = 10 ** 9 * (10 ** _decimals);
    
    IRouterDex dexRouter;
    address public pairAddy;
    bool private launched = false;
    bool private caSwapActive = true;
    uint256 private numCaSwaps;
    bool private inCASwap;
    uint256 caSwapCounter;
    uint256 private taxSwapMax = _totalS * 1000 / 100000;
    uint256 private taxSwapMin = _totalS * 10 / 100000;
    modifier reentrance {inCASwap = true; _; inCASwap = false;}
    uint256 private lpChargeFee = 0;
    uint256 private marketChargeFee = 0;
    uint256 private devChargeFee = 100;
    uint256 private burnChargeFee = 0;
    uint256 private buyersTax = 1000;
    uint256 private sellersTax = 1000;
    uint256 private transfersTax = 1000;
    uint256 private denominator = 10000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal devAddy = 0x8833A528C103eA366F5f7215cC424e9727A4B7F5; 
    address internal marketingAddy = 0x8833A528C103eA366F5f7215cC424e9727A4B7F5;
    address internal lpFeeAddy = 0x8833A528C103eA366F5f7215cC424e9727A4B7F5;
    uint256 public _maximTrxSize = ( _totalS * 300 ) / 10000;
    uint256 public _maximTransferSize = ( _totalS * 300 ) / 10000;
    uint256 public _maximWalletSize = ( _totalS * 300 ) / 10000;

    mapping (address => bool) public _isExcludedFromFee;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    constructor() Ownable(msg.sender) {
        IRouterDex _router = IRouterDex(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactoryDex(_router.factory()).createPair(address(this), _router.WETH());
        dexRouter = _router; pairAddy = _pair;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[lpFeeAddy] = true;
        _isExcludedFromFee[marketingAddy] = true;
        _isExcludedFromFee[devAddy] = true;
        _isExcludedFromFee[msg.sender] = true;
        _balances[msg.sender] = _totalS;
        emit Transfer(address(0), msg.sender, _totalS);
    }
    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _totalS.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function getOwner() external view override returns (address) { return owner; }
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function startTrading() external onlyOwner {launched = true;}
    function setMaxTxLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _totalS.mul(_buy).div(10000); uint256 newTransfer = _totalS.mul(_sell).div(10000); uint256 newWallet = _totalS.mul(_wallet).div(10000);
        _maximTrxSize = newTx; _maximTransferSize = newTransfer; _maximWalletSize = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function clearCADust(address _address, uint256 percent) external onlyOwner {
        uint256 _amount = IERC20(_address).balanceOf(address(this)).mul(percent).div(100);
        IERC20(_address).transfer(devAddy, _amount);
    }
    function swapTaxTokensAndSend(uint256 tokens) private reentrance {
        uint256 _denominator = (lpChargeFee.add(1).add(marketChargeFee).add(devChargeFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(lpChargeFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForFee(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(lpChargeFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(lpChargeFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketChargeFee);
        if(marketingAmt > 0){payable(marketingAddy).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devAddy).transfer(contractBalance);}
    }
    function swapTokensForFee(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
        if(!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient]){require(launched, "launched");}
        if(!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient] && recipient != address(pairAddy) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maximWalletSize, "Exceeds maximum wallet amount.");}
        if(sender != pairAddy){require(amount <= _maximTransferSize || _isExcludedFromFee[sender] || _isExcludedFromFee[recipient], "TX Limit Exceeded");}
        require(amount <= _maximTrxSize || _isExcludedFromFee[sender] || _isExcludedFromFee[recipient], "TX Limit Exceeded"); 
        if(recipient == pairAddy && !_isExcludedFromFee[sender]){numCaSwaps += uint256(1);}
        if(canFeeSwapOnCA(sender, recipient, amount)){swapTaxTokensAndSend(taxSwapMax); numCaSwaps = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !_isExcludedFromFee[sender] ? feeAmountToCharge(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function feeByType(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pairAddy){return sellersTax;}
        if(sender == pairAddy){return buyersTax;}
        return transfersTax;
    }
    function feeAmountToCharge(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (_isExcludedFromFee[recipient]) {return _maximTrxSize;}
        if(feeByType(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(feeByType(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnChargeFee > uint256(0) && feeByType(sender, recipient) > burnChargeFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnChargeFee));}
        return amount.sub(feeAmount);} return amount;
    }
    function canFeeSwapOnCA(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= taxSwapMin;
        bool aboveThreshold = balanceOf(address(this)) >= taxSwapMax;
        return !inCASwap && caSwapActive && launched && aboveMin && !_isExcludedFromFee[sender] && recipient == pairAddy && numCaSwaps >= caSwapCounter && aboveThreshold;
    }
    function setFee(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        lpChargeFee = _liquidity; marketChargeFee = _marketing; burnChargeFee = _burn; devChargeFee = _development; buyersTax = _total; sellersTax = _sell; transfersTax = _trans;
        require(buyersTax <= denominator.div(1) && sellersTax <= denominator.div(1) && transfersTax <= denominator.div(1), "buyersTax and sellersTax cannot be more than 20%");
    }
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpFeeAddy,
            block.timestamp);
    }
}