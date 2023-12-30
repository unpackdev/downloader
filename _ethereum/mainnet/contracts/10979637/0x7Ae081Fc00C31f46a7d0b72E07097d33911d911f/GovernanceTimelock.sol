pragma solidity ^0.5.16;

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/// @title Named Contract
contract NamedContract {
    /// @notice The name of contract, which can be set once
    string public name;

    /// @notice Sets contract name.
    function setContractName(string memory newName) internal {
        name = newName;
    }
}

/// @title Governance Timelock Storage Contract
contract GovernanceTimelockStorage {
    /// @notice Initialized flag - indicates that initialization was made once
    bool internal _initialized;

    uint256 public constant _gracePeriod = 14 days;
    uint256 public constant _minimumDelay = 1 hours;
    uint256 public constant _maximumDelay = 30 days;

    address public _guardian;
    address public _authorizedNewGuardian;
    uint256 public _delay;

    mapping (bytes32 => bool) public _queuedTransactions;
}

/// @title Governance Timelock Event Contract
contract GovernanceTimelockEvent {
    event Initialize(
        address indexed guardian,
        uint256 indexed delay
    );

    event GuardianshipTransferAuthorization(
        address indexed authorizedAddress
    );

    event GuardianUpdate(
        address indexed oldValue,
        address indexed newValue
    );

    event DelayUpdate(
        uint256 indexed oldValue,
        uint256 indexed newValue
    );

    event TransactionQueue(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    event TransactionCancel(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    event TransactionExecution(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );
}
/// @title Governance Timelock Contract
contract GovernanceTimelock is NamedContract, GovernanceTimelockStorage, GovernanceTimelockEvent {
    using SafeMath for uint256;

    constructor() public {
        setContractName('Swipe Governance Timelock');
    }

    function initialize(
        address guardian,
        uint256 delay
    ) external {
        require(
            !_initialized,
            "Contract has been already initialized"
        );
        require(
            _minimumDelay <= delay && delay <= _maximumDelay,
            "Invalid delay"
        );

        _guardian = guardian;
        _delay = delay;

        _initialized = true;

        emit Initialize(
            _guardian,
            _delay
        );
    }

    function() external payable { }

    function setDelay(uint256 delay) external {
        require(
            msg.sender == _guardian,
            "Only the guardian can set the delay"
        );

        require(
            _minimumDelay <= delay && delay <= _maximumDelay,
            "Invalid delay"
        );

        uint256 oldValue = _delay;
        _delay = delay;

        emit DelayUpdate(
            oldValue,
            _delay
        );
    }

    /**
     * @notice Authorizes the transfer of guardianship from guardian to the provided address.
     * NOTE: No transfer will occur unless authorizedAddress calls assumeGuardianship( ).
     * This authorization may be removed by another call to this function authorizing
     * the null address.
     *
     * @param authorizedAddress The address authorized to become the new guardian.
     */
    function authorizeGuardianshipTransfer(address authorizedAddress) external {
        require(
            msg.sender == _guardian,
            "Only the guardian can authorize a new address to become guardian"
        );

        _authorizedNewGuardian = authorizedAddress;

        emit GuardianshipTransferAuthorization(_authorizedNewGuardian);
    }

    /**
     * @notice Transfers guardianship of this contract to the _authorizedNewGuardian.
     */
    function assumeGuardianship() external {
        require(
            msg.sender == _authorizedNewGuardian,
            "Only the authorized new guardian can accept guardianship"
        );

        address oldValue = _guardian;
        _guardian = _authorizedNewGuardian;
        _authorizedNewGuardian = address(0);

        emit GuardianUpdate(
            oldValue,
            _guardian
        );
    }

    function queueTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external returns (bytes32) {
        require(
            msg.sender == _guardian,
            "Only the guardian can queue transaction"
        );

        require(
            eta >= getBlockTimestamp().add(_delay),
            "Estimated execution block must satisfy delay"
        );

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        _queuedTransactions[txHash] = true;

        emit TransactionQueue(
            txHash,
            target,
            value,
            signature,
            data,
            eta
        );

        return txHash;
    }

    function cancelTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external {
        require(
            msg.sender == _guardian,
            "Only the guardian can cancel transaction"
        );

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        _queuedTransactions[txHash] = false;

        emit TransactionCancel(
            txHash,
            target,
            value,
            signature,
            data,
            eta
        );
    }

    function executeTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external payable returns (bytes memory) {
        require(
            msg.sender == _guardian,
            "Only the guardian can execute transaction"
        );

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        
        require(
            _queuedTransactions[txHash],
            "The transaction hasn't been queued"
        );
        
        require(
            getBlockTimestamp() >= eta,
            "The transaction hasn't surpassed time lock"
        );

        require(
            getBlockTimestamp() <= eta.add(_gracePeriod),
            "The transaction is stale"
        );

        _queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call.value(value)(callData);
        
        require(
            success,
            "The transaction execution reverted"
        );

        emit TransactionExecution(
            txHash,
            target,
            value,
            signature,
            data,
            eta
        );

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint256) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }
}