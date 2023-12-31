pragma solidity 0.6.2;


// SPDX-License-Identifier: MIT
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

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 */
abstract contract VersionedInitializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    uint256 private lastInitializedRevision;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        uint256 revision = getRevision();
        require(
            initializing ||
                isConstructor() ||
                revision > lastInitializedRevision,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            lastInitializedRevision = revision;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev returns the revision number of the contract.
    /// Needs to be defined in the inherited class as a constant.
    function getRevision() internal virtual pure returns (uint256);

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        //solium-disable-next-line
        assembly {
            cs := extcodesize(address())
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[16] private ______gap;
}

contract Ownable {
    /** events */

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /** member */

    address public owner;

    /** constructor */

    function initializeOwnable(address _owner) internal {
        owner = _owner;
    }

    /** modifers */

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable.onlyOwner.EID00001");
        _;
    }

    /** functions */
    
    function transferOwnership(address _owner) public onlyOwner {
        require(_owner != address(0), "Ownable.transferOwnership.EID00090");
        emit OwnershipTransferred(owner, _owner);
        owner = _owner;
    }
}

contract Balance is Ownable, VersionedInitializable {
    using SafeMath for uint256;

    struct swap_t {
        uint256 reserve;
        uint256 supply;
        uint256 __reserved__field_0;
        uint256 __reserved__field_1;
        uint256 __reserved__field_2;
        uint256 __reserved__field_3;
    }

    mapping(address => mapping(address => swap_t)) public swaps; //user->token->swap_t
    mapping(address => swap_t) public gswaps; //token-> swap_t
    uint256 public gsupply;

    function getRevision() internal override pure returns (uint256) {
        return uint256(0x1);
    }

    function initialize(address owner) public initializer {
        Ownable.initializeOwnable(owner);
    }

    function deposit(
        address payer,
        address token,
        uint256 reserve
    ) public onlyOwner {
        swaps[payer][token].reserve = swaps[payer][token].reserve.add(reserve);
        gswaps[token].reserve = gswaps[token].reserve.add(reserve);
    }

    function withdraw(
        address receiver,
        address token,
        uint256 reserve
    ) public onlyOwner {
        swaps[receiver][token].reserve = swaps[receiver][token].reserve.sub(
            reserve
        );
        gswaps[token].reserve = gswaps[token].reserve.sub(reserve);
    }

    function burn(
        address payer,
        address token,
        uint256 supply
    ) public onlyOwner {
        swaps[payer][token].supply = swaps[payer][token].supply.sub(supply);
        gswaps[token].supply = gswaps[token].supply.sub(supply);
        gsupply = gsupply.sub(supply);
    }

    function mint(
        address receiver,
        address token,
        uint256 supply
    ) public onlyOwner {
        swaps[receiver][token].supply = swaps[receiver][token].supply.add(
            supply
        );
        gswaps[token].supply = gswaps[token].supply.add(supply);
        gsupply = gsupply.add(supply);
    }

    //销毁 @payer 的 QIAN, 并且增加相应的 @reserve 记录给 @payer, 同时 @who 减少相应的记录.
    function exchange(
        address payer,
        address owner,
        address token,
        uint256 supply,
        uint256 reserve
    ) public onlyOwner {
        swaps[owner][token].supply = swaps[owner][token].supply.sub(supply);
        gswaps[token].supply = gswaps[token].supply.sub(supply);
        gsupply = gsupply.sub(supply);
        swaps[owner][token].reserve = swaps[owner][token].reserve.sub(reserve);
        swaps[payer][token].reserve = swaps[payer][token].reserve.add(reserve);
    }

    function reserve(address who, address token)
        external
        view
        returns (uint256)
    {
        return swaps[who][token].reserve;
    }

    function supply(address who, address token)
        external
        view
        returns (uint256)
    {
        return swaps[who][token].supply;
    }

    function reserve(address token) external view returns (uint256) {
        return gswaps[token].reserve;
    }

    function supply(address token) public view returns (uint256) {
        return gswaps[token].supply;
    }
}