// SPDX-License-Identifier: MIT

/*
YAKOLA | The NFT Options Protocol

Yakola is the first decentralized options protocol to issue and trade option positions on non-fungible tokens.

What is $YAK? 
- By burning your $YAK, you can issue options contracts to make stable, low-risk income by collecting premiums
- Protocol revenue is distributed to $YAK holders with staking platform

Website: https://www.yakola.xyz
Twitter: https://twitter.com/yakola_erc
Telegram: https://t.me/yakola_erc
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

interface IDexFactory{
    function createPair(address tokenA, address tokenB) external returns (address _dexPair);
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

contract YAK is Ownable, IERC20 {
    using SafeMath for uint256;

    string private constant _name = unicode"Yakola Protocol";
    string private constant _symbol = unicode"YAK";

    IDexRouter _dexRouter;
    address public _dexPair;
    bool private openedTrading = false;
    bool private swapEnabled = true;
    uint256 private numOfFeeSwaps;
    bool private swapping;
    uint256 triggerFeeSwapAfter;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public exceptFromFee;

    uint8 private constant _decimals = 9;
    uint256 private _tSupply = 1000000000 * (10 ** _decimals);
    uint256 private _maxCaSwap = ( _tSupply * 1000 ) / 100000;
    uint256 private _minCaSwap = ( _tSupply * 10 ) / 100000;

    uint256 private _maxTxnNum = ( _tSupply * 300 ) / 10000;
    uint256 private _maxTransferNum = ( _tSupply * 300 ) / 10000;
    uint256 private _maxWalletNum = ( _tSupply * 300 ) / 10000;

    uint256 private lpDenominator = 0;
    uint256 private marketingDenominator = 0;
    uint256 private devDenominator = 100;
    uint256 private burnDenominator = 0;

    uint256 private buyFee = 1400;
    uint256 private sellFee = 1400;
    uint256 private transferFee = 1400;
    uint256 private denominator = 10000;

    address internal teamAddress = 0x6247CE549146de3288b16671C3Af3200C8da02d8;
    address internal lpAddress = 0x6247CE549146de3288b16671C3Af3200C8da02d8;
    address internal devAddress = 0x6247CE549146de3288b16671C3Af3200C8da02d8; 
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    modifier locking {swapping = true; _; swapping = false;}

    constructor() Ownable(msg.sender) {
        IDexRouter _router = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IDexFactory(_router.factory()).createPair(address(this), _router.WETH());
        _dexRouter = _router; _dexPair = _pair;
        
        exceptFromFee[msg.sender] = true;
        exceptFromFee[devAddress] = true;
        exceptFromFee[lpAddress] = true;
        exceptFromFee[teamAddress] = true;
        _balances[msg.sender] = _tSupply;
        emit Transfer(address(0), msg.sender, _tSupply);
    }
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function totalSupply() public view override returns (uint256) {return _tSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function startTrading() external onlyOwner {openedTrading = true;}
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}

    function swapAndSendFee(uint256 tokens) private locking {
        uint256 _denominator = (lpDenominator.add(1).add(marketingDenominator).add(devDenominator)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(lpDenominator).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(lpDenominator));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(lpDenominator);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingDenominator);
        if(marketingAmt > 0){payable(teamAddress).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devAddress).transfer(contractBalance);}
    }

    function isExcludedFromFee(address sender, address recipient) internal view returns (bool) {
        return !exceptFromFee[sender] && !exceptFromFee[recipient];
    }    
    
    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _tSupply.mul(_buy).div(10000); uint256 newTransfer = _tSupply.mul(_sell).div(10000); uint256 newWallet = _tSupply.mul(_wallet).div(10000);
        _maxTxnNum = newTx; _maxTransferNum = newTransfer; _maxWalletNum = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }

    function getFeeAmounts(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (exceptFromFee[recipient]) {return _maxTxnNum;}
        if(getTotalFee(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTotalFee(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnDenominator > uint256(0) && getTotalFee(sender, recipient) > burnDenominator){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnDenominator));}
        return amount.sub(feeAmount);} return amount;
    }
    
    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(recipient == _dexPair){return sellFee;}
        if(sender == _dexPair){return buyFee;}
        return transferFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function shouldCATokenSwap(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _minCaSwap;
        bool aboveThreshold = balanceOf(address(this)) >= _maxCaSwap;
        return !swapping && swapEnabled && openedTrading && aboveMin && !exceptFromFee[sender] && recipient == _dexPair && numOfFeeSwaps >= triggerFeeSwapAfter && aboveThreshold;
    }
    
    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        lpDenominator = _liquidity; marketingDenominator = _marketing; burnDenominator = _burn; devDenominator = _development; buyFee = _total; sellFee = _sell; transferFee = _trans;
        require(buyFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "buyFee and sellFee cannot be more than 20%");
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
            lpAddress,
            block.timestamp);
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
        if(!exceptFromFee[sender] && !exceptFromFee[recipient]){require(openedTrading, "openedTrading");}
        if(!exceptFromFee[sender] && !exceptFromFee[recipient] && recipient != address(_dexPair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maxWalletNum, "Exceeds maximum wallet amount.");}
        if(sender != _dexPair){require(amount <= _maxTransferNum || exceptFromFee[sender] || exceptFromFee[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTxnNum || exceptFromFee[sender] || exceptFromFee[recipient], "TX Limit Exceeded"); 
        if(recipient == _dexPair && !exceptFromFee[sender]){numOfFeeSwaps += uint256(1);}
        if(shouldCATokenSwap(sender, recipient, amount)){swapAndSendFee(_maxCaSwap); numOfFeeSwaps = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !exceptFromFee[sender] ? getFeeAmounts(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    receive() external payable {}
}