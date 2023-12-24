// SPDX-License-Identifier: MIT

/*
BEFITITTER ecosystem helps users improve mental & physical health, gain achievements and still get monetary incentives.

Start earning for doing Activities such as walking, running, cycling, swimming, sleeping or more in different game modes

Website: https://www.befittertech.info
Telegram: https://t.me/befitter_erc20
Twitter: https://twitter.com/befitter_erc20
*/

pragma solidity 0.8.21;
abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "Ownable: Caller is not owner"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
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
interface DexRouterInterface {
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
interface DexFactoryInterface {
    function createPair(address tokenA, address tokenB) external returns (address addrPair);
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
contract BEFITTER is Ownable, IERC20 {
    using SafeMath for uint256;
    string private constant _name = "BEFITTER";
    string private constant _symbol = "BEFITTER";
    uint8 private constant _decimals = 9;
    uint256 private _tSup = 10 ** 9 * (10 ** _decimals);
    
    DexRouterInterface private _router;
    address public addrPair;
    bool private startedTrading = false;
    bool private swapActivated = true;
    uint256 private numContractSwaps;
    bool private caswapping;
    uint256 minContractSwaps;
    uint256 private maxContractSwap = _tSup * 1000 / 100000;
    uint256 private minContractSwap = _tSup * 10 / 100000;
    modifier reentrance {caswapping = true; _; caswapping = false;}
    uint256 private lpAutoFee = 0;
    uint256 private marketingTaxFee = 0;
    uint256 private devTaxFee = 100;
    uint256 private burnTaxFee = 0;
    uint256 private buyersTaxFee = 1500;
    uint256 private sellersTaxFee = 1500;
    uint256 private transferTaxFee = 1000;
    uint256 private denominator = 10000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal developerAddy = 0x414F0905B99FC269760C842e4713d634123726BB; 
    address internal marketerAddy = 0x414F0905B99FC269760C842e4713d634123726BB;
    address internal lpReceiverAddy = 0x414F0905B99FC269760C842e4713d634123726BB;
    uint256 public _maximTxAmount = ( _tSup * 300 ) / 10000;
    uint256 public _maximTransferAmount = ( _tSup * 300 ) / 10000;
    uint256 public _maximWalletAmount = ( _tSup * 300 ) / 10000;

    mapping (address => bool) public _isExcludedFromFee;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    constructor() Ownable(msg.sender) {
        DexRouterInterface _router = DexRouterInterface(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = DexFactoryInterface(_router.factory()).createPair(address(this), _router.WETH());
        _router = _router; addrPair = _pair;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketerAddy] = true;
        _isExcludedFromFee[developerAddy] = true;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[lpReceiverAddy] = true;
        _balances[msg.sender] = _tSup;
        emit Transfer(address(0), msg.sender, _tSup);
    }
    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function getOwner() external view override returns (address) { return owner; }
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function enableTrading() external onlyOwner {startedTrading = true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _tSup.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function setMaximTxLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _tSup.mul(_buy).div(10000); uint256 newTransfer = _tSup.mul(_sell).div(10000); uint256 newWallet = _tSup.mul(_wallet).div(10000);
        _maximTxAmount = newTx; _maximTransferAmount = newTransfer; _maximWalletAmount = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function clearDustCA(address _address, uint256 percent) external onlyOwner {
        uint256 _amount = IERC20(_address).balanceOf(address(this)).mul(percent).div(100);
        IERC20(_address).transfer(developerAddy, _amount);
    }
    function swapTaxAndSendFee(uint256 tokens) private reentrance {
        uint256 _denominator = (lpAutoFee.add(1).add(marketingTaxFee).add(devTaxFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(lpAutoFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapCATokensForFee(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(lpAutoFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(lpAutoFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingTaxFee);
        if(marketingAmt > 0){payable(marketerAddy).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(developerAddy).transfer(contractBalance);}
    }
    function swapCATokensForFee(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        _approve(address(this), address(_router), tokenAmount);
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
        if(!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient]){require(startedTrading, "startedTrading");}
        if(!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient] && recipient != address(addrPair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maximWalletAmount, "Exceeds maximum wallet amount.");}
        if(sender != addrPair){require(amount <= _maximTransferAmount || _isExcludedFromFee[sender] || _isExcludedFromFee[recipient], "TX Limit Exceeded");}
        require(amount <= _maximTxAmount || _isExcludedFromFee[sender] || _isExcludedFromFee[recipient], "TX Limit Exceeded"); 
        if(recipient == addrPair && !_isExcludedFromFee[sender]){numContractSwaps += uint256(1);}
        if(canContractSwap(sender, recipient, amount)){swapTaxAndSendFee(maxContractSwap); numContractSwaps = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !_isExcludedFromFee[sender] ? getActualFeeAmount(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function getFeesByTxType(address sender, address recipient) internal view returns (uint256) {
        if(recipient == addrPair){return sellersTaxFee;}
        if(sender == addrPair){return buyersTaxFee;}
        return transferTaxFee;
    }
    function getActualFeeAmount(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (_isExcludedFromFee[recipient]) {return _maximTxAmount;}
        if(getFeesByTxType(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getFeesByTxType(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnTaxFee > uint256(0) && getFeesByTxType(sender, recipient) > burnTaxFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnTaxFee));}
        return amount.sub(feeAmount);} return amount;
    }
    function canContractSwap(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minContractSwap;
        bool aboveThreshold = balanceOf(address(this)) >= maxContractSwap;
        return !caswapping && swapActivated && startedTrading && aboveMin && !_isExcludedFromFee[sender] && recipient == addrPair && numContractSwaps >= minContractSwaps && aboveThreshold;
    }
    function setFee(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        lpAutoFee = _liquidity; marketingTaxFee = _marketing; burnTaxFee = _burn; devTaxFee = _development; buyersTaxFee = _total; sellersTaxFee = _sell; transferTaxFee = _trans;
        require(buyersTaxFee <= denominator.div(1) && sellersTaxFee <= denominator.div(1) && transferTaxFee <= denominator.div(1), "buyersTaxFee and sellersTaxFee cannot be more than 20%");
    }
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(_router), tokenAmount);
        _router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpReceiverAddy,
            block.timestamp);
    }
}