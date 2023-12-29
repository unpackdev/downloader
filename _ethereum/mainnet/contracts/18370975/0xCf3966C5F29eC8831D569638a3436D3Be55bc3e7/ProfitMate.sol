// SPDX-License-Identifier: MIT
/**  
$PRMATE Profit Mate - Powered By AI.Turns Every Buy into a Fat Profit. 100% Win, Zero Loss!

TG: https://t.me/ProfitMateOfficial
Twitter: https://x.com/ProfitMate
Web: https://profitmate.live 
**/
pragma solidity = 0.8.21;

//--- Context ---//
abstract contract Context {
    constructor() {
    }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

//--- Ownable ---//
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IV2Pair {
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
}

interface IRouter01 {
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
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline
    ) external payable returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}



//--- Interface for ERC20 ---//
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//--- Contract v1 ---//
contract ProfitMate is Context, Ownable, IERC20 {

    function totalSupply() external pure override returns (uint256) { if (_totalSupply == 0) { revert(); } return _totalSupply; }
    function decimals() external pure override returns (uint8) { if (_totalSupply == 0) { revert(); } return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function balanceOf(address account) public view override returns (uint256) {
        return balance[account];
    }

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _noFee;
    mapping (address => bool) private liquidityAdd;
    mapping (address => bool) private isLpPair;
    mapping (address => bool) private isPresaleAddress;
    mapping (address => uint256) public balance;

    uint256 public swapThreshold= 500 * 10**9;
    uint256 constant public _totalSupply = 1e6 * 10**9;
    uint256 constant public transferfee = 0;
    uint256 constant public fee_denominator = 100;



         uint256 public maxTransactionAmount= (_totalSupply * 1 / 100);   /// max wallet 1%
         uint256 public maxWallet= (_totalSupply* 1 / 100); ////max tx 1%


    uint256 private maxSellFee = 5;   
    uint256 private maxBuyFee = 5;

    struct Taxes {
        uint256 marketing;
        uint256 rewards;
    }

    Taxes public buyTaxes = Taxes(3, 2);  ///buy tax   5%
    Taxes public sellTaxes = Taxes(3, 2);    ///sell tax  5%

    bool private canSwapFees = true;
    address payable public marketingAddress = payable(0xD31E9cF4ba53702310312b95bd353b0Df7ACC19e);
    address payable public rewardsAddress = payable(0xb387a362683ac53f8F38274B36e50a7B7f7fA7FC);

    IRouter02 public swapRouter;
    string constant private _name = "Profit Mate"; ///name 
    string constant private _symbol = "PRMATE"; ///symbol

    uint8 constant private _decimals = 9;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public lpPair;
    bool public isTradingEnabled = false;
    bool public LiquidityAdded = false;
    bool inSwap;

    modifier inSwapFlag {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _noFee[msg.sender] = true;

     
            swapRouter = IRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
   
        liquidityAdd[msg.sender] = true;
        balance[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

        lpPair = IFactoryV2(swapRouter.factory()).createPair(swapRouter.WETH(), address(this));
        isLpPair[lpPair] = true;
        _approve(msg.sender, address(swapRouter), type(uint256).max);
        _approve(address(this), address(swapRouter), type(uint256).max);

    }

    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function isNoFeeWalelt(address account) external view returns(bool) {
        return _noFee[account];
    }

           function updateMaxTxAmount(uint256 newNum) external onlyOwner {
           
            maxTransactionAmount = (newNum * 1e9) + (1 * 1e9) ;
        }
        
        function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
          
            maxWallet = (newNum * 1e9) + (1 * 1e9);

        }

    function setNoFeeWallet(address account, bool enabled) public onlyOwner {
        _noFee[account] = enabled;
    }

    function isLimitedAddress(address ins, address out) internal view returns (bool) {

        bool isLimited = ins != owner()
            && out != owner() && tx.origin != owner() // any transaction with no direct interaction from owner will be accepted
            && msg.sender != owner()
            && !liquidityAdd[ins]  && !liquidityAdd[out] && out != DEAD && out != address(0) && out != address(this);
            return isLimited;
    }

    function is_buy(address ins, address out) internal view returns (bool) {
        bool _is_buy = !isLpPair[out] && isLpPair[ins];
        return _is_buy;
    }

    function is_sell(address ins, address out) internal view returns (bool) { 
        bool _is_sell = isLpPair[out] && !isLpPair[ins];
        return _is_sell;
    }

    function is_transfer(address ins, address out) internal view returns (bool) { 
        bool _is_transfer = !isLpPair[out] && !isLpPair[ins];
        return _is_transfer;
    }

    function canSwap(address ins, address out) internal view returns (bool) {
        bool canswap = canSwapFees && !isPresaleAddress[ins] && !isPresaleAddress[out];

        return canswap;
    }

    function changeLpPair(address newPair) external onlyOwner {
        lpPair = newPair;
        isLpPair[newPair] = true;
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        bool takeFee = true;
        require(to != address(0), "ERC20: transfer to the zero address");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (isLimitedAddress(from,to)) {
            require(isTradingEnabled,"Trading is not enabled");
        }
        
       if (
                    from != owner() &&

                    to != owner() 
                
                   
                ){

           //when buy
                    if (isLpPair[from] && !_noFee[to]) {
                            require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                            require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");

                    }
                    
                    //when sell
                    else if (isLpPair[to] && !_noFee[from]) {
                            require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                    }
                }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.

        if (inSwap) {
            return _basicTransfer(from, to, amount);
        }

        if(is_sell(from, to) &&  !inSwap && canSwap(from, to)) {
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance >= swapThreshold) { internalSwap(contractTokenBalance); }
        }

        if (_noFee[from] || _noFee[to]) {
            takeFee = false;
        }

        balance[from] -= amount; 
        uint256 amountAfterFee = (takeFee) ? takeTaxes(from, is_buy(from, to), is_sell(from, to), amount) : amount;
        balance[to] += amountAfterFee; 
        emit Transfer(from, to, amountAfterFee);

        return true;
    }

    function _basicTransfer( address from, address to, uint256 amount ) internal returns (bool) {

        balance[from] -= amount; 
        balance[to] += amount; 
        return true;
    }

    function changeWallets(address marketing, address rewards) external onlyOwner payable {
        marketingAddress = payable(marketing);
        rewardsAddress = payable(rewards);
    }

    function takeTaxes(address from, bool isbuy, bool issell, uint256 amount) internal returns (uint256) {
        uint256 fee;
        if (isbuy)  fee = buyTaxes.marketing + buyTaxes.rewards;  
        else if (issell)  fee = sellTaxes.marketing + sellTaxes.rewards;  
        else  fee = transferfee; 

        if (fee == 0)  return amount; 

        uint256 feeAmount = amount * fee / fee_denominator;
        if (feeAmount > 0) { 
            balance[address(this)] += feeAmount;
            emit Transfer(from, address(this), feeAmount);
            
        }
        return amount - feeAmount;
    }

    function internalSwap(uint256 contractTokenBalance) internal inSwapFlag {
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        if (_allowances[address(this)][address(swapRouter)] != type(uint256).max) {
            _allowances[address(this)][address(swapRouter)] = type(uint256).max;
        }

        try swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractTokenBalance,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch {
            return;
        }

        uint256 bnbInContract = address(this).balance;

        uint256 marketingBNB = 0;
        uint256 rewardsBNB = 0;
        uint256 totalTax = sellTaxes.marketing + sellTaxes.rewards;      
        
        if (totalTax > 0) {
            marketingBNB = bnbInContract * sellTaxes.marketing / totalTax;
            rewardsBNB = bnbInContract - marketingBNB;
        }       

        bool success;

        if (marketingBNB > 0)
            (success,) = marketingAddress.call{value: marketingBNB, gas: 35000}("");            

        if (rewardsBNB > 0)
            (success,) = rewardsAddress.call{value: rewardsBNB, gas: 35000}("");
    }

    function updateBuyFeeAmount(uint256 _marketingFee, uint256 _rewardsFee) external onlyOwner {
        require((_marketingFee + _rewardsFee) <= maxBuyFee, "Total should be less maxBuyFee");
        buyTaxes.marketing = _marketingFee;
        buyTaxes.rewards = _rewardsFee;
    }

    function updateSellFeeAmount(uint256 _marketingFee, uint256 _rewardsFee) external onlyOwner {
        require((_marketingFee + _rewardsFee) <= maxSellFee, "Total should be less maxSellFee");
        sellTaxes.marketing = _marketingFee;
        sellTaxes.rewards = _rewardsFee;
    }

    function setPresaleAddress(address presale, bool yesno) external onlyOwner {
        require(isPresaleAddress[presale] != yesno,"Same bool");
        isPresaleAddress[presale] = yesno;
        _noFee[presale] = yesno;
        liquidityAdd[presale] = yesno;
    }

    function enableTrading() external onlyOwner {
        require(!isTradingEnabled, "Trading already enabled");
        
        isTradingEnabled = true;
    }

    function rescueETH(uint256 weiAmount) external onlyOwner {
        payable(owner()).transfer(weiAmount);
    }

    function rescueERC20(address tokenAdd, address _to,uint256 amount) external onlyOwner {
        
         IERC20(tokenAdd).transfer(_to, amount*1e9);
    }
    
    
    function updateSwapthreshold (uint256 newNum) external onlyOwner {
          
            swapThreshold = (newNum * 1e9) + (1 * 1e9);

        }

}