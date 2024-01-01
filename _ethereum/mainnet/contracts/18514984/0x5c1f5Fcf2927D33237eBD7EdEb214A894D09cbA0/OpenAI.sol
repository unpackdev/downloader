// SPDX-License-Identifier: MIT
/*
OpenAI

TG: https://t.me/openentry
Website: https://openaieth.org/
X: https://x.com/tickerisopen
                                                                                                                                     
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

contract OpenAI is Context, IERC20, Ownable {

    using Address for address payable;

    IRouter public router;
    address public pair;
    
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee;
    mapping (address => bool) public _isExcludedFromMaxBalance;

    uint8 private constant _decimals = 9; 
    uint256 private _tTotal = 1_000_000 * (10**_decimals);
    uint256 public swapThreshold = 4_000 * (10**_decimals); 
    uint256 public maxTxAmount = 20_000 * (10**_decimals);
    uint256 public maxWallet =  20_000 * (10**_decimals);

    string private constant _name = "OpenAI"; 
    string private constant _symbol = "OPEN";

    uint8 public buyTax = 20; 
    uint8 public sellTax = 60;

    address public marketingWallet = 0x82AD1FF74893F40354c3385b606A594c85F7E3e9; 
    
    bool public enableTrading = false;
    bool private swapping;
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }   

    event SwapAndLiquify();
    event TaxesChanged();

    constructor () {
        _tOwned[_msgSender()] = _tTotal;

        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router; pair = _pair;
       
        _approve(address(this), address(router), ~uint256(0));
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingWallet] = true;

        _isExcludedFromMaxBalance[owner()] = true;
        _isExcludedFromMaxBalance[address(this)] = true;
        _isExcludedFromMaxBalance[marketingWallet] = true;
        _isExcludedFromMaxBalance[pair] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

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
    
    receive() external payable {}

    function openTrading() external onlyOwner{
        require(!enableTrading,"Can only be opened once");
        enableTrading = true;
    }

    function setContractTaxes(uint8 buyTax_, uint8 sellTax_) external onlyOwner{
        require(buyTax_ <= 35 && sellTax_<= 60, "Taxes can't exceed the limit.");
        buyTax = buyTax_; sellTax = sellTax_;
        emit TaxesChanged();
    }

    function setContractLimits(uint maxTX_EXACT, uint maxWallet_EXACT) public onlyOwner{
        uint pointFiveSupply = (_tTotal * 5 / 1000) / (10**_decimals);
        require(maxTX_EXACT >= pointFiveSupply && maxWallet_EXACT >= pointFiveSupply, "Invalid Settings");
        maxTxAmount = maxTX_EXACT * (10**_decimals);
        maxWallet = maxWallet_EXACT * (10**_decimals);
    }

    function setSwapSettings(uint swapThreshold_EXACT) public onlyOwner{
        swapThreshold = swapThreshold_EXACT * (10**_decimals);
    }

    function setExcludedFromLimits(address account,bool isExcluded) public onlyOwner{
        _isExcludedFromMaxBalance[account] = isExcluded;
    }

    function setExcludedFromTaxes(address account, bool isExcluded) public onlyOwner{
        _isExcludedFromFee[account] = isExcluded;
    }

    function manualSwap() external lockTheSwap{
        require(msg.sender == marketingWallet);
        uint256 tokenBalance = balanceOf(address(this));
        if(tokenBalance > 0){
            uint256 ethSwapped = swapTokensForETH(tokenBalance);
            if(ethSwapped > 0)
                payable(marketingWallet).transfer(ethSwapped);
        }
        if (address(this).balance > 0)
            payable(marketingWallet).sendValue(address(this).balance);
    }

    function _preTransferCheck(address from,address to,uint256 amount) internal{
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= maxTxAmount || _isExcludedFromMaxBalance[from], "Transfer amount exceeds the _maxTxAmount.");

        if(!enableTrading)
            require(_isExcludedFromMaxBalance[from] && from != pair);

        if(!_isExcludedFromMaxBalance[to])
            require(balanceOf(to) + amount <= maxWallet, "Transfer amount exceeds the maxWallet.");
        
        if (balanceOf(address(this)) >= swapThreshold && !swapping && enableTrading && from != pair && from != owner() && to != owner())
            swapAndLiquify();
    }

    function _getTaxValues(uint amount, address from, bool isSell) private returns(uint256){
        uint256 taxedTokens = amount * buyTax / 100;
        if(isSell)
            taxedTokens = amount * sellTax / 100;

        if (taxedTokens > 0){
            _tOwned[address(this)] += taxedTokens;
            emit Transfer (from, address(this), taxedTokens);
        }
        return (amount - taxedTokens);
    }

    function _transfer(address from,address to,uint256 amount) private {
        _preTransferCheck(from, to, amount);
        _tOwned[from] -= amount;
        uint256 transferAmount = amount;
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            transferAmount = _getTaxValues(amount, from, to == pair);
        }
        _tOwned[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
    }

    function swapAndLiquify() private lockTheSwap{

        uint256 tokensForMarketing = swapThreshold * 80 / 100;
        uint256 tokensForLiquidity = swapThreshold * 20 / 100;
        
        if(tokensForMarketing > 0){
            uint256 ethSwapped = swapTokensForETH(tokensForMarketing);
            if(ethSwapped > 0)
                payable(marketingWallet).transfer(ethSwapped);
        }

        if(tokensForLiquidity > 0){
            uint half = tokensForLiquidity / 2;
            uint otherHalf = tokensForLiquidity - half;
            uint balAutoLP = swapTokensForETH(half);
            if (balAutoLP > 0)
                addLiquidity(otherHalf, balAutoLP);
        }

        if (address(this).balance > 0)
            payable(marketingWallet).sendValue(address(this).balance);
        
        emit SwapAndLiquify();

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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(router), tokenAmount);

        (,uint256 ethFromLiquidity,) = router.addLiquidityETH {value: ethAmount} (
            address(this),
            tokenAmount,
            0,
            0,
            marketingWallet,
            block.timestamp
        );
        
        if (ethAmount - ethFromLiquidity > 0)
            payable(marketingWallet).sendValue (ethAmount - ethFromLiquidity);
    }

}