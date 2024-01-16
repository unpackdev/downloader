//SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";
import "./AccessControl.sol";

import "./Types.sol";
import "./Venture.sol";

/**
 * @title Venture
 * @notice You can use this Contract to manage your venture
 */
contract Venture is Ownable, Initializable, AccessControl {
    /// @notice The address to send the venture Funds
    address public fundsAddress;

    /// @notice The Token this venture will give for investments
    IERC20 public ventureToken;

    /// @notice The Token this venture will accept as investments
    IERC20 public treasuryToken;

    /// @notice The total Token supply
    uint256 public tokenSupply;

    /// @notice The venture name
    string public name;

    /// @notice The venture site
    string public site;

    /// @notice The venture logoUrl
    string public logoUrl;

    /// @notice The venture description
    string public description;

    /// @notice A list of allocators this venture manages
    address[] public allocators;

    /// @notice a mapping of allocator => signature store
    mapping(address => address) public signatureStore;

    /// @notice A mapping of allocator => AllocatorType
    mapping(address => Types.AllocatorType) public allocatorType;

    /// @dev Admin role has access to all actions
    bytes32 public constant ADMIN = keccak256("ADMIN");

    /// @dev Allocator manager can manage allocators
    bytes32 public constant ALLOCATOR_MANAGER = keccak256("ALLOCATOR_MANAGER");

    /// @dev Allocator attacher can attach allocators to venture - default to factory
    bytes32 public constant ALLOCATOR_ATTACHER = keccak256("ALLOCATOR_ATTACHER");

    /**
    * @notice This event is emitted when an Allocator(`allocator`) is added to this venture, of type `allocatorType`.
    * @param allocator The allocator that was added.
    * @param allocatorType The type of allocator that was added
    */
    event AllocatorAdded(address indexed allocator, Types.AllocatorType allocatorType);

    /**
    * @notice Initializes a venture with `config`, it also sets the owner,
    * a manager, and the factory as an allocator attacher
    * @param config The config to initialize the Venture
    */
    function initialize(Types.VentureConfig memory config, address _creator) external initializer {
        // Ownable
        _transferOwnership(config.fundsAddress);

        // AccessControl
        _grantRole(DEFAULT_ADMIN_ROLE, config.fundsAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, _creator);
        _addAdmin(config.fundsAddress);
        _addAdmin(msg.sender);
        _addAdmin(_creator);
        _addAllocatorManager(_creator);
        _addAllocatorManager(config.fundsAddress);
        _addAllocatorAttacher(msg.sender);
        _revokeRole(ADMIN, msg.sender);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Initializable
        fundsAddress = config.fundsAddress;
        ventureToken = config.ventureToken;
        treasuryToken = config.treasuryToken;
        tokenSupply = config.tokenSupply;
        name = config.name;
        site = config.site;
        logoUrl = config.logoUrl;
        description = config.description;
    }

    /**
    * @notice Adds an allocator: `newAllocator` of type: `_type` to this venture
    * @param _newAllocator The address of the allocator to be added
    * @param _allocatorType The type of allocator
    */
    function addAllocator(address _newAllocator, Types.AllocatorType _allocatorType) external onlyAllocatorAttacher {
        allocators.push(_newAllocator);
        allocatorType[_newAllocator] = _allocatorType;
        emit AllocatorAdded(_newAllocator, _allocatorType);
    }

    /**
    * @notice Sets the ventureToken to `_ventureToken`. Can only be called once.
    */
    function setVentureToken(IERC20 _ventureToken) external onlyAdmin {
        require(address(ventureToken) == address(0), "Venture: Token is already set");
        require(address(_ventureToken) != address(0), "Venture: Token address invalid");
        ventureToken = _ventureToken;
    }

    /// @notice Helper to get all allocators
    function getAllocators() external view returns (address[] memory) {
        return allocators;
    }

    function addAdmin(address _newAdmin) external virtual onlyOwner {
        _addAdmin(_newAdmin);
    }

    function removeAdmin(address _oldAdmin) external virtual onlyOwner {
        _removeAdmin(_oldAdmin);
    }

    function addAllocatorManager(address newAllocatorManager) external virtual {
        _addAllocatorManager(newAllocatorManager);
    }

    function removeAllocatorManager(address oldAllocatorManager) external virtual {
        _removeAllocatorManager(oldAllocatorManager);
    }

    /// @notice Checks if `maybeAdmin` is an Admin
    /// @return true if `maybeAdmin` has ADMIN role
    function isAdmin(address maybeAdmin) external virtual view returns (bool) {
        return hasRole(ADMIN, maybeAdmin);
    }

    /// @notice Checks if `maybeAllocatorManager` is an Admin OR Allocator Manager
    /// @return true if `maybeAllocatorManager` has ADMIN || ALLOCATOR_MANAGER role
    function isAdminOrAllocatorManager(address maybeAllocatorManager) external virtual view returns (bool) {
        return hasRole(ADMIN, maybeAllocatorManager) || hasRole(ALLOCATOR_MANAGER, maybeAllocatorManager);
    }

    /// @notice Revokes ADMIN role from `newAdmin`
    function _removeAdmin(address oldAmin) private {
        revokeRole(ADMIN, oldAmin);
    }

    /// @notice Grants ADMIN role to `newAdmin`
    function _addAdmin(address newAdmin) private {
        grantRole(ADMIN, newAdmin);
    }

    /// @notice Grants ALLOCATOR_MANAGER role to `newAllocatorManager`
    function _addAllocatorManager(address newAllocatorManager) private {
        require(hasRole(ADMIN, msg.sender), "Venture: Restricted to Admin Role");
        grantRole(ALLOCATOR_MANAGER, newAllocatorManager);
    }

    /// @notice Grants ALLOCATOR_ATTACHER role to `newAttacher`
    function _addAllocatorAttacher(address newAttacher) private {
        grantRole(ALLOCATOR_ATTACHER, newAttacher);
    }

    /// @notice Revokes ALLOCATOR_MANAGER role from `newAllocatorManager`
    function _removeAllocatorManager(address oldAllocatorManager) private {
        require(hasRole(ADMIN, msg.sender), "Venture: Restricted to Admin Role");
        revokeRole(ALLOCATOR_MANAGER, oldAllocatorManager);
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN, msg.sender), "Venture: Restricted to Admin Role");
        _;
    }

    modifier onlyAllocatorAttacher() {
        require(hasRole(ALLOCATOR_ATTACHER, msg.sender), "Venture: Restricted to Attacher Role");
        _;
    }

}

