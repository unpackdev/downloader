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

/**
 * @dev Core project implementation
 */
abstract contract ProjectCoreUpgradeable is
    Initializable,
    IProjectCoreUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC165Upgradeable
{
    using StringsUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    /**
     * External interface identifiers for royalties
     */

    /**
     *  @dev ProjectCore
     *
     *  bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *
     *  => 0xbb3bafd6 = 0xbb3bafd6
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_PROJECTCORE = 0xbb3bafd6;

    /**
     *  @dev Rarible: RoyaltiesV1
     *
     *  bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *  bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     *
     *  => 0xb9c4d9fb ^ 0x0ebd4c7f = 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    /**
     *  @dev Foundation
     *
     *  bytes4(keccak256('getFees(uint256)')) == 0xd5a06d4c
     *
     *  => 0xd5a06d4c = 0xd5a06d4c
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_FOUNDATION = 0xd5a06d4c;

    /**
     *  @dev EIP-2981
     *
     * bytes4(keccak256("royaltyInfo(uint256,uint256,bytes)")) == 0x6057361d
     *
     * => 0x6057361d = 0x6057361d
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x6057361d;

    uint256 _tokenCount;

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

    // Royalty configurations
    mapping(address => address payable[]) internal _managerRoyaltyReceivers;
    mapping(address => uint256[]) internal _managerRoyaltyBPS;
    mapping(uint256 => address payable[]) internal _tokenRoyaltyReceivers;
    mapping(uint256 => uint256[]) internal _tokenRoyaltyBPS;

    /**
     * @dev initializer
     */
    function __ProjectCore_init() internal initializer {
        __ReentrancyGuard_init_unchained();
        __ERC165_init_unchained();
        __ProjectCore_init_unchained();
        _tokenCount = 0;
    }

    function __ProjectCore_init_unchained() internal initializer {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IProjectCoreUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId) ||
            interfaceId == _INTERFACE_ID_ROYALTIES_PROJECTCORE ||
            interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE ||
            interfaceId == _INTERFACE_ID_ROYALTIES_FOUNDATION ||
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981;
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
     * @dev totalSupply
     */
    function totalSupply() public view override returns (uint256) {
        return _tokenCount;
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

    /**
     * Helper to get royalties for a token
     */
    function _getRoyalties(uint256 tokenId) internal view returns (address payable[] storage, uint256[] storage) {
        return (_getRoyaltyReceivers(tokenId), _getRoyaltyBPS(tokenId));
    }

    /**
     * Helper to get royalty receivers for a token
     */
    function _getRoyaltyReceivers(uint256 tokenId) internal view returns (address payable[] storage) {
        if (_tokenRoyaltyReceivers[tokenId].length > 0) {
            return _tokenRoyaltyReceivers[tokenId];
        } else if (_managerRoyaltyReceivers[_tokensManager[tokenId]].length > 0) {
            return _managerRoyaltyReceivers[_tokensManager[tokenId]];
        }
        return _managerRoyaltyReceivers[address(this)];
    }

    /**
     * Helper to get royalty basis points for a token
     */
    function _getRoyaltyBPS(uint256 tokenId) internal view returns (uint256[] storage) {
        if (_tokenRoyaltyBPS[tokenId].length > 0) {
            return _tokenRoyaltyBPS[tokenId];
        } else if (_managerRoyaltyBPS[_tokensManager[tokenId]].length > 0) {
            return _managerRoyaltyBPS[_tokensManager[tokenId]];
        }
        return _managerRoyaltyBPS[address(this)];
    }

    function _getRoyaltyInfo(uint256 tokenId, uint256 value)
        internal
        view
        returns (
            address receiver,
            uint256 amount,
            bytes memory data
        )
    {
        address payable[] storage receivers = _getRoyaltyReceivers(tokenId);
        require(receivers.length <= 1, "More than 1 royalty receiver");

        if (receivers.length == 0) {
            return (address(this), 0, data);
        }
        return (receivers[0], (_getRoyaltyBPS(tokenId)[0] * value) / 10000, data);
    }

    /**
     * Set royalties for a token
     */
    function _setRoyalties(
        uint256 tokenId,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) internal {
        require(receivers.length == basisPoints.length, "Invalid input");
        uint256 totalBasisPoints;
        for (uint256 i = 0; i < basisPoints.length; i++) {
            totalBasisPoints += basisPoints[i];
        }
        require(totalBasisPoints < 10000, "Invalid total royalties");
        _tokenRoyaltyReceivers[tokenId] = receivers;
        _tokenRoyaltyBPS[tokenId] = basisPoints;
        emit RoyaltiesUpdated(tokenId, receivers, basisPoints);
    }

    /**
     * Set royalties for all tokens of an manager
     */
    function _setRoyaltiesManager(
        address manager,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) internal {
        require(receivers.length == basisPoints.length, "Invalid input");
        uint256 totalBasisPoints;
        for (uint256 i = 0; i < basisPoints.length; i++) {
            totalBasisPoints += basisPoints[i];
        }
        require(totalBasisPoints < 10000, "Invalid total royalties");
        _managerRoyaltyReceivers[manager] = receivers;
        _managerRoyaltyBPS[manager] = basisPoints;
        if (manager == address(this)) {
            emit DefaultRoyaltiesUpdated(receivers, basisPoints);
        } else {
            emit ManagerRoyaltiesUpdated(manager, receivers, basisPoints);
        }
    }

    uint256[36] private __gap;
}
