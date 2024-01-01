// SPDX-License-Identifier: MIT

/*
Best Smoothy Trading Platform!

Website: https://smoothy.cc
Telegram: https://t.me/smoothy_erc
Twitter: https://twitter.com/smoothy_erc
*/

pragma solidity 0.8.19;

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
interface IERC20Simple {
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
    function renounceOwnership() public onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}
interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address uniswapPair);
}

contract Smoothy is IERC20Simple, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"SMOOTHY";
    string private constant _symbol = unicode"Smoothy";
    uint8 private constant _decimals = 9;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 private _supplyTotal = 1000000000 * (10 ** _decimals);
    uint256 private swapTimes;
    bool private swapping;
    uint256 swapAfter;
    IRouter router;
    address public uniswapPair;
    bool private tradeStarted = false;
    bool private swapEnabled = true;
    uint256 private feeSwapMax = ( _supplyTotal * 1000 ) / 100000;
    uint256 private feeSwapMin = ( _supplyTotal * 10 ) / 100000;
    modifier lockSwap {swapping = true; _; swapping = false;}
    uint256 private lpDynamicRate = 0;
    uint256 private marketingDivide = 0;
    uint256 private devDivide = 100;
    uint256 private burnDivide = 0;
    uint256 private buyFee = 1200;
    uint256 private sellFee = 2400;
    uint256 private transferFee = 1200;
    uint256 private denominator = 10000;
    address internal devAddress = 0xDcBB18fF7d9b63df71fAE30010b527304C0ad13D; 
    address internal marketingAddr = 0xDcBB18fF7d9b63df71fAE30010b527304C0ad13D;
    address internal lpTokenAddress = 0xDcBB18fF7d9b63df71fAE30010b527304C0ad13D;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFees;
    uint256 public maxTxSz = ( _supplyTotal * 200 ) / 10000;
    uint256 public maxBuySz = ( _supplyTotal * 200 ) / 10000;
    uint256 public maxWalletSz = ( _supplyTotal * 200 ) / 10000;

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router; uniswapPair = _pair;
        _isExcludedFromFees[lpTokenAddress] = true;
        _isExcludedFromFees[marketingAddr] = true;
        _isExcludedFromFees[devAddress] = true;
        _isExcludedFromFees[msg.sender] = true;
        _balances[msg.sender] = _supplyTotal;
        emit Transfer(address(0), msg.sender, _supplyTotal);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _supplyTotal.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function decimals() public pure returns (uint8) {return _decimals;}    
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function getOwner() external view override returns (address) { return owner; }
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!_isExcludedFromFees[sender] && !_isExcludedFromFees[recipient]){require(tradeStarted, "tradeStarted");}
        if(!_isExcludedFromFees[sender] && !_isExcludedFromFees[recipient] && recipient != address(uniswapPair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= maxWalletSz, "Exceeds maximum wallet amount.");}
        if(sender != uniswapPair){require(amount <= maxBuySz || _isExcludedFromFees[sender] || _isExcludedFromFees[recipient], "TX Limit Exceeded");}
        require(amount <= maxTxSz || _isExcludedFromFees[sender] || _isExcludedFromFees[recipient], "TX Limit Exceeded"); 
        if(recipient == uniswapPair && !_isExcludedFromFees[sender]){swapTimes += uint256(1);}
        if(canSwapTax(sender, recipient, amount)){swapBackToken(feeSwapMax); swapTimes = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !_isExcludedFromFees[sender] ? getAmountAfterFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    function canSwapTax(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= feeSwapMin;
        bool aboveThreshold = balanceOf(address(this)) >= feeSwapMax;
        return !swapping && swapEnabled && tradeStarted && aboveMin && !_isExcludedFromFees[sender] && recipient == uniswapPair && swapTimes >= swapAfter && aboveThreshold;
    }
    function swapBackToken(uint256 tokens) private lockSwap {
        uint256 _denominator = (lpDynamicRate.add(1).add(marketingDivide).add(devDivide)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(lpDynamicRate).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokens(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(lpDynamicRate));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(lpDynamicRate);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingDivide);
        if(marketingAmt > 0){payable(marketingAddr).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devAddress).transfer(contractBalance);}
    }
    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supplyTotal.mul(_buy).div(10000); uint256 newTransfer = _supplyTotal.mul(_sell).div(10000); uint256 newWallet = _supplyTotal.mul(_wallet).div(10000);
        maxTxSz = newTx; maxBuySz = newTransfer; maxWalletSz = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }
    function getAmountAfterFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (_isExcludedFromFees[recipient]) {return maxTxSz;}
        if(getTransferFees(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTransferFees(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnDivide > uint256(0) && getTransferFees(sender, recipient) > burnDivide){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnDivide));}
        return amount.sub(feeAmount);} return amount;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _devAddresselopment, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        lpDynamicRate = _liquidity; marketingDivide = _marketing; burnDivide = _burn; devDivide = _devAddresselopment; buyFee = _total; sellFee = _sell; transferFee = _trans;
        require(buyFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "buyFee and sellFee cannot be more than 20%");
    }
    function swapTokens(uint256 tokenAmount) private {
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
            lpTokenAddress,
            block.timestamp);
    }
    function getTransferFees(address sender, address recipient) internal view returns (uint256) {
        if(recipient == uniswapPair){return sellFee;}
        if(sender == uniswapPair){return buyFee;}
        return transferFee;
    }
    function startTrading() external onlyOwner {tradeStarted = true;}
}