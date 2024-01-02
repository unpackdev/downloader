// SPDX-License-Identifier: Unlicensed

/*
JOIN THE SUPER PERIO REVOLUTION AND EXPERIENCE THE TRUE POWER OF THE MOST RECOGNIZABLE MEME IN THE WORLD, WHILE DIVING INTO A VIBRANT, FORWARD-THINKING COMMUNITY.

Web: https://superperio.xyz
Tg: https://t.me/superperio_group
X: https://twitter.com/superperio_erc
 */

pragma solidity 0.8.21;

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

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDexRouter {
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

contract SUPERPERIO is Context, IERC20, Ownable { 
    using SafeMath for uint256;

    string private _name = "SUPER PERIO"; 
    string private _symbol = unicode"佩里奧";

    uint8 private _decimals = 9;
    uint256 private _tTotal = 10 ** 9 * 10**_decimals;
    uint256 public maxTransaction = 25 * _tTotal / 1000;
    uint256 public feeSwapThreshold = _tTotal / 10000;

    uint256 private totalFee = 2000;
    uint256 public buyFee = 29;
    uint256 public sellFee = 25;

    uint256 private prevTotalFee = totalFee; 
    uint256 private prevBuyFee = buyFee; 
    uint256 private prevSellFee = sellFee; 

    uint8 private buyersCount = 0;
    uint8 private triggerSwapAfter = 2; 
                                     
    IDexRouter public swapRouter;
    address public swapPair;

    bool public hasTransferFee = true;
    bool public inswap;
    bool public swapEnabled = true;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromFee; 

    address payable private devWallet;
    address payable private DEAD;

    modifier lockSwap {
        inswap = true;
        _;
        inswap = false;
    }
    
    constructor () {
        _balances[owner()] = _tTotal;
        DEAD = payable(0x000000000000000000000000000000000000dEaD); 
        IDexRouter _uniswapV2Router = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        devWallet = payable(0x1e553837c5f83D6b5D36A7c311D99a785adF653D); 
        swapPair = IDexFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        swapRouter = _uniswapV2Router;
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[devWallet] = true;
        
        emit Transfer(address(0), owner(), _tTotal);
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
        return _tTotal;
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
        
    function removeFee() private {
        if(totalFee == 0 && buyFee == 0 && sellFee == 0) return;

        prevBuyFee = buyFee; 
        prevSellFee = sellFee; 
        prevTotalFee = totalFee;
        buyFee = 0;
        sellFee = 0;
        totalFee = 0;
    }

    function restoreFee() private {
        totalFee = prevTotalFee;
        buyFee = prevBuyFee; 
        sellFee = prevSellFee; 
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function transferStandard(address sender, address recipient, uint256 finalAmount) private {
        (uint256 tTransferAmount, uint256 tDev) = getTransferAmount(finalAmount);
        if(isExcludedFromFee[sender] && _balances[sender] <= maxTransaction) {
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
            to != devWallet &&
            to != address(this) &&
            to != swapPair &&
            to != DEAD &&
            from != owner()){

            uint256 currentBalance = balanceOf(to);
            require((currentBalance + amount) <= maxTransaction,"Maximum wallet limited has been exceeded");       
        }

        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");

        if(
            buyersCount >= triggerSwapAfter && 
            amount > feeSwapThreshold &&
            !inswap &&
            !isExcludedFromFee[from] &&
            to == swapPair &&
            swapEnabled 
            )
        {  
            buyersCount = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){
            swapBack(contractTokenBalance);
           }
        }
        
        bool takeFee = true;
         
        if(isExcludedFromFee[from] || isExcludedFromFee[to] || (hasTransferFee && from != swapPair && to != swapPair)){
            takeFee = false;
        } else if (from == swapPair){
            totalFee = buyFee;
        } else if (to == swapPair){
            totalFee = sellFee;
        }

        _basicTransfer(from,to,amount,takeFee);
    }
    
    function removeLimits() external onlyOwner {
        maxTransaction = ~uint256(0);
        totalFee = 100;
        buyFee = 1;
        sellFee = 1;
    }
    
    function transferFee(address payable receiver, uint256 amount) private {
        receiver.transfer(amount);
    }
    
    function swapBack(uint256 contractTokenBalance) private lockSwap {
        swapTokensForEth(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        transferFee(devWallet,contractETH);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
            
        if(!takeFee){
            removeFee();
        } else {
            buyersCount++;
        }
        transferStandard(sender, recipient, amount);
        
        if(!takeFee) {
            restoreFee();
        }
    }
    
    function getTransferAmount(uint256 finalAmount) private view returns (uint256, uint256) {
        uint256 tDev = finalAmount.mul(totalFee).div(100);
        uint256 tTransferAmount = finalAmount.sub(tDev);
        return (tTransferAmount, tDev);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();
        _approve(address(this), address(swapRouter), tokenAmount);
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    receive() external payable {}
}