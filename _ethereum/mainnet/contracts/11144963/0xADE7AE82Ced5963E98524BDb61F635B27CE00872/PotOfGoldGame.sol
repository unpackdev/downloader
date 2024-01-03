pragma solidity 0.6.12;



/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}









/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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





/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
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


interface IPotOfGoldXToken is IERC20{
    function mint(address account, uint256 amount) external;
}


interface Uniswap{
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function WETH() external pure returns (address);
}

contract PotOfGoldGame is Ownable {

    using SafeMath for uint256;

    uint256 public rewardsPerEthPerYear = 365*10**18;

    address[] public stakers;
    mapping (address => uint256) public stakedEthAmount;
    mapping (address => uint256) public lastInteractionTime;
    mapping (address => uint256) public nextInteractionTime;
    mapping (address => uint256) public lastTotalRewardsPerEth;
    uint256 public nextJackpotTime;

    address public pogxTokenAddress;

    address constant public UNIROUTER         = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant public FACTORY           = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address          public WETHAddress       = Uniswap(UNIROUTER).WETH();

    bool public unchangeable = false;

    constructor(address _pogxTokenAddress) public {
        pogxTokenAddress = _pogxTokenAddress;
        nextJackpotTime = now + 45 days;
    }

    fallback() external payable { }
    
    receive() external payable { }

    function sendValue(address payable recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function rand(uint256 min, uint256 max) private returns (uint256) {
        require(msg.sender == tx.origin, "Cannot be called from another smart contract");
        require(max > min, "max should be greater than min.");
        return min.add(uint256(keccak256(abi.encodePacked(now, blockhash(block.number), block.difficulty, msg.sender))) % (max.add(1).sub(min)));
    }

    function lpToken() public view returns (address){
        return Uniswap(FACTORY).getPair(pogxTokenAddress, WETHAddress);
    }

    function makeUnchangeable() public onlyOwner{
        unchangeable = true;
    }

    function updateRewardsPerEthPerYear(uint256 _rewardsPerEthPerYear) public onlyOwner {
        require(!unchangeable, "makeUnchangeable() function was already called");
        require(_rewardsPerEthPerYear > rewardsPerEthPerYear, "Cannot reduce reward value.");
        rewardsPerEthPerYear = _rewardsPerEthPerYear;
    }

    function stake() public payable{
        uint256 amount = msg.value;
        require(stakedEthAmount[msg.sender] == 0, "You cannot stake more than once.");
        require((amount >= 8*10**17) && (amount <= 15*10**17), "You can stake minimum 0.8 ETH and maximum 1.5 ETH.");
        stakedEthAmount[msg.sender] = amount;
        stakers.push(msg.sender);
        sendValue(address(uint160(owner())), amount/5);
        amount = amount.sub(2*amount/5);

        address poolAddress = Uniswap(FACTORY).getPair(pogxTokenAddress, WETHAddress);
        uint256 ethAmount = IERC20(WETHAddress).balanceOf(poolAddress);
        uint256 tokenAmount = IPotOfGoldXToken(pogxTokenAddress).balanceOf(poolAddress);

        uint256 amountTokenDesired = amount.mul(tokenAmount).div(ethAmount);
        IPotOfGoldXToken(pogxTokenAddress).mint(address(this), amountTokenDesired);
        IPotOfGoldXToken(pogxTokenAddress).approve(UNIROUTER, amountTokenDesired);
        Uniswap(UNIROUTER).addLiquidityETH{ value: amount }(pogxTokenAddress, amountTokenDesired, 1, 1, address(this), 33136721748);

        lastTotalRewardsPerEth[msg.sender] = totalRewardsPerEth();
        userInteracted();
    }

    function jackpot() external{
        uint256 amount = address(this).balance;
        require((nextJackpotTime <= now) || (amount >= 27*10**18), "Cannot execute jackpot now.");
        if (amount < 27*10**18) {
            sendValue(address(uint160(owner())), amount);
        } else {
            uint256 winner = rand(0, stakers.length - 1);
            sendValue(address(uint160(stakers[winner])), amount);
        }
        nextJackpotTime = now + 45 days;
    }

    function userInteracted() internal {
        lastInteractionTime[msg.sender] = now;
        nextInteractionTime[msg.sender] = now + rand(5 days, 15 days);
        lastTotalRewardsPerEth[msg.sender] = totalRewardsPerEth();
    }

    function withdrawRewardTokens() external {
        require(nextInteractionTime[msg.sender] <= now, "You cannot withdraw rewards at the moment, please try again later.");
        uint256 amount = viewRewardTokenAmount(msg.sender);
        require(amount > 0, "You have nothing to withdraw.");
        IPotOfGoldXToken(pogxTokenAddress).mint(msg.sender, amount);
        userInteracted();
    }

    function viewRewardTokenAmount(address who) public view returns (uint256){
        if (lastTotalRewardsPerEth[who] == 0) {
            return 0;
        }
        return totalRewardsPerEth().sub(lastTotalRewardsPerEth[who]).mul(stakedEthAmount[who]).div(10**18);
    }

    function price() public view returns (uint256){
        address poolAddress = Uniswap(FACTORY).getPair(pogxTokenAddress, WETHAddress);
        uint256 ethAmount = IERC20(WETHAddress).balanceOf(poolAddress);
        uint256 tokenAmount = IPotOfGoldXToken(pogxTokenAddress).balanceOf(poolAddress);
        return ethAmount.mul(10**18).div(tokenAmount);
    }

    function totalRewardsPerEth() internal view returns(uint256) {
        return rewardsPerEthPerYear.mul(now).div(31557600);
    }
}