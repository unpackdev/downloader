//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";

import "./TokenIdentifiers.sol";
import "./AssetContract.sol";

/**
 * @title OasisXStorefront
 * @notice Shared asset contract - A contract for easily creating custom assets on OasisX
 * @author OasisX Protocol | cryptoware.eth
 */
contract OasisXStorefront is AssetContract, ReentrancyGuard {
    /// @notice Migration contract address
    OasisXStorefront public migrationTarget;

    mapping(address => bool) public sharedProxyAddresses;

    struct Ownership {
        uint256 id;
        address owner;
    }

    using TokenIdentifiers for uint256;

    event CreatorChanged
    (
        uint256 indexed _id,
        address indexed _creator
    );

    event ProxyRegistryAddressChanged
    (
        address indexed ProxyRegistry
    );

    event SharedProxyAdded
    (
        address indexed SharedProxy
    );

    event SharedProxyRemoved
    (
        address indexed SharedProxy
    );

    event MigrationDisabled();

    mapping(uint256 => address) internal _creatorOverride;

    /**
     * @dev Require msg.sender to be the creator of the token id
     */
    modifier creatorOnly(uint256 _id) {
        require(
            _isCreatorOrProxy(_id, _msgSender()),
            "OasisXStorefront#creatorOnly: ONLY_CREATOR_ALLOWED"
        );
        _;
    }

    /**
     * @dev Require the caller to own the full supply of the token
     */
    modifier onlyFullTokenOwner(uint256 _id) {
        require(
            _ownsTokenAmount(_msgSender(), _id, _id.tokenMaxSupply()),
            "OasisXStorefront#onlyFullTokenOwner: ONLY_FULL_TOKEN_OWNER_ALLOWED"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        string memory _templateURI,
        address _migrationAddress
    ) AssetContract(_name, _symbol, _proxyRegistryAddress, _templateURI) {
        require
        (
            _proxyRegistryAddress != address(0),
            "OasisXStoreFront: Address cannot be 0"
        );
        migrationTarget = OasisXStorefront(_migrationAddress);
    }

    /**
     * @dev Allows owner to change the proxy registry
     */
    function setProxyRegistryAddress(address _address) external onlyOwnerOrProxy {
        require
        (
            _address != address(0),
            "OasisXStorefront: Address cannot be 0"
        );
        require
        (
            proxyRegistryAddress != _address,
            "OasisXStorefront : Address cannot be same as previous"
        );
        proxyRegistryAddress = _address;
        emit ProxyRegistryAddressChanged(_address);
    }

    /**
     * @dev Allows owner to add a shared proxy address
     */
    function addSharedProxyAddress(address _address) external onlyOwnerOrProxy {
        require
        (
            _address != address(0),
            "OasisXStorefront: Address cannot be 0"
        );
        require
        (
            !sharedProxyAddresses[_address],
            "OasisXStorefront : Address already exist"
        );
        sharedProxyAddresses[_address] = true;
        emit SharedProxyAdded(_address);
    }

    /**
     * @dev Allows owner to remove a shared proxy address
     */
    function removeSharedProxyAddress(address _address)
        external
        onlyOwnerOrProxy
    {
        require
        (
            sharedProxyAddresses[_address] == true,
            "OasisXStorefront: Address doesn't exist!"
        );
        sharedProxyAddresses[_address] = false;
        emit SharedProxyRemoved(_address);
    }

    /**
     * @dev Allows owner to disable the ability to migrate
     */
    function disableMigrate() public onlyOwnerOrProxy {
        migrationTarget = OasisXStorefront(address(0));
        emit MigrationDisabled();
    }

    /**
     * @dev Migrate state from previous contract
     */
    function migrate(Ownership[] memory _ownerships) public onlyOwnerOrProxy {
        OasisXStorefront _migrationTarget = migrationTarget;
        require(
            _migrationTarget != OasisXStorefront(address(0)),
            "OasisXStorefront#migrate: MIGRATE_DISABLED"
        );

        string memory _migrationTargetTemplateURI = _migrationTarget
            .templateURI();

        for (uint256 i = 0; i < _ownerships.length; ++i) {
            uint256 id = _ownerships[i].id;
            address owner = _ownerships[i].owner;

            require(
                owner != address(0),
                "OasisXStorefront#migrate: ZERO_ADDRESS_NOT_ALLOWED"
            );

            uint256 previousAmount = _migrationTarget.balanceOf(owner, id);

            if (previousAmount == 0) {
                continue;
            }

            _mint(owner, id, previousAmount, "");

            if (
                keccak256(bytes(_migrationTarget.uri(id))) !=
                keccak256(bytes(_migrationTargetTemplateURI))
            ) {
                _setPermanentURI(id, _migrationTarget.uri(id));
            }
        }
    }

    /**
     * @notice minting function
     * @param _to the address to send the minted token to
     * @param _id id of the token to mint
     * @param _quantity uantity of tokens to mint
     * @param _data data to send with mint
     */
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public override nonReentrant creatorOnly(_id) {
        _mint(_to, _id, _quantity, _data);
    }

    /**
     * @notice Batch mint function
     * @param _to the address to send the minted token to
     * @param _ids id of the token to mint
     * @param _quantities uantity of tokens to mint
     * @param _data data to send with mint
     */
    function batchMint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    ) public override nonReentrant {
        for (uint256 i = 0; i < _ids.length; i++) {
            require(
                _isCreatorOrProxy(_ids[i], _msgSender()),
                "OasisXStorefront#_batchMint: ONLY_CREATOR_ALLOWED"
            );
        }
        _batchMint(_to, _ids, _quantities, _data);
    }

    /////////////////////////////////
    // CONVENIENCE CREATOR METHODS //
    /////////////////////////////////

    /**
     * @dev Will update the URI for the token
     * @param _id The token ID to update. msg.sender must be its creator, the uri must be impermanent,
     *            and the creator must own all of the token supply
     * @param _uri New URI for the token.
     */
    function setURI(uint256 _id, string memory _uri)
        public
        override
        creatorOnly(_id)
        onlyImpermanentURI(_id)
        onlyFullTokenOwner(_id)
    {
        _setURI(_id, _uri);
    }

    /**
     * @dev setURI, but permanent
     */
    function setPermanentURI(uint256 _id, string memory _uri)
        public
        override
        creatorOnly(_id)
        onlyImpermanentURI(_id)
        onlyFullTokenOwner(_id)
    {
        _setPermanentURI(_id, _uri);
    }

    /**
     * @dev Change the creator address for given token
     * @param _to   Address of the new creator
     * @param _id  Token IDs to change creator of
     */
    function setCreator(uint256 _id, address _to) external creatorOnly(_id) {
        require(
            _to != address(0),
            "OasisXStorefront#setCreator: INVALID_ADDRESS."
        );
        _creatorOverride[_id] = _to;
        emit CreatorChanged(_id, _to);
    }

    /**
     * @dev Get the creator for a token
     * @param _id   The token id to look up
     */
    function creator(uint256 _id) public view returns (address) {
        if (_creatorOverride[_id] != address(0)) {
            return _creatorOverride[_id];
        } else {
            return _id.tokenCreator();
        }
    }

    /**
     * @dev Get the maximum supply for a token
     * @param _id   The token id to look up
     */
    function maxSupply(uint256 _id) public pure returns (uint256) {
        return _id.tokenMaxSupply();
    }

    /**
     * @notice Override ERC1155Tradable for birth events
     * @param _id id of token
     */
    function _origin(uint256 _id) internal pure override returns (address) {
        return _id.tokenCreator();
    }

    function _requireMintable(address _address, uint256 _id) internal view {
        require(
            _isCreatorOrProxy(_id, _address),
            "OasisXStorefront#_requireMintable: ONLY_CREATOR_ALLOWED"
        );
    }

    /**
     * @notice returns remaining supply
     * @param _id id of token
     */
    function _remainingSupply(uint256 _id)
        internal
        view
        override
        returns (uint256)
    {
        return maxSupply(_id) - totalSupply(_id);
    }

    /**
     * @notice Checking if address is creator of id
     * @param _id id of token
     * @param _address address of creator or proxy
     */
    function _isCreatorOrProxy(uint256 _id, address _address)
        internal
        view
        override
        returns (bool)
    {
        address creator_ = creator(_id);
        return creator_ == _address || _isProxyForUser(creator_, _address);
    }

    /**
     * @notice Overrides ERC1155Tradable to allow a shared proxy address
     * @param _user address of the user
     * @param _address address of shared proxy
     */
    function _isProxyForUser(address _user, address _address)
        internal
        view
        override
        returns (bool)
    {
        if (sharedProxyAddresses[_address]) {
            return true;
        }
        return super._isProxyForUser(_user, _address);
    }
}
