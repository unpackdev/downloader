// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

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
        // Solidity only automatically asserts when dividing by 0
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

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

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

// File: contracts/MultisigDeal.sol

pragma solidity ^0.6.0;





contract MultisigDeal is Context {
    using SafeMath for uint256;

    address private _radix;
    address private _seller;
    address private _buyer;
    uint256 private _amount;
    string private _tokenName;
    address private _token;
    uint256 private _uid;
    bool _executed;

    modifier onlyRadix () {
        require(_msgSender() == address(_radix), "caller is not the radix");
        _;
    }

    constructor (uint256 uid, address radix, address buyer, uint256 amount, string memory tokenName, address token) public {
        IERC20 candidate = IERC20(token);
        require(candidate.totalSupply() > 0, "token doesn't support ERC20");
        _radix = radix;
        _seller = tx.origin;
        _buyer = buyer;
        _amount = amount;
        _tokenName = tokenName;
        _token = token;
        _executed = false;
        _uid = uid;
    }

    function transferToBuyer() external onlyRadix {
        require(!_executed, "contract always executed");
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= _amount, "insufficient contract address balance");

        token.transfer(_buyer, _amount);
        if (balance > _amount) {
            token.transfer(_seller, balance.sub(_amount));
        }
        _executed = true;
    }

    function returnToSeller() external onlyRadix {
        require(!_executed, "contract always executed");
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.transfer(_seller, balance);
        }
        _executed = true;
    }

    function radixAddress() external view returns (address) {
        return _radix;
    }

    function sellerAddress() external view returns (address) {
        return _seller;
    }

    function buyerAddress() external view returns (address) {
        return _buyer;
    }

    function amount() external view returns (uint256) {
        return _amount;
    }

    function tokenName() external view returns (string memory) {
        return _tokenName;
    }

    function tokenAddress() external view returns (address) {
        return _token;
    }

    function executed() external view returns (bool) {
        return _executed;
    }

    function uid() external view returns (uint256) {
        return _uid;
    }
}

// File: contracts/Factory.sol

pragma solidity ^0.6.0;



// import "./TestToken.sol";


contract Factory is Context {
    using SafeMath for uint256;

    mapping (uint256 => address) private _deals; // uid -> deals address
    mapping (address => address[]) private _userDeals; // user address -> deals addresses

    function createDeal(uint256 uid, address radix, address buyer, uint256 amount, string calldata tokenName, address token) external {
        require(radix != address(0), "radix can't be zero address");
        require(buyer != address(0), "buyer can't be zero address");
        require(token != address(0), "token can't be zero address");
        require(amount > 0, "amount cat't be zero");
        require(_deals[uid] == address(0), "uid already used, collision");
        MultisigDeal newDeal = new MultisigDeal(uid, radix, buyer, amount, tokenName, token);

        _deals[uid] = address(newDeal);
        _userDeals[_msgSender()].push(address(newDeal));
        _userDeals[buyer].push(address(newDeal));
    }

    function getUserDeals(address user) external view returns (address[] memory) {
         return _userDeals[user];
    }

    function getUserDealsWithFilter(address user, bool buyersOnly) external view returns (address[] memory) {
        uint256 counter = 0;
        uint256 length = _userDeals[user].length;
        for (uint256 i = 0; i < length; ++i) {
            MultisigDeal deal = MultisigDeal(_userDeals[user][i]);
            if ((deal.buyerAddress() == user && buyersOnly) ||
                (deal.sellerAddress() == user && !buyersOnly)) {
                counter++;
            }
        }

        address[] memory deals = new address[](counter);
        uint256 index = 0;
        for (uint256 i = 0; i < length; ++i) {
            MultisigDeal deal = MultisigDeal(_userDeals[user][i]);
            if ((deal.buyerAddress() == user && buyersOnly) ||
                (deal.sellerAddress() == user && !buyersOnly)) {
                deals[index] = _userDeals[user][i];
                index++;
            }
        }

        return deals;
    }

    function getDealContract(uint256 uid) external view returns (address) {
        return _deals[uid];
    }
}