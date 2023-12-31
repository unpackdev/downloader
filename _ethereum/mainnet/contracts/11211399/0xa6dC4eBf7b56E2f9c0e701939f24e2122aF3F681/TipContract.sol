pragma solidity ^0.6.4;

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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable
{
	address payable public owner;
	address public operator;

	constructor() public
	{
		owner = msg.sender;
		operator = msg.sender;
	}

	modifier onlyOwner()
	{
		require(msg.sender == owner,
		"Sender not authorised to access.");
		_;
	}

	modifier onlyOperator()
	{
		require(msg.sender == owner || msg.sender == operator,
		"Sender not authorised to access.");
		_;
	}

	function transferOwnership(address payable newOwner) external onlyOwner
	{
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

	function transferOperatorRights(address payable newOperator) external onlyOwner
	{
        if (newOperator != address(0)) {
            operator = newOperator;
        }
    }
}

contract TipContract is Ownable {
	using SafeMath for uint256;

	uint256 public etherBalance;
	mapping(address => uint256) public fees;
	mapping(address => bool) whitelistedTokens;

	event DiscordDeposit(address indexed tokenContract, uint256 amount, uint64 indexed discordId);
	event DiscordWithdrawal(address indexed tokenContract, uint256 amount, address recipient, uint64 indexed discordId);

	function updateTokens(address[] calldata _tokens, bool _value) external onlyOwner {
		for (uint256 i = 0; i < _tokens.length; i++)
			whitelistedTokens[_tokens[i]]  =  _value;
	}

	function depositEther(uint64 discordId) external payable {
		etherBalance = etherBalance.add(msg.value);
		emit DiscordDeposit(address(0), msg.value, discordId);
	}

	function withdrawEther(uint256 amount, uint256 fee, address payable recipient, uint64 discordId) public onlyOperator {
		etherBalance = etherBalance.sub(amount);
		recipient.transfer(amount.sub(fee));
		emit  DiscordWithdrawal(address(0), amount.sub(fee), recipient, discordId);
	}

	function depositToken(uint256 amount, address tokenContract, uint64 discordId) external {
		require(whitelistedTokens[tokenContract], "TipContract: Token not whitelisted.");
		IERC20(tokenContract).transferFrom(msg.sender, address(this), amount);
		emit DiscordDeposit(tokenContract, amount, discordId);
	}

	function withdrawToken(uint256 amount, uint256 fee, address tokenContract, address recipient, uint64 discordId) public onlyOperator {
		fees[tokenContract] = fees[tokenContract].add(fee);
		IERC20(tokenContract).transfer(recipient, amount.sub(fee));
		emit DiscordWithdrawal(tokenContract, amount.sub(fee), recipient, discordId);
	}

	function withdrawFees(address tokenContract) public onlyOwner returns (bool) {
		require (fees[tokenContract] > 0, "TipContract: Balance is empty.");
		uint256 fee = fees[tokenContract];
		fees[tokenContract] = 0;
		return IERC20(tokenContract).transfer(owner, fee);
	}

	function syphonEther(uint256 amount) public onlyOperator {
		require (amount < address(this).balance.sub(etherBalance), "TipContract: Amount is higher than ether balance");
		owner.transfer(amount);
	}
}