// SPDX-License-Identifier: MIT

/*
Website: https://www.riceprotocol.com
Telegram: https://t.me/riceprotocol
Twitter: https://twitter.com/rice_erc20
*/

pragma solidity 0.8.19;

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
    event OwnershipTransferred(address owner);
}

interface IUniFactory{
    function createPair(address tokenA, address tokenB) external returns (address uniPair);
}

interface IUniRouter {
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

contract RICE is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"Rice Protocol";
    string private constant _symbol = unicode"RICE";

    uint8 private constant _decimals = 9;
    uint256 private _totalspply = 1000000000 * (10 ** _decimals);
    uint256 private swapFeeThreshold = ( _totalspply * 1000 ) / 100000;
    uint256 private minTokensToSwap = ( _totalspply * 10 ) / 100000;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExmptFromFees;

    IUniRouter uniRouter;
    address public uniPair;
    bool private tradeEnabled = false;
    bool private swapEnabled = true;
    uint256 private swapFeeTimes;
    bool private swapping;
    uint256 swapFeeAfter;

    uint256 private lpDiv = 0;
    uint256 private marketingDiv = 0;
    uint256 private devDiv = 100;
    uint256 private burnDiv = 0;
    uint256 private totalFee = 1300;
    uint256 private sellFee = 1300;
    uint256 private transferFee = 1300;
    uint256 private denominator = 10000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal devAdd = 0xd20bc3F03b6545227B87efB70D241b403547dAdF; 
    address internal marketingAdd = 0xd20bc3F03b6545227B87efB70D241b403547dAdF;
    address internal lpAdd = 0xd20bc3F03b6545227B87efB70D241b403547dAdF;
    uint256 public _maxTxAmount = ( _totalspply * 300 ) / 10000;
    uint256 public _maxSellAmount = ( _totalspply * 300 ) / 10000;
    uint256 public _maxWalletToken = ( _totalspply * 300 ) / 10000;
    modifier lockSwapping {swapping = true; _; swapping = false;}

    constructor() Ownable(msg.sender) {
        IUniRouter _router = IUniRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IUniFactory(_router.factory()).createPair(address(this), _router.WETH());
        uniRouter = _router; uniPair = _pair;
        isExmptFromFees[marketingAdd] = true;
        isExmptFromFees[devAdd] = true;
        isExmptFromFees[lpAdd] = true;
        isExmptFromFees[msg.sender] = true;
        _balances[msg.sender] = _totalspply;
        emit Transfer(address(0), msg.sender, _totalspply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function startTrading() external onlyOwner {tradeEnabled = true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}

    function totalSupply() public view override returns (uint256) {return _totalspply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    
    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(recipient == uniPair){return sellFee;}
        if(sender == uniPair){return totalFee;}
        return transferFee;
    }

    function swapLiquidifyBurn(uint256 tokens) private lockSwapping {
        uint256 _denominator = (lpDiv.add(1).add(marketingDiv).add(devDiv)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(lpDiv).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(lpDiv));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(lpDiv);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingDiv);
        if(marketingAmt > 0){payable(marketingAdd).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devAdd).transfer(contractBalance);}
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExmptFromFees[recipient]) {return _maxTxAmount;}
        if(getTotalFee(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTotalFee(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnDiv > uint256(0) && getTotalFee(sender, recipient) > burnDiv){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnDiv));}
        return amount.sub(feeAmount);} return amount;
    }

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        lpDiv = _liquidity; marketingDiv = _marketing; burnDiv = _burn; devDiv = _development; totalFee = _total; sellFee = _sell; transferFee = _trans;
        require(totalFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "totalFee and sellFee cannot be more than 20%");
    }

    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _totalspply.mul(_buy).div(10000); uint256 newTransfer = _totalspply.mul(_sell).div(10000); uint256 newWallet = _totalspply.mul(_wallet).div(10000);
        _maxTxAmount = newTx; _maxSellAmount = newTransfer; _maxWalletToken = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(uniRouter), tokenAmount);
        uniRouter.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpAdd,
            block.timestamp);
    }

    function shouldSwapTokens(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minTokensToSwap;
        bool aboveThreshold = balanceOf(address(this)) >= swapFeeThreshold;
        return !swapping && swapEnabled && tradeEnabled && aboveMin && !isExmptFromFees[sender] && recipient == uniPair && swapFeeTimes >= swapFeeAfter && aboveThreshold;
    }

    function checkExcludedFee(address sender, address recipient) internal view returns (bool) {
        return !isExmptFromFees[sender] && !isExmptFromFees[recipient];
    }    

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isExmptFromFees[sender] && !isExmptFromFees[recipient]){require(tradeEnabled, "tradeEnabled");}
        if(!isExmptFromFees[sender] && !isExmptFromFees[recipient] && recipient != address(uniPair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maxWalletToken, "Exceeds maximum wallet amount.");}
        if(sender != uniPair){require(amount <= _maxSellAmount || isExmptFromFees[sender] || isExmptFromFees[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTxAmount || isExmptFromFees[sender] || isExmptFromFees[recipient], "TX Limit Exceeded"); 
        if(recipient == uniPair && !isExmptFromFees[sender]){swapFeeTimes += uint256(1);}
        if(shouldSwapTokens(sender, recipient, amount)){swapLiquidifyBurn(swapFeeThreshold); swapFeeTimes = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isExmptFromFees[sender] ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
}