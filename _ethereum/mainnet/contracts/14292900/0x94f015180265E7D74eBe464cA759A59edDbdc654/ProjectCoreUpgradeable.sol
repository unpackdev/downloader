// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./ReentrancyGuardUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./ERC165CheckerUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./Initializable.sol";

import "./IProjectTokenURIManager.sol";
import "./IProjectCoreUpgradeable.sol";
import "./ERC2981Upgradeable.sol";

/**
 * @dev Core project implementation
 */
abstract contract ProjectCoreUpgradeable is
    Initializable,
    ERC165Upgradeable,
    ERC2981Upgradeable,
    IProjectCoreUpgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    // Track registered managers data
    EnumerableSetUpgradeable.AddressSet internal _managers;
    EnumerableSetUpgradeable.AddressSet internal _blacklistedManagers;
    mapping(address => address) internal _managerPermissions;
    mapping(address => bool) internal _managerApproveTransfers;

    // For tracking which manager a token was minted by
    mapping(uint256 => address) internal _tokensManager;

    // The baseURI for a given manager
    mapping(address => string) private _managerBaseURI;
    mapping(address => bool) private _managerBaseURIIdentical;

    // The prefix for any tokens with a uri configured
    mapping(address => string) private _managerURIPrefix;

    // Mapping for individual token URIs
    mapping(uint256 => string) internal _tokenURIs;
    string internal _contractURI;

    /**
     * @dev initializer
     */
    function __ProjectCore_init() internal initializer {
        __ERC2981_init_unchained();
        __ERC165_init_unchained();
        __ReentrancyGuard_init_unchained();
        __ProjectCore_init_unchained();
    }

    function __ProjectCore_init_unchained() internal initializer {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return interfaceId == type(IProjectCoreUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Only allows registered managers to call the specified function
     */
    modifier managerRequired() {
        require(_managers.contains(msg.sender), "Must be registered manager");
        _;
    }

    /**
     * @dev Only allows non-blacklisted managers
     */
    modifier nonBlacklistRequired(address manager) {
        require(!_blacklistedManagers.contains(manager), "Manager blacklisted");
        _;
    }

    /**
     * @dev See {IProjectCore-contractURI}.
     */
    function contractURI() external view override returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev See {IProjectCore-getManagers}.
     */
    function getManagers() external view override returns (address[] memory managers) {
        managers = new address[](_managers.length());
        for (uint256 i = 0; i < _managers.length(); i++) {
            managers[i] = _managers.at(i);
        }
        return managers;
    }

    /**
     * @dev Register an manager
     */
    function _registerManager(
        address manager,
        string calldata baseURI,
        bool baseURIIdentical
    ) internal {
        require(manager != address(this), "Project: Invalid");
        require(manager.isContract(), "Project: Manager must be a contract");
        if (_managers.add(manager)) {
            _managerBaseURI[manager] = baseURI;
            _managerBaseURIIdentical[manager] = baseURIIdentical;
            emit ManagerRegistered(manager, msg.sender);
        }
    }

    /**
     * @dev Unregister an manager
     */
    function _unregisterManager(address manager) internal {
        if (_managers.remove(manager)) {
            emit ManagerUnregistered(manager, msg.sender);
        }
    }

    /**
     * @dev Blacklist an manager
     */
    function _blacklistManager(address manager) internal {
        require(manager != address(this), "Cannot blacklist yourself");
        if (_managers.remove(manager)) {
            emit ManagerUnregistered(manager, msg.sender);
        }
        if (_blacklistedManagers.add(manager)) {
            emit ManagerBlacklisted(manager, msg.sender);
        }
    }

    /**
     * @dev Set base token uri for an manager
     */
    function _managerSetBaseTokenURI(string calldata uri, bool identical) internal {
        _managerBaseURI[msg.sender] = uri;
        _managerBaseURIIdentical[msg.sender] = identical;
    }

    /**
     * @dev Set token uri prefix for an manager
     */
    function _managerSetTokenURIPrefix(string calldata prefix) internal {
        _managerURIPrefix[msg.sender] = prefix;
    }

    /**
     * @dev Set token uri for a token of an manager
     */
    function _managerSetTokenURI(uint256 tokenId, string calldata uri) internal {
        require(_tokensManager[tokenId] == msg.sender, "Invalid token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Set base token uri for tokens with no manager
     */
    function _setBaseTokenURI(string memory uri) internal {
        _managerBaseURI[address(this)] = uri;
    }

    /**
     * @dev Set token uri prefix for tokens with no manager
     */
    function _setTokenURIPrefix(string calldata prefix) internal {
        _managerURIPrefix[address(this)] = prefix;
    }

    /**
     * @dev Set token uri for a token with no manager
     */
    function _setTokenURI(uint256 tokenId, string calldata uri) internal {
        require(_tokensManager[tokenId] == address(this), "Invalid token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Retrieve a token's URI
     */
    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        address manager = _tokensManager[tokenId];
        require(!_blacklistedManagers.contains(manager), "Manager blacklisted");

        // 1. if tokenURI is stored in this contract, use it with managerURIPrefix if any
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            if (bytes(_managerURIPrefix[manager]).length != 0) {
                return string(abi.encodePacked(_managerURIPrefix[manager], _tokenURIs[tokenId]));
            }
            return _tokenURIs[tokenId];
        }

        // 2. if URI is controlled by manager, retrieve it from manager
        if (ERC165CheckerUpgradeable.supportsInterface(manager, type(IProjectTokenURIManager).interfaceId)) {
            return IProjectTokenURIManager(manager).tokenURI(address(this), tokenId);
        }

        // 3. use managerBaseURI with id or not
        if (!_managerBaseURIIdentical[manager]) {
            return string(abi.encodePacked(_managerBaseURI[manager], tokenId.toString()));
        } else {
            return _managerBaseURI[manager];
        }
    }

    /**
     * Get token manager
     */
    function _tokenManager(uint256 tokenId) internal view returns (address manager) {
        manager = _tokensManager[tokenId];

        require(manager != address(this), "No manager for token");
        require(!_blacklistedManagers.contains(manager), "Manager blacklisted");

        return manager;
    }

    function _setContractURI(string memory uri) internal {
        _contractURI = uri;
        emit ContractURISet(uri);
    }

    uint256[41] private __gap;
}
