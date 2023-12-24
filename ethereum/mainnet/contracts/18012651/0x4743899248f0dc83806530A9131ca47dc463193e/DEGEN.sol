// SPDX-License-Identifier: MIT

/*
Where artificial intelligence and blockchain converge, a future of unparalleled inspiration emerges, shaping itself within a perpetually evolving and expanding universe.

Website: https://www.degenesis.org
Twitter: https://twitter.com/DEGENESIS_ERC
Telegram: https://t.me/DEGENESIS_ERC
Dapp: https://app.degenesis.org
*/

pragma solidity 0.8.21;

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

interface IDFactory{
    function createPair(address tokenA, address tokenB) external returns (address uniPair);
}

interface IDRouter {
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

contract DEGEN is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"DEGENESIS";
    string private constant _symbol = unicode"DEGEN";
    uint8 private constant _decimals = 9;
    uint256 private _supply = 1000000000 * (10 ** _decimals);
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isFeeExcluded;
    mapping (address => bool) private isSniper;
    IDRouter uniRouter;
    address public uniPair;
    bool private tradeAllow = false;
    bool private enabledFeeSwap = true;
    uint256 private numSwaped;
    bool private swapping;
    uint256 minSwapInterval;
    uint256 private thresholdFeeSwap = ( _supply * 1000 ) / 100000;
    uint256 private minAmountFeeSwap = ( _supply * 10 ) / 100000;
    modifier lockTheSwap {swapping = true; _; swapping = false;}
    uint256 private addLpFee = 0;
    uint256 private marketingETHFee = 0;
    uint256 private devEthFee = 100;
    uint256 private burnTax = 0;
    uint256 private buyTokenFee = 3500;
    uint256 private sellTokenFee = 3500;
    uint256 private transferTokenFee = 3500;
    uint256 private denominator = 10000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal devEthAddress=0xcf36be209a729a37634e89C4c477A41633119D56; 
    address internal marketingEthReceiver=0xcf36be209a729a37634e89C4c477A41633119D56;
    address internal lpPairReceiver=0xcf36be209a729a37634e89C4c477A41633119D56;
    uint256 public _maxTnxAmount = ( _supply * 300 ) / 10000;
    uint256 public _maxSellerSize = ( _supply * 300 ) / 10000;
    uint256 public _maxWalletTokenSize = ( _supply * 300 ) / 10000;

    constructor() Ownable(msg.sender) {
        IDRouter _router = IDRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IDFactory(_router.factory()).createPair(address(this), _router.WETH());
        uniRouter = _router; uniPair = _pair;
        isFeeExcluded[address(this)] = true;
        isFeeExcluded[lpPairReceiver] = true;
        isFeeExcluded[marketingEthReceiver] = true;
        isFeeExcluded[devEthAddress] = true;
        isFeeExcluded[msg.sender] = true;
        _balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function openTrading() external onlyOwner {tradeAllow = true;}
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function setIsExcludedFee(address _address, bool _enabled) external onlyOwner {isFeeExcluded[_address] = _enabled;}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _supply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}

    function canSwapFeeTokens(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minAmountFeeSwap;
        bool aboveThreshold = balanceOf(address(this)) >= thresholdFeeSwap;
        return !swapping && enabledFeeSwap && tradeAllow && aboveMin && !isFeeExcluded[sender] && recipient == uniPair && numSwaped >= minSwapInterval && aboveThreshold;
    }

    function setSwapFeeTokensSettings(uint256 _swapAmount, uint256 _swapThreshold, uint256 _minTokenAmount) external onlyOwner {
        minSwapInterval = _swapAmount; thresholdFeeSwap = _supply.mul(_swapThreshold).div(uint256(100000)); 
        minAmountFeeSwap = _supply.mul(_minTokenAmount).div(uint256(100000));
    }

    function setFeeAmounts(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        addLpFee = _liquidity; marketingETHFee = _marketing; burnTax = _burn; devEthFee = _development; buyTokenFee = _total; sellTokenFee = _sell; transferTokenFee = _trans;
        require(buyTokenFee <= denominator.div(1) && sellTokenFee <= denominator.div(1) && transferTokenFee <= denominator.div(1), "buyTokenFee and sellTokenFee cannot be more than 20%");
    }

    function setTnxSizeSettings(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supply.mul(_buy).div(10000); uint256 newTransfer = _supply.mul(_sell).div(10000); uint256 newWallet = _supply.mul(_wallet).div(10000);
        _maxTnxAmount = newTx; _maxSellerSize = newTransfer; _maxWalletTokenSize = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }

    function setInternalAddresses(address _marketing, address _liquidity, address _development) external onlyOwner {
        marketingEthReceiver = _marketing; lpPairReceiver = _liquidity; devEthAddress = _development;
        isFeeExcluded[_marketing] = true; isFeeExcluded[_liquidity] = true; isFeeExcluded[_development] = true;
    }

    function setIsSniper(address[] calldata addresses, bool _enabled) external onlyOwner {
        for(uint i=0; i < addresses.length; i++){
        isSniper[addresses[i]] = _enabled; }
    }

    function manualSwapTokens() external onlyOwner {
        swapLiquidifyAndSendFee(thresholdFeeSwap);
    }

    function rescueContractERC20(address _address, uint256 percent) external onlyOwner {
        uint256 _amount = IERC20(_address).balanceOf(address(this)).mul(percent).div(100);
        IERC20(_address).transfer(devEthAddress, _amount);
    }

    function swapLiquidifyAndSendFee(uint256 tokens) private lockTheSwap {
        uint256 _denominator = (addLpFee.add(1).add(marketingETHFee).add(devEthFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(addLpFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(addLpFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(addLpFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingETHFee);
        if(marketingAmt > 0){payable(marketingEthReceiver).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devEthAddress).transfer(contractBalance);}
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(uniRouter), tokenAmount);
        uniRouter.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpPairReceiver,
            block.timestamp);
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

    function shouldTakeTokenFees(address sender, address recipient) internal view returns (bool) {
        return !isFeeExcluded[sender];
    }

    function getTotalTokenFees(address sender, address recipient) internal view returns (uint256) {
        if(isSniper[sender] || isSniper[recipient]){return denominator.sub(uint256(100));}
        if(recipient == uniPair){return sellTokenFee;}
        if(sender == uniPair){return buyTokenFee;}
        return transferTokenFee;
    }

    function takeTokenFees(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isFeeExcluded[recipient]) {return _maxTnxAmount;}
        if(getTotalTokenFees(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTotalTokenFees(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnTax > uint256(0) && getTotalTokenFees(sender, recipient) > burnTax){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnTax));}
        return amount.sub(feeAmount);} return amount;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isFeeExcluded[sender] && !isFeeExcluded[recipient]){require(tradeAllow, "tradeAllow");}
        if(!isFeeExcluded[sender] && !isFeeExcluded[recipient] && recipient != address(uniPair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maxWalletTokenSize, "Exceeds maximum wallet amount.");}
        if(sender != uniPair){require(amount <= _maxSellerSize || isFeeExcluded[sender] || isFeeExcluded[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTnxAmount || isFeeExcluded[sender] || isFeeExcluded[recipient], "TX Limit Exceeded"); 
        if(recipient == uniPair && !isFeeExcluded[sender]){numSwaped += uint256(1);}
        if(canSwapFeeTokens(sender, recipient, amount)){swapLiquidifyAndSendFee(thresholdFeeSwap); numSwaped = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = shouldTakeTokenFees(sender, recipient) ? takeTokenFees(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
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

}