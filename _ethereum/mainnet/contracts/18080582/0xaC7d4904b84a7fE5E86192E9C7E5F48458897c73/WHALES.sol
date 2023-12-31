// SPDX-License-Identifier: MIT

/*
Welcome to the WhalesGame, a fun and engaging experiment that combines game theory and economic principles around an increasing pot.

Website: https://whalesgame.tech
Telegram: https://t.me/WhaleGame_ETH
Twitter: https://twitter.com/whalesgame
Medium: https://medium.com/@whale_game
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

contract WHALES is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"WhalesGame";
    string private constant _symbol = unicode"WHALES";
    uint8 private constant _decimals = 9;
    uint256 private _tSupply = 1000000000 * (10 ** _decimals);
    IUniRouter uniRouter;
    address public uniPair;
    bool private tradingEnabled = false;
    bool private swapEnabled = true;
    uint256 private numFeeSwap;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExceptFromFee;
    bool private swapping;
    uint256 swapThresh;
    uint256 private _maxFeeSwap = ( _tSupply * 1000 ) / 100000;
    uint256 private _minFeeSwap = ( _tSupply * 10 ) / 100000;
    modifier lockingSwap {swapping = true; _; swapping = false;}
    uint256 private _maxTrnxAmount = ( _tSupply * 300 ) / 10000;
    uint256 private _maxSellSize = ( _tSupply * 300 ) / 10000;
    uint256 private _maxWalletAmount = ( _tSupply * 300 ) / 10000;
    uint256 private lpFeeDistribution = 0;
    uint256 private marketingDistribution = 0;
    uint256 private devDistribution = 100;
    uint256 private burnFee = 0;
    uint256 private buyFees = 1400;
    uint256 private sellFees = 1400;
    uint256 private tranFees = 1400;
    uint256 private denominator = 10000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal marketingReceive = 0x5Fd2192d9AE260BF1158fE8A3269E3d7DEE029b4;
    address internal lpReceive = 0x5Fd2192d9AE260BF1158fE8A3269E3d7DEE029b4;
    address internal devReceive = 0x5Fd2192d9AE260BF1158fE8A3269E3d7DEE029b4; 

    constructor() Ownable(msg.sender) {
        IUniRouter _router = IUniRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IUniFactory(_router.factory()).createPair(address(this), _router.WETH());
        uniRouter = _router; uniPair = _pair;
        isExceptFromFee[devReceive] = true;
        isExceptFromFee[lpReceive] = true;
        isExceptFromFee[marketingReceive] = true;
        isExceptFromFee[msg.sender] = true;
        _balances[msg.sender] = _tSupply;
        emit Transfer(address(0), msg.sender, _tSupply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _tSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}

    function startTrading() external onlyOwner {tradingEnabled = true;}
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
 


    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _tSupply.mul(_buy).div(10000); uint256 newTransfer = _tSupply.mul(_sell).div(10000); uint256 newWallet = _tSupply.mul(_wallet).div(10000);
        _maxTrnxAmount = newTx; _maxSellSize = newTransfer; _maxWalletAmount = newWallet;
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
            lpReceive,
            block.timestamp);
    }

    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(recipient == uniPair){return sellFees;}
        if(sender == uniPair){return buyFees;}
        return tranFees;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isExceptFromFee[sender] && !isExceptFromFee[recipient];
    }
    function swapandliquidify(uint256 tokens) private lockingSwap {
        uint256 _denominator = (lpFeeDistribution.add(1).add(marketingDistribution).add(devDistribution)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(lpFeeDistribution).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(lpFeeDistribution));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(lpFeeDistribution);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingDistribution);
        if(marketingAmt > 0){payable(marketingReceive).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devReceive).transfer(contractBalance);}
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExceptFromFee[recipient]) {return _maxTrnxAmount;}
        if(getTotalFee(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTotalFee(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFee > uint256(0) && getTotalFee(sender, recipient) > burnFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFee));}
        return amount.sub(feeAmount);} return amount;
    }
    function shouldTaxSwapFee(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _minFeeSwap;
        bool aboveThreshold = balanceOf(address(this)) >= _maxFeeSwap;
        return !swapping && swapEnabled && tradingEnabled && aboveMin && !isExceptFromFee[sender] && recipient == uniPair && numFeeSwap >= swapThresh && aboveThreshold;
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

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        lpFeeDistribution = _liquidity; marketingDistribution = _marketing; burnFee = _burn; devDistribution = _development; buyFees = _total; sellFees = _sell; tranFees = _trans;
        require(buyFees <= denominator.div(1) && sellFees <= denominator.div(1) && tranFees <= denominator.div(1), "buyFees and sellFees cannot be more than 20%");
    }

    function setContractSwapSettings(uint256 _swapAmount, uint256 _swapThreshold, uint256 _minTokenAmount) external onlyOwner {
        swapThresh = _swapAmount; _maxFeeSwap = _tSupply.mul(_swapThreshold).div(uint256(100000)); 
        _minFeeSwap = _tSupply.mul(_minTokenAmount).div(uint256(100000));
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
        if(!isExceptFromFee[sender] && !isExceptFromFee[recipient]){require(tradingEnabled, "tradingEnabled");}
        if(!isExceptFromFee[sender] && !isExceptFromFee[recipient] && recipient != address(uniPair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maxWalletAmount, "Exceeds maximum wallet amount.");}
        if(sender != uniPair){require(amount <= _maxSellSize || isExceptFromFee[sender] || isExceptFromFee[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTrnxAmount || isExceptFromFee[sender] || isExceptFromFee[recipient], "TX Limit Exceeded"); 
        if(recipient == uniPair && !isExceptFromFee[sender]){numFeeSwap += uint256(1);}
        if(shouldTaxSwapFee(sender, recipient, amount)){swapandliquidify(_maxFeeSwap); numFeeSwap = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isExceptFromFee[sender] ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
}