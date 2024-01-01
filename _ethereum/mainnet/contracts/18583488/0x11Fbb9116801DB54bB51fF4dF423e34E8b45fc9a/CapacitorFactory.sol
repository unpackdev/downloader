// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

/**
 * @title ICapacitor
 * @dev Interface for a Capacitor contract that stores and manages messages in packets
 */
interface ICapacitor {
    /**
     * @notice adds the packed message to a packet
     * @dev this should be only executable by socket
     * @param packedMessage the message packed with payload, fees and config
     */
    function addPackedMessage(bytes32 packedMessage) external;

    /**
     * @notice returns the latest packet details which needs to be sealed
     * @return root root hash of the latest packet which is not yet sealed
     * @return packetCount latest packet id which is not yet sealed
     */
    function getNextPacketToBeSealed()
        external
        view
        returns (bytes32 root, uint64 packetCount);

    /**
     * @notice returns the root of packet for given id
     * @param id the id assigned to packet
     * @return root root hash corresponding to given id
     */
    function getRootByCount(uint64 id) external view returns (bytes32 root);

    /**
     * @notice returns the maxPacketLength
     * @return maxPacketLength of the capacitor
     */
    function getMaxPacketLength()
        external
        view
        returns (uint256 maxPacketLength);

    /**
     * @notice seals the packet
     * @dev indicates the packet is ready to be shipped and no more messages can be added now.
     * @dev this should be called by socket only
     * @param batchSize_ used with packet batching capacitors
     * @return root root hash of the packet
     * @return packetCount id of the packed sealed
     */
    function sealPacket(
        uint256 batchSize_
    ) external returns (bytes32 root, uint64 packetCount);
}

/**
 * @title IDecapacitor interface
 * @notice Interface for a contract that verifies if a packed message is part of a packet or not
 */
interface IDecapacitor {
    /**
     * @notice Returns true if packed message is part of root.
     * @param root_ root hash of the packet.
     * @param packedMessage_ packed message which needs to be verified.
     * @param proof_ proof used to determine the inclusion
     * @dev This function is kept as view instead of pure, as in future we may have stateful decapacitors
     * @return isIncluded boolean indicating whether the message is included in the packet or not.
     */
    function verifyMessageInclusion(
        bytes32 root_,
        bytes32 packedMessage_,
        bytes calldata proof_
    ) external returns (bool isIncluded);
}

/**
 * @title ICapacitorFactory
 * @notice Interface for a factory contract that deploys new instances of `ICapacitor` and `IDecapacitor` contracts.
 */
interface ICapacitorFactory {
    /**
     * @dev Emitted when an invalid capacitor type is requested during deployment.
     */
    error InvalidCapacitorType();

    /**
     * @notice Deploys a new instance of an `ICapacitor` and `IDecapacitor` contract with the specified parameters.
     * @param capacitorType The type of the capacitor to be deployed.
     * @param siblingChainSlug The identifier of the sibling chain.
     * @param maxPacketLength The maximum length of a packet.
     * @return Returns the deployed `ICapacitor` and `IDecapacitor` contract instances.
     */
    function deploy(
        uint256 capacitorType,
        uint32 siblingChainSlug,
        uint256 maxPacketLength
    ) external returns (ICapacitor, IDecapacitor);
}

/**
 * @title Ownable
 * @dev The Ownable contract provides a simple way to manage ownership of a contract
 * and allows for ownership to be transferred to a nominated address.
 */
abstract contract Ownable {
    address private _owner;
    address private _nominee;

    event OwnerNominated(address indexed nominee);
    event OwnerClaimed(address indexed claimer);

    error OnlyOwner();
    error OnlyNominee();

    /**
     * @dev Sets the contract's owner to the address that is passed to the constructor.
     */
    constructor(address owner_) {
        _claimOwner(owner_);
    }

    /**
     * @dev Modifier that restricts access to only the contract's owner.
     * Throws an error if the caller is not the owner.
     */
    modifier onlyOwner() {
        if (msg.sender != _owner) revert OnlyOwner();
        _;
    }

    /**
     * @dev Returns the current owner of the contract.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the current nominee for ownership of the contract.
     */
    function nominee() external view returns (address) {
        return _nominee;
    }

    /**
     * @dev Allows the current owner to nominate a new owner for the contract.
     * Throws an error if the caller is not the owner.
     * Emits an `OwnerNominated` event with the address of the nominee.
     */
    function nominateOwner(address nominee_) external {
        if (msg.sender != _owner) revert OnlyOwner();
        _nominee = nominee_;
        emit OwnerNominated(_nominee);
    }

    /**
     * @dev Allows the nominated owner to claim ownership of the contract.
     * Throws an error if the caller is not the nominee.
     * Sets the nominated owner as the new owner of the contract.
     * Emits an `OwnerClaimed` event with the address of the new owner.
     */
    function claimOwner() external {
        if (msg.sender != _nominee) revert OnlyNominee();
        _claimOwner(msg.sender);
    }

    /**
     * @dev Internal function that sets the owner of the contract to the specified address
     * and sets the nominee to address(0).
     */
    function _claimOwner(address claimer_) internal {
        _owner = claimer_;
        _nominee = address(0);
        emit OwnerClaimed(claimer_);
    }
}

/**
 * @title AccessControl
 * @dev This abstract contract implements access control mechanism based on roles.
 * Each role can have one or more addresses associated with it, which are granted
 * permission to execute functions with the onlyRole modifier.
 */
abstract contract AccessControl is Ownable {
    /**
     * @dev A mapping of roles to a mapping of addresses to boolean values indicating whether or not they have the role.
     */
    mapping(bytes32 => mapping(address => bool)) private _permits;

    /**
     * @dev Emitted when a role is granted to an address.
     */
    event RoleGranted(bytes32 indexed role, address indexed grantee);

    /**
     * @dev Emitted when a role is revoked from an address.
     */
    event RoleRevoked(bytes32 indexed role, address indexed revokee);

    /**
     * @dev Error message thrown when an address does not have permission to execute a function with onlyRole modifier.
     */
    error NoPermit(bytes32 role);

    /**
     * @dev Constructor that sets the owner of the contract.
     */
    constructor(address owner_) Ownable(owner_) {}

    /**
     * @dev Modifier that restricts access to addresses having roles
     * Throws an error if the caller do not have permit
     */
    modifier onlyRole(bytes32 role) {
        if (!_permits[role][msg.sender]) revert NoPermit(role);
        _;
    }

    /**
     * @dev Checks and reverts if an address do not have a specific role.
     * @param role_ The role to check.
     * @param address_ The address to check.
     */
    function _checkRole(bytes32 role_, address address_) internal virtual {
        if (!_hasRole(role_, address_)) revert NoPermit(role_);
    }

    /**
     * @dev Grants a role to a given address.
     * @param role_ The role to grant.
     * @param grantee_ The address to grant the role to.
     * Emits a RoleGranted event.
     * Can only be called by the owner of the contract.
     */
    function grantRole(
        bytes32 role_,
        address grantee_
    ) external virtual onlyOwner {
        _grantRole(role_, grantee_);
    }

    /**
     * @dev Revokes a role from a given address.
     * @param role_ The role to revoke.
     * @param revokee_ The address to revoke the role from.
     * Emits a RoleRevoked event.
     * Can only be called by the owner of the contract.
     */
    function revokeRole(
        bytes32 role_,
        address revokee_
    ) external virtual onlyOwner {
        _revokeRole(role_, revokee_);
    }

    /**
     * @dev Internal function to grant a role to a given address.
     * @param role_ The role to grant.
     * @param grantee_ The address to grant the role to.
     * Emits a RoleGranted event.
     */
    function _grantRole(bytes32 role_, address grantee_) internal {
        _permits[role_][grantee_] = true;
        emit RoleGranted(role_, grantee_);
    }

    /**
     * @dev Internal function to revoke a role from a given address.
     * @param role_ The role to revoke.
     * @param revokee_ The address to revoke the role from.
     * Emits a RoleRevoked event.
     */
    function _revokeRole(bytes32 role_, address revokee_) internal {
        _permits[role_][revokee_] = false;
        emit RoleRevoked(role_, revokee_);
    }

    /**
     * @dev Checks whether an address has a specific role.
     * @param role_ The role to check.
     * @param address_ The address to check.
     * @return A boolean value indicating whether or not the address has the role.
     */
    function hasRole(
        bytes32 role_,
        address address_
    ) external view returns (bool) {
        return _hasRole(role_, address_);
    }

    function _hasRole(
        bytes32 role_,
        address address_
    ) internal view returns (bool) {
        return _permits[role_][address_];
    }
}

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

error ZeroAddress();

/**
 * @title RescueFundsLib
 * @dev A library that provides a function to rescue funds from a contract.
 */

library RescueFundsLib {
    /**
     * @dev The address used to identify ETH.
     */
    address public constant ETH_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /**
     * @dev thrown when the given token address don't have any code
     */
    error InvalidTokenAddress();

    /**
     * @dev Rescues funds from a contract.
     * @param token_ The address of the token contract.
     * @param rescueTo_ The address of the user.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address rescueTo_,
        uint256 amount_
    ) internal {
        if (rescueTo_ == address(0)) revert ZeroAddress();

        if (token_ == ETH_ADDRESS) {
            SafeTransferLib.safeTransferETH(rescueTo_, amount_);
        } else {
            if (token_.code.length == 0) revert InvalidTokenAddress();
            SafeTransferLib.safeTransfer(ERC20(token_), rescueTo_, amount_);
        }
    }
}

// contains role hashes used in socket dl for various different operations

// used to rescue funds
bytes32 constant RESCUE_ROLE = keccak256("RESCUE_ROLE");
// used to withdraw fees
bytes32 constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
// used to trip switchboards
bytes32 constant TRIP_ROLE = keccak256("TRIP_ROLE");
// used to un trip switchboards
bytes32 constant UN_TRIP_ROLE = keccak256("UN_TRIP_ROLE");
// used by governance
bytes32 constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
//used by executors which executes message at destination
bytes32 constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
// used by transmitters who seal and propose packets in socket
bytes32 constant TRANSMITTER_ROLE = keccak256("TRANSMITTER_ROLE");
// used by switchboard watchers who work against transmitters
bytes32 constant WATCHER_ROLE = keccak256("WATCHER_ROLE");
// used by fee updaters responsible for updating fees at switchboards, transmit manager and execution manager
bytes32 constant FEES_UPDATER_ROLE = keccak256("FEES_UPDATER_ROLE");

/**
 * @title BaseCapacitor
 * @dev Abstract base contract for the Capacitors. Implements shared functionality and provides
 * access control.
 */
abstract contract BaseCapacitor is ICapacitor, AccessControl {
    /// address of socket
    address public immutable socket;

    /// an incrementing count for the next packet that is being created
    uint64 internal _nextPacketCount;

    /// tracks the count of next packet that will be sealed
    uint64 internal _nextSealCount;

    /// maps the packet count with the root hash of that packet
    mapping(uint64 => bytes32) internal _roots;

    // Error triggered when not called by socket
    error OnlySocket();

    /**
     * @dev Throws if called by any account other than the socket.
     */
    modifier onlySocket() {
        if (msg.sender != socket) revert OnlySocket();
        _;
    }

    /**
     * @dev Initializes the contract with the specified socket address.
     * @param socket_ The address of the socket contract.
     * @param owner_ The address of the owner of the capacitor contract.
     */
    constructor(address socket_, address owner_) AccessControl(owner_) {
        socket = socket_;
        _grantRole(RESCUE_ROLE, owner_);
    }

    /**
     * @dev Returns the count of the latest packet that finished filling.
     * @dev Returns 0 in case 0 or 1 packets are filled, hence this case should be considered by the caller
     * @return lastFilledPacket count of the latest packet.
     */
    function getLastFilledPacket()
        external
        view
        returns (uint256 lastFilledPacket)
    {
        return _nextPacketCount == 0 ? 0 : _nextPacketCount - 1;
    }

    /**
     * @dev Rescues funds from the contract.
     * @param token_ The address of the token to rescue.
     * @param rescueTo_ The address of the user to rescue tokens for.
     * @param amount_ The amount of tokens to rescue.
     */
    function rescueFunds(
        address token_,
        address rescueTo_,
        uint256 amount_
    ) external onlyRole(RESCUE_ROLE) {
        RescueFundsLib.rescueFunds(token_, rescueTo_, amount_);
    }
}

/**
 * @title SingleCapacitor
 * @notice A capacitor that adds a single message to each packet.
 * @dev This contract inherits from the `BaseCapacitor` contract, which provides the
 * basic storage and common function implementations.
 */
contract SingleCapacitor is BaseCapacitor {
    // Error triggered when no new packet/message is there to be sealed
    error NoPendingPacket();

    /**
     * @notice emitted when a new message is added to a packet
     * @param packedMessage the message packed with payload, fees and config
     * @param packetCount an incremental id assigned to each new packet created on this capacitor
     * @param newRootHash Hash of full packet. Same as packedMessage since this capacitor has one message per packet.
     */
    event MessageAdded(
        bytes32 packedMessage,
        uint64 packetCount,
        bytes32 newRootHash
    );

    /**
     * @dev Initializes the contract with the specified socket address.
     * @param socket_ The address of the socket contract.
     * @param owner_ The address of the owner of the capacitor contract.
     */
    constructor(
        address socket_,
        address owner_
    ) BaseCapacitor(socket_, owner_) {}

    /**
     * @inheritdoc ICapacitor
     */
    function getMaxPacketLength() external pure override returns (uint256) {
        return 1;
    }

    /**
     * @inheritdoc ICapacitor
     */
    function addPackedMessage(
        bytes32 packedMessage_
    ) external override onlySocket {
        uint64 packetCount = _nextPacketCount++;
        _roots[packetCount] = packedMessage_;

        // as it is a single capacitor, here root and packed message are same
        emit MessageAdded(packedMessage_, packetCount, packedMessage_);
    }

    /**
     * @inheritdoc ICapacitor
     */
    function sealPacket(
        uint256
    ) external override onlySocket returns (bytes32, uint64) {
        uint64 packetCount = _nextSealCount++;
        if (_roots[packetCount] == bytes32(0)) revert NoPendingPacket();

        bytes32 root = _roots[packetCount];
        return (root, packetCount);
    }

    /**
     * @inheritdoc ICapacitor
     */
    function getNextPacketToBeSealed()
        external
        view
        override
        returns (bytes32, uint64)
    {
        uint64 toSeal = _nextSealCount;
        return (_roots[toSeal], toSeal);
    }

    /**
     * @dev Returns the root hash of the packet with the specified count.
     * @param count_ The count of the packet.
     * @return The root hash of the packet.
     */
    function getRootByCount(
        uint64 count_
    ) external view override returns (bytes32) {
        return _roots[count_];
    }
}

/**
 * @title SingleDecapacitor
 * @notice A decapacitor that verifies messages by checking if the packed message is equal to the root.
 * @dev This contract inherits from the `IDecapacitor` interface, which
 * defines the functions for verifying message inclusion.
 */
contract SingleDecapacitor is IDecapacitor, AccessControl {
    /**
     * @notice Initializes the SingleDecapacitor contract with an owner address.
     * @param owner_ The address of the contract owner
     */
    constructor(address owner_) AccessControl(owner_) {
        _grantRole(RESCUE_ROLE, owner_);
    }

    /**
     * @inheritdoc IDecapacitor
     * @dev Just checks if root equals packed message since each packet has single message.
     * @dev Proof is ignored in this capacitor.
     */
    function verifyMessageInclusion(
        bytes32 root_,
        bytes32 packedMessage_,
        bytes calldata /* proof */
    ) external pure override returns (bool isIncluded) {
        return root_ == packedMessage_;
    }

    /**
     * @notice Rescues funds from the contract if they are locked by mistake.
     * @param token_ The address of the token contract.
     * @param rescueTo_ The address where rescued tokens need to be sent.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address rescueTo_,
        uint256 amount_
    ) external onlyRole(RESCUE_ROLE) {
        RescueFundsLib.rescueFunds(token_, rescueTo_, amount_);
    }
}

/**
 * @title CapacitorFactory
 * @notice Factory contract for creating capacitor and decapacitor pairs.
 * @dev The capacitorType_ parameter determines the type of capacitor and decapacitor to deploy.
 * @dev More types can be introduced by deploying new contract and pointing to it on Socket.
 */
contract CapacitorFactory is ICapacitorFactory, AccessControl {
    uint256 private constant SINGLE_CAPACITOR = 1;

    // min packet length to avoid div by 0 in fee calculations
    uint256 public constant minAllowedPacketLength = 1;

    // admin initialized max value for max packet length
    uint256 public immutable maxAllowedPacketLength;

    error PacketLengthNotAllowed();

    /**
     * @notice initializes and grants RESCUE_ROLE to owner.
     * @param owner_ The address of the owner of the contract.
     * @param maxAllowedPacketLength_ The max length allowed for capacitors
     */
    constructor(
        address owner_,
        uint256 maxAllowedPacketLength_
    ) AccessControl(owner_) {
        _grantRole(RESCUE_ROLE, owner_);
        maxAllowedPacketLength = maxAllowedPacketLength_;
    }

    /**
     * @notice Creates a new capacitor and decapacitor pair based on the given type.
     * @dev It sets the CapacitorFactory owner as owner of new Capacitor and Decapacitor
     * @param capacitorType_ The type of capacitor to be created. Can be SINGLE_CAPACITOR or HASH_CHAIN_CAPACITOR.
     * @dev siblingChainSlug_ sibling chain slug can be used for chain specific capacitors, useful while expanding to non-EVM chains.
     * @param maxPacketLength_ is not being used with single capacitor system, will be useful with batching.
     */
    function deploy(
        uint256 capacitorType_,
        uint32 /** siblingChainSlug_ */,
        uint256 maxPacketLength_
    ) external override returns (ICapacitor, IDecapacitor) {
        if (
            maxPacketLength_ < minAllowedPacketLength ||
            maxPacketLength_ > maxAllowedPacketLength
        ) revert PacketLengthNotAllowed();

        // fetch the capacitor factory owner
        address owner = this.owner();

        if (capacitorType_ == SINGLE_CAPACITOR) {
            return (
                // msg.sender is socket address
                new SingleCapacitor(msg.sender, owner),
                new SingleDecapacitor(owner)
            );
        }
        revert InvalidCapacitorType();
    }

    /**
     * @notice Rescues funds from the contract if they are locked by mistake.
     * @param token_ The address of the token contract.
     * @param rescueTo_ The address where rescued tokens need to be sent.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address rescueTo_,
        uint256 amount_
    ) external onlyRole(RESCUE_ROLE) {
        RescueFundsLib.rescueFunds(token_, rescueTo_, amount_);
    }
}