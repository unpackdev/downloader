pragma solidity ^0.5.16;

/// @title Named Contract
contract NamedContract {
    /// @notice The name of contract, which can be set once
    string public name;

    /// @notice Sets contract name.
    function setContractName(string memory newName) internal {
        name = newName;
    }
}

contract Ownable {
    /// @notice Storage position of the owner address
    /// @dev The address of the current owner is stored in a
    /// constant pseudorandom slot of the contract storage
    /// (slot number obtained as a result of hashing a certain message),
    /// the probability of rewriting which is almost zero
    bytes32 private constant _ownerPosition = keccak256("owner");

    /// @notice Storage position of the authorized new owner address
    bytes32 private constant _authorizedNewOwnerPosition = keccak256("authorizedNewOwner");

    /// @notice Contract constructor
    /// @dev Sets msg sender address as owner address
    constructor() public {
        bytes32 ownerPosition = _ownerPosition;
        address owner = msg.sender;
        assembly {
            sstore(ownerPosition, owner)
        }
    }

    /// @notice Check that requires msg.sender to be the current owner
    function requireOwner() internal view {
        require(
            msg.sender == getOwner(),
            "Sender must be owner"
        );
    }

    /// @notice Returns contract owner address
    function getOwner() public view returns (address owner) {
        bytes32 ownerPosition = _ownerPosition;
        assembly {
            owner := sload(ownerPosition)
        }
    }

    /// @notice Returns authorized new owner address
    function getAuthorizedNewOwner() public view returns (address newOwner) {
        bytes32 authorizedNewOwnerPosition = _authorizedNewOwnerPosition;
        assembly {
            newOwner := sload(authorizedNewOwnerPosition)
        }
    }

    /**
     * @notice Authorizes the transfer of ownership to the provided address.
     * NOTE: No transfer will occur unless authorizedAddress calls assumeOwnership( ).
     * This authorization may be removed by another call to this function authorizing
     * the null address.
     *
     * @param authorizedAddress The address authorized to become the new owner.
     */
    function authorizeOwnershipTransfer(address authorizedAddress) external {
        requireOwner();
        bytes32 authorizedNewOwnerPosition = _authorizedNewOwnerPosition;
        assembly {
            sstore(authorizedNewOwnerPosition, authorizedAddress)
        }
    }
    
    /**
     * @notice Transfers ownership of this contract to the authorizedNewOwner.
     */
    function assumeOwnership() external {
        bytes32 authorizedNewOwnerPosition = _authorizedNewOwnerPosition;
        address newOwner;

        assembly {
            newOwner := sload(authorizedNewOwnerPosition)
        }

        require(
            msg.sender == newOwner,
            "Only the authorized new owner can accept ownership"
        );
        
        bytes32 ownerPosition = _ownerPosition;
        address zero = address(0);

        assembly {
            sstore(ownerPosition, newOwner)
            sstore(authorizedNewOwnerPosition, zero)
        }
    }
}

/// @title Upgradeable contract
contract Upgradeable is Ownable {
    /// @notice Storage position of the current implementation address.
    /// @dev The address of the current implementation is stored in a
    /// constant pseudorandom slot of the contract proxy contract storage
    /// (slot number obtained as a result of hashing a certain message),
    /// the probability of rewriting which is almost zero
    bytes32 private constant implementationPosition = keccak256(
        "implementation"
    );

    /// @notice Contract constructor
    /// @dev Calls Ownable contract constructor
    constructor() public Ownable() {}

    /// @notice Returns the current implementation contract address
    function getImplementation() public view returns (address implementation) {
        bytes32 position = implementationPosition;
        assembly {
            implementation := sload(position)
        }
    }

    /// @notice Sets new implementation contract address as current
    /// @param _newImplementation New implementation contract address
    function setImplementation(address _newImplementation) public {
        requireOwner();
        require(_newImplementation != address(0), "New implementation must have non-zero address");
        address currentImplementation = getImplementation();
        require(currentImplementation != _newImplementation, "New implementation must have new address");
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, _newImplementation)
        }
    }

    /// @notice Sets new implementation contract address and call its initializer.
    /// @dev New implementation call is a low level delegatecall.
    /// @param _newImplementation the new implementation address.
    /// @param _newImplementaionCallData represents the msg.data to bet sent through the low level delegatecall.
    /// This parameter may include the initializer function signature with the needed payload.
    function setImplementationAndCall(
        address _newImplementation,
        bytes calldata _newImplementaionCallData
    ) external payable {
        setImplementation(_newImplementation);
        if (_newImplementaionCallData.length > 0) {
            (bool success, ) = address(this).call.value(msg.value)(
                _newImplementaionCallData
            );
            require(success, "Delegatecall has failed");
        }
    }
}
/// @title Upgradeable Registry Contract
contract SwipeRegistry is NamedContract, Upgradeable {
    /// @notice Contract constructor
    /// @dev Calls Upgradable contract constructor and sets contract name
    constructor(string memory contractName) public Upgradeable() {
        setContractName(contractName);
    }
    
    /// @notice Performs a delegatecall to the implementation contract.
    /// @dev Fallback function allows to perform a delegatecall to the given implementation.
    /// This function will return whatever the implementation call returns.
    function() external payable {
        require(msg.data.length > 0, "Calldata must not be empty");
        address _impl = getImplementation();
        assembly {
            // The pointer to the free memory slot
            let ptr := mload(0x40)
            // Copy function signature and arguments from calldata at zero position into memory at pointer position
            calldatacopy(ptr, 0x0, calldatasize)
            // Delegatecall method of the implementation contract, returns 0 on error
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0x0, 0)
            // Get the size of the last return data
            let size := returndatasize
            // Copy the size length of bytes from return data at zero position to pointer position
            returndatacopy(ptr, 0x0, size)
            // Depending on result value
            switch result
                case 0 {
                    // End execution and revert state changes
                    revert(ptr, size)
                }
                default {
                    // Return data with length of size at pointers position
                    return(ptr, size)
                }
        }
    }
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

/// @title Governance Timelock Proxy Contract
contract GovernanceTimelockProxy is SwipeRegistry, GovernanceTimelockEvent {
    /// @notice Contract constructor
    /// @dev Calls SwipeRegistry contract constructor
    constructor() public SwipeRegistry("Swipe Governance Timelock Proxy") {}
}