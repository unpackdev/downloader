// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./TokenIdentifiers.sol";
import "./AssetContract.sol";

/**
 * @title AssetContractShared
 * Jungle shared asset contract - A contract for easily creating custom assets on Jungle
 */
contract AssetContractShared is AssetContract, ReentrancyGuardUpgradeable, UUPSUpgradeable {

    mapping(address => bool) public sharedProxyAddresses;

    struct Ownership {
        uint256 id;
        address owner;
    }

    using TokenIdentifiers for uint256;

    event CreatorChanged(uint256 indexed _id, address indexed _creator);

    mapping(uint256 => address) internal _creatorOverride;

    /**
     * @dev Require msg.sender to be the creator of the token id
     */
    modifier creatorOnly(uint256 _id) {
        require(
            _isCreatorOrProxy(_id, _msgSender()),
            "AssetContractShared#creatorOnly: ONLY_CREATOR_ALLOWED"
        );
        _;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        string memory _templateURI,
        uint256 _platformMintingfee,
        address _royaltyFeeRecipient,
        address _defaultFeeController,
        address _contractOwner
    ) external initializer {
        require(_royaltyFeeRecipient != address(0), "Invalid RoyaltyFeeRecipient" );
        require(_proxyRegistryAddress != address(0), "Invalid ProxyRegistry");
        require(_contractOwner != address(0), "Invalid owner");

        __UUPSUpgradeable_init();
        __AssetContract_init(_name, _symbol, _proxyRegistryAddress, _templateURI, _platformMintingfee, _royaltyFeeRecipient, _defaultFeeController);
        _transferOwnership(_contractOwner);
    }

    /**
     * @dev Allows owner to change the proxy registry. Can be set to zero address if admin decided. 
     */
    function setProxyRegistryAddress(address _address) external onlyOwnerOrProxy {
        proxyRegistryAddress = _address;
    }

    /**
     * @dev Allows owner to add a shared proxy address
     */
    function addSharedProxyAddress(address _address) external onlyOwnerOrProxy {
        require(_address != address(0), "SharedProxyAddress cannot be zero address");
        sharedProxyAddresses[_address] = true;
    }

    /**
     * @dev Allows owner to remove a shared proxy address
     */
    function removeSharedProxyAddress(address _address)
    external
    onlyOwnerOrProxy
    {
        require(_address != address(0), "Invalid Address");
        delete sharedProxyAddresses[_address];
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public override nonReentrant creatorOnly(_id) {
        _mint(_to, _id, _quantity, _data);
    }

    function batchMint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    ) public override nonReentrant {
        for (uint256 i = 0; i < _ids.length; i++) {
            require(
                _isCreatorOrProxy(_ids[i], _msgSender()),
                "AssetContractShared#_batchMint: ONLY_CREATOR_ALLOWED"
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
    external
    override
    creatorOnly(_id)
    onlyImpermanentURI(_id)
    {
        _setURI(_id, _uri);
    }

    /**
     * @dev setURI, but permanent
     */
    function setPermanentURI(uint256 _id, string memory _uri)
    external
    override
    creatorOnly(_id)
    onlyImpermanentURI(_id)
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
            "AssetContractShared#setCreator: INVALID_ADDRESS."
        );
        _creatorOverride[_id] = _to;
        emit CreatorChanged(_id, _to);
    }

    /**
     * @dev Set the royalty percent for an NFT
     * @param _tokenId Token ID of NFT to update the royalty percent
     * @param _feeNumerator Numerator for Royalty fee percent
     */
    function setTokenRoyalty(uint256 _tokenId, uint96 _feeNumerator) external creatorOnly(_tokenId){
        require(_feeNumerator <= royaltyFeeLimit, "Royalty fee exceeded royalty fee limit");
        _setTokenRoyalty(_tokenId, royaltyFeeRecipient, _feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function resetTokenRoyalty(uint256 _tokenId) external creatorOnly(_tokenId) {
        _resetTokenRoyalty(_tokenId);
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

    //Only owner function for upgrading proxy.
    function _authorizeUpgrade(address) internal override onlyOwner {}
    
    // Override ERC1155Tradable for birth events
    function _origin(uint256 _id) internal pure override returns (address) {
        return _id.tokenCreator();
    }

    function _requireMintable(address _address, uint256 _id) internal view {
        require(
            _isCreatorOrProxy(_id, _address),
            "AssetContractShared#_requireMintable: ONLY_CREATOR_ALLOWED"
        );
    }

    function _remainingSupply(uint256 _id)
    internal
    view
    override
    returns (uint256)
    {
        return maxSupply(_id) - totalSupply(_id);
    }

    function _isCreatorOrProxy(uint256 _id, address _address)
    internal
    view
    override
    returns (bool)
    {
        address creator_ = creator(_id);
        return creator_ == _address || _isProxyForUser(creator_, _address);
    }

    // Overrides ERC1155Tradable to allow a shared proxy address
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