// File: @openzeppelin\contracts\math\SafeMath.sol

pragma solidity ^0.5.0;

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: node_modules\@openzeppelin\contracts\GSN\Context.sol

pragma solidity ^0.5.0;

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
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\ownership\Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\IReferrerBook.sol

pragma solidity 0.5.16;

interface IReferrerBook {
    function affirmReferrer(address user, address referrer) external returns (bool);
    function getUserReferrer(address user) external view returns (address);
    function getUserTopNode(address user) external view returns (address);
    function getUserNormalNode(address user) external view returns (address);
}

// File: contracts\ReferrerBook.sol

pragma solidity 0.5.16;




contract ReferrerBook is IReferrerBook, Ownable {
    using SafeMath for uint256;

    event ReferrerUpdated(
        address indexed user,
        address indexed referrer,
        uint256 timestampSec
    );

    mapping(address => address) public userReferrers;
    mapping(address => address) public userTopNodes;
    mapping(address => address) public userNormalNodes;

    mapping(address => uint256) public topNodes;
    mapping(address => uint256) public normalNodes;

    mapping(address => uint256) public providers;

    address public nodeSetter;

    bool public canUpdateReferrer;
    bool public canMakeupReferrer;

    address constant ZERO_ADDRESS = address(0);

    modifier onlyBookWriter() {
        require(
            providers[msg.sender] != uint256(0) || msg.sender == owner(),
            "Book writer must be owner or provider"
        );
        _;
    }

    modifier onlyNodeSetter() {
        require(msg.sender == nodeSetter, "Node setter wrong");
        _;
    }

    constructor() public {
        canUpdateReferrer = false;
        canMakeupReferrer = true;
        nodeSetter = msg.sender;
    }

    function affirmUserNode(
        address user,
        address referrer,
        mapping(address => uint256) storage nodes,
        mapping(address => address) storage userNodes
    ) internal returns (bool) {
        address node = userNodes[user];

        //node can only set once
        if (node != ZERO_ADDRESS && nodes[node] != uint256(0)) {
            return false;
        }

        //1. if parent is node
        if (nodes[referrer] != uint256(0)) {
            node = referrer;
        }

        //2. get parent's node
        if (node == ZERO_ADDRESS && userNodes[referrer] != ZERO_ADDRESS) {
            node = userNodes[referrer];
        }

        //4. set node
        if (node != ZERO_ADDRESS) {
            userNodes[user] = node;
            return true;
        }

        return false;
    }

    function affirmReferrer(address user, address referrer)
        external
        onlyBookWriter
        returns (bool)
    {
        require(user != ZERO_ADDRESS, "User address == 0");
        require(referrer != ZERO_ADDRESS, "Referrer address == 0");
        require(user != referrer, "referrer cannot be oneself");

        bool updated = false;
        if (userReferrers[user] == ZERO_ADDRESS || canUpdateReferrer) {
            userReferrers[user] = referrer;
            affirmUserNode(user, referrer, topNodes, userTopNodes);
            affirmUserNode(user, referrer, normalNodes, userNormalNodes);
            emit ReferrerUpdated(user, referrer, now);
            updated = true;
        }

        return updated;
    }

    function getUserReferrer(address user) external view returns (address) {
        return userReferrers[user];
    }

    function getUserTopNode(address user) external view returns (address) {
        address node = userTopNodes[user];
        if (node != ZERO_ADDRESS && topNodes[node] == uint256(0)) {
            return ZERO_ADDRESS;
        }
        return node;
    }

    function getUserNormalNode(address user) external view returns (address) {
        address node = userNormalNodes[user];
        if (node != ZERO_ADDRESS && normalNodes[node] == uint256(0)) {
            return ZERO_ADDRESS;
        }
        return node;
    }

    function addTopNode(address addr) external onlyNodeSetter {
        require(
            topNodes[addr] == uint256(0) && normalNodes[addr] == uint256(0),
            "Node alreay added"
        );

        topNodes[addr] = now;
    }

    function removeTopNode(address addr) external onlyNodeSetter {
        delete topNodes[addr];
    }

    function isTopNode(address addr) external view returns (bool) {
        return topNodes[addr] != uint256(0);
    }

    function addNormalNode(address addr) external onlyNodeSetter {
        require(
            topNodes[addr] == uint256(0) && normalNodes[addr] == uint256(0),
            "Node alreay added"
        );

        normalNodes[addr] = now;
    }

    function removeNormalNode(address addr) external onlyNodeSetter {
        delete normalNodes[addr];
    }

    function isNormalNode(address addr) external view returns (bool) {
        return normalNodes[addr] != uint256(0);
    }

    function setCanUpdateReferrer(bool canUpdate) external onlyOwner {
        canUpdateReferrer = canUpdate;
    }

    function setCanMakeupReferrer(bool canMakeup) external onlyOwner {
        canMakeupReferrer = canMakeup;
    }

    function setNodeSetter(address addr) external onlyOwner {
        nodeSetter = addr;
    }

    function addProvider(address addr) external onlyOwner {
        require(providers[addr] == uint256(0), "Provider alreay added");

        providers[addr] = now;
    }

    function removeProvider(address addr) external onlyOwner {
        delete providers[addr];
    }

    function isProvider(address addr) external view returns (bool) {
        return providers[addr] != uint256(0);
    }

    function makeupReferrer(address referrer) external {
        require(canMakeupReferrer, "cannot makeup referrer now");
        require(referrer != ZERO_ADDRESS, "referrer address == 0");

        address user = msg.sender;

        require(user != referrer, "referrer cannot be oneself");

        require(
            userReferrers[user] == ZERO_ADDRESS,
            "User already as referrer"
        );

        userReferrers[user] = referrer;

        affirmUserNode(user, referrer, topNodes, userTopNodes);
        affirmUserNode(user, referrer, normalNodes, userNormalNodes);

        emit ReferrerUpdated(user, referrer, now);
    }
}