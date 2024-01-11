// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.4;

//  ==========  External imports    ==========

import "./ERC721AUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./MulticallUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./IERC2981Upgradeable.sol";

import "./ERC2771ContextUpgradeable.sol";
import "./IOwnable.sol";
import "./MerkleProof.sol";

//  ==========  Internal imports    ==========

import "./IPropsContract.sol";
import "./IPropsAccessRegistry.sol";

contract PropsProject is
    Initializable,
    IOwnable,
    IPropsContract,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    AccessControlEnumerableUpgradeable
{
    using StringsUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    //////////////////////////////////////////////
    // State Vars
    /////////////////////////////////////////////

    bytes32 private constant MODULE_TYPE = bytes32("PropsProject");
    uint256 private constant VERSION = 1;

    bytes32 private constant CONTRACT_ADMIN_ROLE =
        keccak256("CONTRACT_ADMIN_ROLE");
    bytes32 private constant PRODUCER_ROLE = keccak256("PRODUCER_ROLE");
    // @dev reserving space for 10 more roles
    bytes32[32] private __gap;

    string public contractURI;
    string public name;
    address private _owner;
    address private accessRegistry;
    address[] private trustedForwarders;
    EnumerableSetUpgradeable.AddressSet private contracts;

    //////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////

    event ContractAdded(address);
    event ContractRemoved(address);

    //////////////////////////////////////////////
    // Init
    /////////////////////////////////////////////

    function initialize(
        string calldata _name,
        address _defaultAdmin,
        address[] memory _trustedForwarders,
        address _accessRegistry
    ) public initializer {
        __ReentrancyGuard_init();
        __ERC2771Context_init(_trustedForwarders);

        name = _name;
        _owner = _defaultAdmin;
        accessRegistry = _accessRegistry;

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setRoleAdmin(CONTRACT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PRODUCER_ROLE, CONTRACT_ADMIN_ROLE);

        IPropsAccessRegistry(accessRegistry).add(_defaultAdmin, address(this));
    }

    /*///////////////////////////////////////////////////////////////
                      Generic contract logic
  //////////////////////////////////////////////////////////////*/

    /// @dev Returns the type of the contract.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    /*///////////////////////////////////////////////////////////////
                      Getters
  //////////////////////////////////////////////////////////////*/

    /// @dev TODO
    function getContracts()
        external
        view
        returns (address[] memory _contracts)
    {
        _contracts = contracts.values();
    }

    /// @dev TODO
    function count() external view returns (uint256 count_) {
        count_ = contracts.length();
    }

    /*///////////////////////////////////////////////////////////////
                      Setters
  //////////////////////////////////////////////////////////////*/

    // @dev add child contracts
    function addContract(address _contractAddress)
        external
        minRole(CONTRACT_ADMIN_ROLE)
    {
        bool added = contracts.add(_contractAddress);
        require(added, "failed to add contract");
        emit ContractAdded(_contractAddress);
    }

    // @dev remove child contracts
    function removeContract(address _contractAddress)
        external
        minRole(CONTRACT_ADMIN_ROLE)
    {
        bool removed = contracts.remove(_contractAddress);
        require(removed, "failed to remove contract");
        emit ContractRemoved(_contractAddress);
    }

    // @dev set metadata

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function setOwner(address _newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), "!ADMIN");
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri)
        external
        minRole(CONTRACT_ADMIN_ROLE)
    {
        contractURI = _uri;
    }

    /// @dev Lets a contract admin set the address for the access registry.
    function setAccessRegistry(address _accessRegistry)
        external
        minRole(CONTRACT_ADMIN_ROLE)
    {
        accessRegistry = _accessRegistry;
    }

    /// @dev Lets a contract admin set the name for a project.
    function setName(string calldata _name) external minRole(PRODUCER_ROLE) {
        name = _name;
    }

    /*///////////////////////////////////////////////////////////////
                      Miscellaneous / Overrides
  //////////////////////////////////////////////////////////////*/

    function grantRole(bytes32 role, address account)
        public
        virtual
        override(AccessControlUpgradeable, IAccessControlUpgradeable)
        minRole(CONTRACT_ADMIN_ROLE)
    {
        // #TODO check if it still adds roles (enumerable)!
        super._grantRole(role, account);
        IPropsAccessRegistry(accessRegistry).add(account, address(this));
    }

    function revokeRole(bytes32 role, address account)
        public
        virtual
        override(AccessControlUpgradeable, IAccessControlUpgradeable)
        minRole(CONTRACT_ADMIN_ROLE)
    {
        // @dev ya'll can't take your own admin role, fool.
        if (role == DEFAULT_ADMIN_ROLE && account == owner()) revert();
        // #TODO check if it still adds roles (enumerable)!
        super._revokeRole(role, account);
        IPropsAccessRegistry(accessRegistry).remove(account, address(this));
    }

    /**
     * @dev Check if minimum role for function is required.
     */
    modifier minRole(bytes32 _role) {
        require(_hasMinRole(_role), "Not authorized");
        _;
    }

    function hasMinRole(bytes32 _role) public view virtual returns (bool) {
        return _hasMinRole(_role);
    }

    function _hasMinRole(bytes32 _role) internal view returns (bool) {
        // @dev does account have role?
        if (hasRole(_role, _msgSender())) return true;
        // @dev are we checking against default admin?
        if (_role == DEFAULT_ADMIN_ROLE) return false;
        // @dev walk up tree to check if user has role admin role
        return _hasMinRole(getRoleAdmin(_role));
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    uint256[49] private ___gap;
}
