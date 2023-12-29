//SPDX-License-Identifier: CC-BY-NC-ND-2.5
pragma solidity 0.8.16;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";
import "./AccessControl.sol";

import "./Types.sol";


/**
 * @title Venture
 * @notice You can use this Contract to manage your venture
 */
contract Venture is Ownable, Initializable, AccessControl {
    using SafeERC20 for IERC20;
    /// @notice The address to send the venture Funds
    address public fundsAddress;

    /// @notice The Token this venture will give for investments
    IERC20 public ventureToken;

    /// @notice The Token this venture will accept as investments
    IERC20 public treasuryToken;

    /// @notice The total Token supply, only to be used whilst the token is not minted
    /// @notice The total Token supply, only to be used whilst the token is not minted
    uint256 public tokenSupply;

    /// @notice Total tokens allocated using all allocators per token
    /// @dev ventureToken allocation is stored against venterToken address
    mapping(address => uint256) totalTokensAllocated;

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

    /// @notice A mapping of allocator => AllocatorType
    mapping(address => uint256) public allocatorType;

    /// @dev Admin role has access to all actions
    bytes32 public constant ADMIN = keccak256("ADMIN");

    /// @dev Allocator manager can manage allocators
    bytes32 public constant ALLOCATOR_MANAGER = keccak256("ALLOCATOR_MANAGER");

    /// @dev Allocator attacher can attach allocators
    bytes32 public constant ALLOCATOR_ATTACHER = keccak256("ALLOCATOR_ATTACHER");

    /**
    * @notice This event is emitted when an Allocator(`allocator`) is added to this venture, of type `allocatorType`.
    * @param allocator The allocator that was added.
    * @param allocatorType The type of allocator that was added
    * @param tokensAllocated The total tokens allocated by this allocator
    */
    event AllocatorAdded(address indexed allocator, uint256 allocatorType, uint256 tokensAllocated);

    /**
    * @notice This event is emitted when an Allocator(`allocator`) is closed, and unallocated tokens have been returned to the venture wallet (fundsAddress).
    * @param allocator The allocator that was added.
    * @param tokensReturned The number of tokens not allocated by this allocator and returned to the venture wallet (fundsAddress)
    */
    event UnallocatedTokensReturned(address indexed allocator, uint256 tokensReturned);

    /**
     * @dev Emitted when the venture token address is set.
     * @param ventureToken The address of the venture token.
     */
    event VentureTokenSet(address indexed ventureToken);

    /**
     * @dev Emitted when the venture token supply is set.
     * @param tokenSupply The total supply of the venture token.
     */
    event VentureTokenSupplySet(uint256 tokenSupply);

    /**
    * @notice Initializes a venture with `config`, it also sets the owner,
    * a manager, and the factory as an allocator manager
     * @dev PLEASE NOTE, this contract supports prices with the decimals specific to the purchase token, i.e. $USDC 1 as 1000000
     * Allocation token is only supported with 18 decimals
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
        _addAllocatorAttacher(msg.sender);
        _revokeRole(ADMIN, msg.sender);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Initializable
        fundsAddress = config.fundsAddress;
        ventureToken = config.ventureToken;
        treasuryToken = config.treasuryToken;
        // TODO make this work.
        // require(config.ventureToken.totalSupply() == tokenSupply || address(ventureToken) == address(0), "Venture: Token has insufficient supply");
        tokenSupply = config.tokenSupply;
        name = config.name;
        site = config.site;
        logoUrl = config.logoUrl;
        description = config.description;
        // emit ManagerAdded(_creator);
    }

    /**
    * @notice Adds an allocator: `newAllocator` of type: `_type` to this venture
    * @param _newAllocator The address of the allocator to be added
    * @param _allocatorType The type of allocator
    */
    function addAllocator(address _newAllocator, uint256 _allocatorType, uint256 _tokensForAllocation) external  {
        require(_isAdminOrAllocatorManager(msg.sender) || _isAllocatorAttacher(msg.sender), "Venture: Only Admin or Manager or Attacher");
        require(_newAllocator != address(0), "Venture: Allocator address invalid");
        require(_tokensForAllocation != 0, "Venture: Allocator tokens invalid");
        allocators.push(_newAllocator);
        allocatorType[_newAllocator] = _allocatorType;
        totalTokensAllocated[_newAllocator] = totalTokensAllocated[_newAllocator] + _tokensForAllocation;
        emit AllocatorAdded(_newAllocator, _allocatorType, _tokensForAllocation);
    }

    /**
     * @notice Marks the unallocated tokens returned by the allocator.
     * @dev It is expected that this function only ever gets called by an allocator.
     * @param _allocator The address of the allocator.
     * @param _tokensReturned The number of tokens returned.
     */
    function markUnallocatedTokensReturned(address _allocator, uint256 _tokensReturned) external {
        require(msg.sender == owner() || totalTokensAllocated[_allocator] != 0, "Venture: invalid venture allocator or owner");
        require(_tokensReturned != 0, "Venture: Tokens returned invalid");
        require(_allocator != address(0), "Venture: Allocator address invalid");
        totalTokensAllocated[_allocator] = totalTokensAllocated[_allocator] - _tokensReturned;
        emit UnallocatedTokensReturned(_allocator, _tokensReturned);
    }

    /**
    * @notice Sets the ventureToken to `_ventureToken`. Can only be called once.
    */
    function setVentureToken(IERC20 _ventureToken) external onlyAdmin {
        require(address(ventureToken) == address(0), "Venture: Token is already set");
        require(address(_ventureToken) != address(0), "Venture: Token address invalid");
        require(_ventureToken.totalSupply() == tokenSupply || tokenSupply == 0, "Venture: Token does not meet supply requirements");
        require(_ventureToken.totalSupply() != 0, "Venture: Insufficient token supply");
        ventureToken = _ventureToken;
        emit VentureTokenSet(address(_ventureToken));
    }

        /**
    * @notice Sets the tokenSupply to `_ventureToken`. Can only be called once.
    */
    function setVentureTokenSupply(uint256 _tokenSupply) external onlyAdmin {
        require(tokenSupply == 0, "Venture: Token Supply is already set");
        tokenSupply = _tokenSupply;
        emit VentureTokenSupplySet(_tokenSupply);
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

    function addAllocatorManager(address newAllocatorManager) external virtual onlyAdmin {
        _addAllocatorManager(newAllocatorManager);
    }

    function removeAllocatorManager(address oldAllocatorManager) external virtual onlyAdmin {
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
        return _isAdminOrAllocatorManager(maybeAllocatorManager);
    }

    function _isAdminOrAllocatorManager(address maybeAllocatorManager) internal view returns (bool) {
        return hasRole(ADMIN, maybeAllocatorManager) || hasRole(ALLOCATOR_MANAGER, maybeAllocatorManager);
    }

    function _isAllocatorAttacher(address maybeAllocatorAttacher) internal view returns (bool) {
        return hasRole(ALLOCATOR_ATTACHER, maybeAllocatorAttacher);
    }

    /// @notice Revokes ADMIN role from `newAdmin`
    function _removeAdmin(address oldAdmin) private {
        revokeRole(ADMIN, oldAdmin);
    }

    /// @notice Grants ADMIN role to `newAdmin`
    function _addAdmin(address newAdmin) private {
        grantRole(ADMIN, newAdmin);
    }

    /// @notice Grants ALLOCATOR_MANAGER role to `newAllocatorManager`
    function _addAllocatorManager(address newAllocatorManager) private {
        grantRole(ALLOCATOR_MANAGER, newAllocatorManager);
    }

    /// @notice Revokes ALLOCATOR_MANAGER role from `newAllocatorManager`
    function _removeAllocatorManager(address oldAllocatorManager) private {
        revokeRole(ALLOCATOR_MANAGER, oldAllocatorManager);
    }

    /// @notice Grants ALLOCATOR_ATTACHER role to `newAllocatorAttacher`
    function _addAllocatorAttacher(address newAllocatorAttacher) private {
        grantRole(ALLOCATOR_ATTACHER, newAllocatorAttacher);
    }

    /// @notice Revokes ALLOCATOR_ATTACHER role from `newAllocatorAttacher`
    function _removeAllocatorAttacher(address oldAllocatorAttacher) private {
        revokeRole(ALLOCATOR_ATTACHER, oldAllocatorAttacher);
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN, msg.sender), "Venture: Restricted to Admin Role");
        _;
    }

}

