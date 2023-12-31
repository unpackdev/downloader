// SPDX-License-Identifier: MIT
// 
//
//   _____/\\\\\\\\\\\\_______/\\\\\__________/\\\\\\\\\\\\_____/\\\\\\\\\____        
//    ___/\\\//////////______/\\\///\\\______/\\\//////////____/\\\\\\\\\\\\\__       
//     __/\\\_______________/\\\/__\///\\\___/\\\______________/\\\/////////\\\_      
//      _\/\\\____/\\\\\\\__/\\\______\//\\\_\/\\\____/\\\\\\\_\/\\\_______\/\\\_     
//       _\/\\\___\/////\\\_\/\\\_______\/\\\_\/\\\___\/////\\\_\/\\\\\\\\\\\\\\\_    
//        _\/\\\_______\/\\\_\//\\\______/\\\__\/\\\_______\/\\\_\/\\\/////////\\\_   
//         _\/\\\_______\/\\\__\///\\\__/\\\____\/\\\_______\/\\\_\/\\\_______\/\\\_  
//          _\//\\\\\\\\\\\\/_____\///\\\\\/_____\//\\\\\\\\\\\\/__\/\\\_______\/\\\_ 
//           __\////////////_________\/////________\////////////____\///________\///__
//                            
//   
// 
// 
// Website      :   https://gogatoken.com

pragma solidity 0.8.9;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns(address pair);
}

interface IERC20 {
    
    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function allowance(address owner, address spender) external view returns(uint256);
    function approve(address spender, uint256 amount) external returns(bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
 
    uint256 private _totalSupply;
 
    string private _name;
    string private _symbol;
    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    
    function name() public view virtual override returns(string memory) {
        return _name;
    }
   
    function symbol() public view virtual override returns(string memory) {
        return _symbol;
    }
    
    function decimals() public view virtual override returns(uint8) {
        return 18;
    }
   
    function totalSupply() public view virtual override returns(uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view virtual override returns(uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual override returns(uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public virtual override returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased cannot be below zero"));
        return true;
    }
    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
   
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}
 
library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
   
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
   
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    
        if (a == 0) {
            return 0;
        }
 
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
 
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
  
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    
}
 
contract Ownable is Context {

    address private _owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns(address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
 
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);
    
    function mul(int256 a, int256 b) internal pure returns(int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }
   
    function div(int256 a, int256 b) internal pure returns(int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns(int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns(int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns(int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns(uint256) {
        require(a >= 0);
        return uint256(a);
    }
}
 
library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns(int256) {
    int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

interface IUniswapV2Router02 {
    function factory() external pure returns(address);
    function WETH() external pure returns(address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
 
contract GOGA is ERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public immutable router;
    address public immutable uniswapV2Pair;

    address public  feesWallet;

    // limits 
    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;   
    uint256 public maxWalletAmount;
 
    uint256 private thresholdSwapAmount;

    // status flags
    bool private isTrading = false;
    bool public swapEnabled = false;
    bool public isSwapping;

    uint8 public buyFees;
    uint8 public sellFees;

    uint256 public tokensForFees = balanceOf(address(this));


    // Excludes from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public _isExcludedMaxWalletAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public marketPair;
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived
    );

    constructor() ERC20("GOGA TOKEN", "GOGA") {
 
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());

        _isExcludedMaxTransactionAmount[address(router)] = true;
        _isExcludedMaxTransactionAmount[address(uniswapV2Pair)] = true;        
        _isExcludedMaxTransactionAmount[owner()] = true;
        _isExcludedMaxTransactionAmount[address(this)] = true;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;

        _isExcludedMaxWalletAmount[owner()] = true;
        _isExcludedMaxWalletAmount[address(this)] = true;
        _isExcludedMaxWalletAmount[address(uniswapV2Pair)] = true;

        marketPair[address(uniswapV2Pair)] = true;

        approve(address(router), type(uint256).max);
        uint256 totalSupply = 1e11 * 1e18; //Total supply is 100 Billion

        maxBuyAmount = totalSupply * 1 / 1000; // 0.1% maxbuy initially
        maxSellAmount = totalSupply * 1 / 1000; // 0.1% maxsell initially
        maxWalletAmount = totalSupply * 1 / 1000; // 0.1% maxWallet initially 
        thresholdSwapAmount = totalSupply * 1 / 10000; // 0.01% minimum to allow fees swap

        buyFees = 1;
        sellFees = 1;

        feesWallet = address(0xC1B8C5675023DBe4335BccD011FD053a57b901dA);
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    /**
     * @dev Once enabled, trades cannot be disabled.
     */
    function enableTrading() external onlyOwner {
        isTrading = true;
        swapEnabled = true;
    }

    function updateMaxTxnAmount(uint256 newMaxBuy, uint256 newMaxSell) external onlyOwner {
        /**
        * @dev to enter 1 for 0.1%, 10 for 1% and 1000 for 100%
        */
        require(((totalSupply() * newMaxBuy) / 1000) >= (totalSupply() / 1000), "maxBuyAmount must be greater than 0.1%");
        require(((totalSupply() * newMaxSell) / 1000) >= (totalSupply() / 1000), "maxSellAmount must be greater than 0.1%");
        maxBuyAmount = (totalSupply() * newMaxBuy) / 1000;
        maxSellAmount = (totalSupply() * newMaxSell) / 1000;
    }

    function updateMaxWalletAmount(uint256 newPercentage) external onlyOwner {
        /**
        * @dev to enter 1 for 0.1%, 10 for 1% and 1000 for 100%
        */
        require(((totalSupply() * newPercentage) / 1000) >= (totalSupply() / 1000), "Must be atleast 0.1%");
        maxWalletAmount = (totalSupply() * newPercentage) / 1000;
    }
    
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function excludeFromWalletLimit(address account, bool excluded) public onlyOwner {
        _isExcludedMaxWalletAmount[account] = excluded;
    }

    function setMarketPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "Must keep uniswapV2Pair");
        marketPair[pair] = value;
    }

    function rescueETH(uint256 weiAmount) external onlyOwner {
        payable(owner()).transfer(weiAmount);
    }

    function rescueERC20(address tokenAdd, uint256 amount) external onlyOwner {
        IERC20(tokenAdd).transfer(owner(), amount);
    }

    function setFeesWallet(address _feesWallet) external onlyOwner{
        feesWallet = _feesWallet;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
        
    ) internal override {
        
        if (amount == 0) {
            super._transfer(sender, recipient, 0);
            return;
        }

        if (
            sender != owner() &&
            recipient != owner() &&
            !isSwapping
        ) {

            if (!isTrading) {
                require(_isExcludedFromFees[sender] || _isExcludedFromFees[recipient], "Trading is not active.");
            }
            if (marketPair[sender] && !_isExcludedMaxTransactionAmount[recipient]) {
                require(amount <= maxBuyAmount, "buy transfer over max amount");
            } 
            else if (marketPair[recipient] && !_isExcludedMaxTransactionAmount[sender]) {
                require(amount <= maxSellAmount, "Sell transfer over max amount");
            }

            if (!_isExcludedMaxWalletAmount[recipient]) {
                require(amount + balanceOf(recipient) <= maxWalletAmount, "Max wallet exceeded");
            }
           
        }
 
        uint256 contractTokenBalance = balanceOf(address(this));
 
        bool canSwap = contractTokenBalance >= thresholdSwapAmount;

        if (
            canSwap &&
            swapEnabled &&
            !isSwapping &&
            marketPair[recipient] &&
            !_isExcludedFromFees[sender] &&
            !_isExcludedFromFees[recipient]
        ) {
            isSwapping = true;
            swapBack();
            isSwapping = false;
        }
 
        bool takeFee = !isSwapping;

        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
            takeFee = false;
        }
 
        // Only take fees on buys/sells, not on wallet transfers
        if (takeFee) {
            uint256 fees = 0;
            // On sell
            if (marketPair[recipient] && sellFees > 0) {
                fees = amount.mul(sellFees).div(100);
            }
            // On buy
            else if (marketPair[sender] && buyFees > 0) {
                fees = amount.mul(buyFees).div(100);
            }
            //Transfer fees tokens to contract
            if (fees > 0) {
                super._transfer(sender, address(this), fees);
            }

            amount -= fees;

        }

        super._transfer(sender, recipient, amount);
    }

    function swapTokensForEth(uint256 tAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

    }

    function swapBack() private {

        uint256 contractTokenBalance = balanceOf(address(this));
        bool success;

        if (contractTokenBalance == 0) { return; }

        if (contractTokenBalance > thresholdSwapAmount * 100) {
            contractTokenBalance = thresholdSwapAmount * 100;
        }

        uint256 amountToSwapForETH = contractTokenBalance;

        swapTokensForEth(amountToSwapForETH); 

        (success,) = address(feesWallet).call{ value: (address(this).balance) } ("");

    }

}