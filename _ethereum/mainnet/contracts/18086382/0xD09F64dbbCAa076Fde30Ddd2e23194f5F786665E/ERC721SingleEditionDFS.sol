// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./IMetadataRenderer.sol";
import "./IEditionsMetadataRenderer.sol";
import "./IEditionCollection.sol";
import "./ERC721MinimizedBase.sol";
import "./IPostTransfer.sol";
import "./IPostBurn.sol";
import "./IERC721EditionMint.sol";
import "./MarketplaceFilterer.sol";
import "./ITokenManagerEditions.sol";
import "./ERC721AUpgradeable.sol";

/**
 * @title ERC721 Single Edition
 * @author highlight.xyz
 * @notice Single Edition Per Collection
 * @dev Using Decentralized File Storage
 */
contract ERC721SingleEditionDFS is
    IERC721EditionMint,
    IEditionCollection,
    ERC721MinimizedBase,
    ERC721AUpgradeable,
    MarketplaceFilterer
{
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice Throw when edition doesn't exist
     */
    error EditionDoesNotExist();

    /**
     * @notice Throw when token doesn't exist
     */
    error TokenDoesNotExist();

    /**
     * @notice Throw when attempting to mint, while mint is frozen
     */
    error MintFrozen();

    /**
     * @notice Throw when tokens on edition are sold out
     */
    error SoldOut();

    /**
     * @notice Throw when editionIds length is invalid
     */
    error InvalidEditionIdsLength();

    /**
     * @notice Throw when editionId is invalid
     */
    error InvalidEditionId();

    /**
     * @notice Contract metadata
     */
    string public contractURI;

    /**
     * @notice Total size of edition that can be minted
     */
    uint256 public size;

    /**
     * @notice Stores the edition's metadata
     */
    string public editionUri;

    /**
     * @notice Emitted when edition is created
     * @param size Edition size
     * @param editionTokenManager Token manager for edition
     */
    event EditionCreated(uint256 indexed size, address indexed editionTokenManager);

    /**
     * @notice Initializes the contract
     * @param data Data to initialize contract, in current format:
     * @ param creator Creator/owner of contract
     * @ param defaultRoyalty Default royalty object for contract (optional)
     * @ param _defaultTokenManager Default token manager for contract (optional)
     * @ param _contractURI Contract metadata
     * @ param _name Name of token edition
     * @ param _symbol Symbol of the token edition
     * @ param _size Edition size
     * @ param trustedForwarder Trusted minimal forwarder
     * @ param initialMinter Initial minter to register
     * @ param useMarketplaceFiltererRegistry Denotes whether to use marketplace filterer registry
     * @ param _editionUri Edition uri
     * @param _observability Observability contract address
     */
    function initialize(bytes calldata data, address _observability) external initializer {
        (
            address creator,
            IRoyaltyManager.Royalty memory defaultRoyalty,
            address _defaultTokenManager,
            string memory _contractURI,
            string memory _name,
            string memory _symbol,
            uint256 _size,
            address trustedForwarder,
            address initialMinter,
            bool useMarketplaceFiltererRegistry,
            string memory _editionUri
        ) = abi.decode(
                data,
                (
                    address,
                    IRoyaltyManager.Royalty,
                    address,
                    string,
                    string,
                    string,
                    uint256,
                    address,
                    address,
                    bool,
                    string
                )
            );

        _initialize(
            creator,
            defaultRoyalty,
            _defaultTokenManager,
            _contractURI,
            _name,
            _symbol,
            _editionUri,
            _size,
            trustedForwarder,
            initialMinter,
            useMarketplaceFiltererRegistry
        );

        IObservability(_observability).emitSingleEditionDeployed(address(this));
        observability = IObservability(_observability);
    }

    /**
     * @notice See {IERC721EditionMint-mintOneToRecipient}
     */
    function mintOneToRecipient(
        uint256 editionId,
        address recipient
    ) external onlyMinter nonReentrant returns (uint256) {
        if (_mintFrozen == 1) {
            _revert(MintFrozen.selector);
        }
        if (!_editionExists(editionId)) {
            _revert(EditionDoesNotExist.selector);
        }

        return _mintEditionsToOne(recipient, 1);
    }

    /**
     * @notice See {IERC721EditionMint-mintAmountToRecipient}
     */
    function mintAmountToRecipient(
        uint256 editionId,
        address recipient,
        uint256 amount
    ) external onlyMinter nonReentrant returns (uint256) {
        if (_mintFrozen == 1) {
            _revert(MintFrozen.selector);
        }
        if (!_editionExists(editionId)) {
            _revert(EditionDoesNotExist.selector);
        }

        return _mintEditionsToOne(recipient, amount);
    }

    /**
     * @notice See {IERC721EditionMint-mintOneToRecipients}
     */
    function mintOneToRecipients(
        uint256 editionId,
        address[] memory recipients
    ) external onlyMinter nonReentrant returns (uint256) {
        if (_mintFrozen == 1) {
            _revert(MintFrozen.selector);
        }
        if (!_editionExists(editionId)) {
            _revert(EditionDoesNotExist.selector);
        }
        return _mintEditions(recipients, 1);
    }

    /**
     * @notice See {IERC721EditionMint-mintAmountToRecipients}
     */
    function mintAmountToRecipients(
        uint256 editionId,
        address[] memory recipients,
        uint256 amount
    ) external onlyMinter nonReentrant returns (uint256) {
        if (_mintFrozen == 1) {
            _revert(MintFrozen.selector);
        }
        if (!_editionExists(editionId)) {
            _revert(EditionDoesNotExist.selector);
        }
        return _mintEditions(recipients, amount);
    }

    /**
     * @notice Set contract name
     * @param newName New name
     * @param newSymbol New symbol
     * @param newContractUri New contractURI
     */
    function setContractMetadata(
        string calldata newName,
        string calldata newSymbol,
        string calldata newContractUri
    ) external onlyOwner {
        _setContractMetadata(newName, newSymbol);
        contractURI = newContractUri;

        observability.emitContractMetadataSet(newName, newSymbol, newContractUri);
    }

    /**
     * @notice See {IEditionCollection-getEditionId}
     */
    function getEditionId(uint256 tokenId) external view returns (uint256) {
        if (!_exists(tokenId)) {
            _revert(TokenDoesNotExist.selector);
        }
        return 0;
    }

    /**
     * @notice See {IEditionCollection-getEditionDetails}
     */
    function getEditionDetails(uint256 editionId) external view returns (EditionDetails memory) {
        if (!_editionExists(editionId)) {
            _revert(EditionDoesNotExist.selector);
        }
        return _getEditionDetails();
    }

    /**
     * @notice See {IEditionCollection-getEditionsDetailsAndUri}
     */
    function getEditionsDetailsAndUri(
        uint256[] calldata editionIds
    ) external view returns (EditionDetails[] memory, string[] memory) {
        if (editionIds.length != 1) {
            _revert(InvalidEditionIdsLength.selector);
        }
        EditionDetails[] memory editionsDetails = new EditionDetails[](1);
        string[] memory uris = new string[](1);

        // expected to be 0, validated in editionURI call
        uint256 editionId = editionIds[0];

        uris[0] = editionURI(editionId);
        editionsDetails[0] = _getEditionDetails();

        return (editionsDetails, uris);
    }

    /**
     * @notice See {IERC721-transferFrom}. Overrides default behaviour to check associated tokenManager.
     */
    function transferFrom(address from, address to, uint256 tokenId) public payable override {
        ERC721AUpgradeable.transferFrom(from, to, tokenId);

        address _manager = defaultManager;
        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostTransfer).interfaceId)) {
            IPostTransfer(_manager).postTransferFrom(_msgSender(), from, to, tokenId);
        }

        observability.emitTransfer(from, to, tokenId);
    }

    /**
     * @notice See {IERC721-safeTransferFrom}. Overrides default behaviour to check associated tokenManager.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override {
        ERC721AUpgradeable.safeTransferFrom(from, to, tokenId, data);

        address _manager = defaultManager;
        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostTransfer).interfaceId)) {
            IPostTransfer(_manager).postSafeTransferFrom(_msgSender(), from, to, tokenId, data);
        }

        observability.emitTransfer(from, to, tokenId);
    }

    /**
     * @notice See {IERC721-burn}. Overrides default behaviour to check associated tokenManager.
     */
    function burn(uint256 tokenId) public nonReentrant {
        address _manager = defaultManager;
        address msgSender = _msgSender();

        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostBurn).interfaceId)) {
            address owner = ownerOf(tokenId);
            IPostBurn(_manager).postBurn(msgSender, owner, 0);
        } else {
            // default to restricting burn to owner or operator if a valid TM isn't present
            if (!_isApprovedOrOwner(msgSender, tokenId)) {
                _revert(Unauthorized.selector);
            }
        }

        _burn(tokenId);

        observability.emitTransfer(msgSender, address(0), tokenId);
    }

    /**
     * @notice Conforms to ERC-2981.
     * @param // Token id
     * @param _salePrice Sale price of token
     */
    function royaltyInfo(
        uint256 /* _tokenId */,
        uint256 _salePrice
    ) public view virtual override returns (address receiver, uint256 royaltyAmount) {
        return ERC721MinimizedBase.royaltyInfo(0, _salePrice);
    }

    /**
     * @notice Get URI for given edition id
     * @param editionId edition id to get uri for
     * @return base64-encoded json metadata object
     */
    function editionURI(uint256 editionId) public view returns (string memory) {
        if (!_editionExists(editionId)) {
            _revert(EditionDoesNotExist.selector);
        }
        return editionUri;
    }

    /**
     * @notice Get URI for given token id
     * @param tokenId token id to get uri for
     * @return base64-encoded json metadata object
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            _revert(TokenDoesNotExist.selector);
        }
        return editionUri;
    }

    /**
     * @notice Used to get token manager of token id
     * @param tokenId ID of the token
     */
    function tokenManagerByTokenId(uint256 tokenId) public view returns (address) {
        return tokenManager(tokenId);
    }

    /**
     * @notice Set an Edition's uri
     * @param editionId Edition to set uri for
     * @param _uri Uri to set on editions
     */
    function setEditionURI(uint256 editionId, string calldata _uri) external {
        if (editionId != 0) {
            _revert(InvalidEditionId.selector);
        }
        address _manager = defaultManager;
        address msgSender = _msgSender();

        if (_manager == address(0)) {
            address tempOwner = owner();
            if (msgSender != tempOwner) {
                _revert(Unauthorized.selector);
            }
        } else {
            if (
                !ITokenManagerEditions(_manager).canUpdateEditionsMetadata(
                    address(this),
                    msgSender,
                    0,
                    bytes(_uri),
                    ITokenManagerEditions.FieldUpdated.other
                )
            ) {
                _revert(Unauthorized.selector);
            }
        }

        editionUri = _uri;

        uint256[] memory _ids = new uint256[](1);
        _ids[0] = 0;
        string[] memory _uris = new string[](1);
        _uris[0] = _uri;
        observability.emitTokenURIsSet(_ids, _uris);
    }

    /**
     * @notice See {IERC721AUpgradeable-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165Upgradeable, ERC721AUpgradeable) returns (bool) {
        return ERC721AUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @notice Private function to mint without any access checks. Called by the public edition minting functions.
     * @param recipients Recipients of newly minted tokens
     * @param _amount Amount minted to each recipient
     */
    function _mintEditions(address[] memory recipients, uint256 _amount) internal returns (uint256) {
        uint256 recipientsLength = recipients.length;

        uint256 tempCurrent = _nextTokenId();
        uint256 endAt = tempCurrent + (recipientsLength * _amount) - 1;

        if (size != 0 && endAt > size) {
            _revert(SoldOut.selector);
        }

        for (uint256 i = 0; i < recipientsLength; i++) {
            _mint(recipients[i], _amount);
        }

        return endAt;
    }

    /**
     * @notice Private function to mint without any access checks. Called by the public edition minting functions.
     * @param recipient Recipient of newly minted token
     * @param _amount Amount minted to recipient
     */
    function _mintEditionsToOne(address recipient, uint256 _amount) internal returns (uint256) {
        uint256 tempCurrent = _nextTokenId();
        uint256 endAt = tempCurrent + _amount - 1;

        if (size != 0 && endAt > size) {
            _revert(SoldOut.selector);
        }

        _mint(recipient, _amount);

        return endAt;
    }

    /**
     * @notice Used for meta-transactions
     */
    function _msgSender() internal view override(ERC721MinimizedBase, ContextUpgradeable) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /**
     * @notice Used for meta-transactions
     */
    function _msgData() internal view override(ERC721MinimizedBase, ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    /**
     * @dev For more efficient reverts.
     */
    function _revert(
        bytes4 errorSelector
    ) internal pure override(ERC721AUpgradeable, ERC721MinimizedBase, MarketplaceFilterer) {
        ERC721AUpgradeable._revert(errorSelector);
    }

    /**
     * @notice Used to initialize contract
     * @param creator Creator/owner of contract
     * @param defaultRoyalty Default royalty object for contract (optional)
     * @param _defaultTokenManager Default token manager for contract (optional)
     * @param _contractURI Contract metadata
     * @param _name Name of token edition
     * @param _symbol Symbol of the token edition
     * @param _editionUri Edition uri (metadata)
     * @param _size Edition size
     * @param trustedForwarder Trusted minimal forwarder
     * @param initialMinter Initial minter to register
     * @param useMarketplaceFiltererRegistry Denotes whether to use marketplace filterer registry
     */
    function _initialize(
        address creator,
        IRoyaltyManager.Royalty memory defaultRoyalty,
        address _defaultTokenManager,
        string memory _contractURI,
        string memory _name,
        string memory _symbol,
        string memory _editionUri,
        uint256 _size,
        address trustedForwarder,
        address initialMinter,
        bool useMarketplaceFiltererRegistry
    ) private {
        __ERC721MinimizedBase_initialize(creator, defaultRoyalty, _defaultTokenManager);
        __ERC721A_init(_name, _symbol);
        __ERC2771ContextUpgradeable__init__(trustedForwarder);
        // deprecate but keep input for backwards-compatibility:
        // __MarketplaceFilterer__init__(useMarketplaceFiltererRegistry);
        size = _size;
        editionUri = _editionUri;
        _minters.add(initialMinter);
        contractURI = _contractURI;

        emit EditionCreated(_size, _defaultTokenManager);
    }

    /**
     * @notice Get edition details
     */
    function _getEditionDetails() private view returns (EditionDetails memory) {
        return EditionDetails(this.name(), size, _nextTokenId() - 1, 1);
    }

    /**
     * @notice Returns whether `editionId` exists.
     */
    function _editionExists(uint256 editionId) private pure returns (bool) {
        return editionId == 0;
    }
}
