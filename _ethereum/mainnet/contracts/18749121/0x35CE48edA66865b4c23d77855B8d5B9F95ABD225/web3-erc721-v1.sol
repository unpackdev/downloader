// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Royalty.sol";
import "./Counters.sol";

import "./web3-latchable.sol";
import "./web3-uploadable.sol";

contract Web3ERC721V1 is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Royalty,
    Ownable,
    ReentrancyGuard,
    Web3Latchable,
    Web3Uploadable
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    event FactoryUpdated(address newFactory);
    event RoyaltyUpdated(address feeReceiver, uint96 fee);
    event TokenMinted(uint256 indexed tokenId, uint256 indexed uuid);
    event TokenRoyaltyUpdated(
        uint256 indexed tokenId,
        address feeReceiver,
        uint96 fee
    );
    event TokenMetadataUpdated(uint256 indexed tokenId, string uri);

    uint256 internal constant _TRANSFERABLE = 1 << 0;
    uint256 internal constant _LATCHABLE = 1 << 1;
    uint256 internal constant _UPLOADABLE = 1 << 2;

    Counters.Counter private _tokenIdCounter;
    address private _factory;
    uint256 private _behaviorFlags;

    /// @dev Throws if called by any account other than the owner or the factory.
    modifier onlyOwnerOrFactory() {
        _checkOwnerOrFactory();
        _;
    }

    /// @dev Throws if the token is not minted or is already transferred
    modifier recentlyMinted(uint256 _tokenId) {
        _checkTokenMintedRecently(_tokenId);
        _;
    }

    /// @notice Creates a new NFT collection
    /// @param _name Name of the collection
    /// @param _symbol Symbol of the collection
    /// @param _flags Behaviour flags ((1st)transferable, (2nd)latcheable, (3rd)uploadable)
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _flags
    ) ERC721(_name, _symbol) {
        _factory = _msgSender();
        _behaviorFlags = _flags;
        _setDefaultRoyalty(_msgSender(), 0);
    }

    /// @notice set a new factory contract approved to mint tokens and manage this collection
    /// @param _newFactory Address of the new factory
    function setFactory(
        address _newFactory
    ) public onlyOwnerOrFactory nonReentrant {
        _factory = _newFactory;
        emit FactoryUpdated(_newFactory);
    }

    /// @notice set a new latch proxy to check latch status
    /// @param _newProxy Address of the new latch proxy
    function setLatchProxy(address _newProxy) public onlyOwnerOrFactory {
        _setLatchProxy(_newProxy);
    }

    /// @notice Sets an operator for contract owner's tokens
    /// @param _operator Address of the operator
    /// @param _approved Whether the operator is approved or not
    function setContractOperator(
        address _operator,
        bool _approved
    ) public onlyOwnerOrFactory nonReentrant {
        _setApprovalForAll(owner(), _operator, _approved);
    }

    /// @notice Sets the default royalty fee for the collection
    /// @param _feeReceiver Address of the fee receiver
    /// @param _fee Royalty fee in basis points
    function setDefaultRoyalty(
        address _feeReceiver,
        uint96 _fee
    ) public onlyOwnerOrFactory nonReentrant {
        _setDefaultRoyalty(_feeReceiver, _fee);
        emit RoyaltyUpdated(_feeReceiver, _fee);
    }

    /// @notice Sets the royalty fee for a given token
    /// @param _tokenId token id of the token
    /// @param _fee Royalty fee in basis points
    function setTokenRoyalty(
        uint256 _tokenId,
        uint96 _fee
    ) public onlyOwnerOrFactory nonReentrant {
        (address feeReceiver, ) = royaltyInfo(_tokenId, 0);
        _setTokenRoyalty(_tokenId, feeReceiver, _fee);
        emit TokenRoyaltyUpdated(_tokenId, feeReceiver, _fee);
    }

    /// @notice Updates the metadata uri for a given token if it has not been transferred
    /// @param _tokenId token id of the token
    /// @param _uri IPFS cid of the metadata
    function setTokenUri(
        uint256 _tokenId,
        string memory _uri
    ) public onlyOwnerOrFactory recentlyMinted(_tokenId) nonReentrant {
        _setTokenURI(_tokenId, _uri);
        emit TokenMetadataUpdated(_tokenId, _uri);
    }

    /// @notice Mints a new token for a given recipient with ipfs metadata and returns tokenId
    /// @param _recipient Address of the recipient
    /// @param _uri IPFS cid of the metadata
    /// @param _fee Royalty fee in basis points for the nft, overriding default (0 for default)
    /// @param _uuid uuid of the nft for correlation purposes
    /// @return tokenId of the newly minted token
    function safeMint(
        address _recipient,
        string memory _uri,
        uint96 _fee,
        uint256 _uuid
    ) public onlyOwnerOrFactory nonReentrant returns (uint256) {
        return _safeMint(_recipient, _uri, _fee, _uuid);
    }

    /// @notice Mints a batch of new tokens for a given recipient with ipfs metadata, returning the first tokenId
    /// @param _recipients Addresses of the recipients
    /// @param _uris IPFS cids of the metadata
    /// @param _fees Royalty fees in basis points for the nfts, overriding default (0 for default)
    /// @param _uuids uuids of the nfts for correlation purposes
    /// @return tokenId of the first newly minted token
    function safeMintBatch(
        address[] memory _recipients,
        string[] memory _uris,
        uint96[] memory _fees,
        uint256[] memory _uuids
    ) public onlyOwnerOrFactory nonReentrant returns (uint256) {
        require(_recipients.length == _uris.length, "invalid input");
        require(_recipients.length == _fees.length, "invalid input");

        uint256 tokenId = _tokenIdCounter.current();
        for (uint256 i = 0; i < _uris.length; i++) {
            _safeMint(_recipients[i], _uris[i], _fees[i], _uuids[i]);
        }
        return tokenId;
    }

    /// @notice burns a token
    /// @param _tokenId token id of the token
    function burn(uint256 _tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "caller is not token owner or approved"
        );
        _burn(_tokenId);
    }

    /// @notice updates a filepart for a given token
    /// @param _tokenId token id of the token
    /// @param _partIndex index of the filepart
    /// @param _data data of the filepart
    function uploadFilePart(
        uint256 _tokenId,
        uint256 _partIndex,
        bytes calldata _data
    ) public onlyOwnerOrFactory nonReentrant {
        _checkUploadability();
        _requireMinted(_tokenId);
        _uploadFilePart(_tokenId, _partIndex, _data);
    }

    /// @notice check if collection is transferable beyond the first transaction
    function isTransferable() public view returns (bool) {
        return (_behaviorFlags & _TRANSFERABLE) != 0;
    }

    /// @notice check if collection is latcheable using Telefonica's Latch
    function isLatchable() public view returns (bool) {
        return (_behaviorFlags & _LATCHABLE) != 0;
    }

    /// @notice check if collection supports uploading of fileparts per token
    function isUploadable() public view returns (bool) {
        return (_behaviorFlags & _UPLOADABLE) != 0;
    }

    /// @dev internal logic for minting wih uris, fees and correlator
    function _safeMint(
        address _recipient,
        string memory _uri,
        uint96 _fee,
        uint256 _uuid
    ) private returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        emit TokenMinted(tokenId, _uuid);
        _safeMint(_recipient, tokenId);
        _setTokenURI(tokenId, _uri);
        emit TokenMetadataUpdated(tokenId, _uri);
        (address feeReceiver, ) = royaltyInfo(tokenId, 0);
        _setTokenRoyalty(tokenId, feeReceiver, _fee);
        emit TokenRoyaltyUpdated(tokenId, feeReceiver, _fee);
        return tokenId;
    }

    /// @dev Throws if the sender is not the owner or the factory.
    function _checkOwnerOrFactory() internal view virtual {
        require(
            owner() == _msgSender() || _factory == _msgSender(),
            "Ownable: caller is not the owner"
        );
    }

    /// @dev Throws if the token is not minted or is already transferred
    /// @param _tokenId token id of the token
    function _checkTokenMintedRecently(uint256 _tokenId) private view {
        _requireMinted(_tokenId);
        require(owner() == ownerOf(_tokenId), "token has been transferred");
    }

    /// @dev transfers are limited depending on flags
    /// @param _from address of the sender
    function _checkTransferability(address _from) private view {
        if (!isTransferable()) {
            require(
                _from == owner() || _from == address(0),
                "transfer not allowed"
            );
        }
    }

    /// @dev latchable collections need to check latch status
    function _checkLatchability() private view {
        if (isLatchable()) {
            require(isLatchOpen(), "latch closed for caller");
        }
    }

    /// @dev non uploadable collections do not allow filepart uploads
    function _checkUploadability() private view {
        require(isUploadable(), "upload not allowed");
    }

    /// @dev this collection only works with IPFS metadata
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    /// @dev override of _beforeTokenTransfer to enforce collection flags
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _firstTokenId,
        uint256 _batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        _checkTransferability(_from);
        if (_from != address(0)) {
            _checkLatchability();
        }
        return
            super._beforeTokenTransfer(_from, _to, _firstTokenId, _batchSize);
    }

    /// @dev override of _approve to enforce collection flags
    function _approve(address _to, uint256 _tokenId) internal virtual override {
        _checkLatchability();
        super._approve(_to, _tokenId);
    }

    /// @dev override of _setApprovalForAll to enforce collection flags
    function _setApprovalForAll(
        address _owner,
        address _operator,
        bool _approved
    ) internal virtual override {
        _checkLatchability();
        super._setApprovalForAll(_owner, _operator, _approved);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(_tokenId);
    }

    function _burn(
        uint256 _tokenId
    ) internal override(ERC721, ERC721URIStorage, ERC721Royalty) {
        super._burn(_tokenId);
    }
}
