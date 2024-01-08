// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";

import "./IArtworkStore.sol";
import "./ITRLabCore.sol";
import "./ERC2981Upgradeable.sol";
import "./LibArtwork.sol";

/// @title Interface of TRLab NFT core contract
/// @author Joe
/// @notice This is the interface of TRLab NFT core contract
contract TRLabCoreV2 is
    ITRLabCore,
    Initializable,
    ERC2981Upgradeable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // ---------------- params -----------------
    /// @dev internal id counter, do not use directly, use _getNextTokenId()
    CountersUpgradeable.Counter private _tokenIdCounter;
    /// @dev account address => approved or not
    mapping(address => bool) public override approvedTokenCreators;
    /// @dev token id => ArtworkRelease
    mapping(uint256 => LibArtwork.ArtworkRelease) public tokenIdToArtworkRelease;
    /// @dev artwork store contract address
    IArtworkStore public artworkStore;

    /// @dev reentrancy constants
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    /// @dev reentrancy status
    uint256 private _status;

    /// @dev Throws if called by any account other than the owner or approved creator
    modifier onlyOwnerOrCreator() {
        require(
            owner() == _msgSender() || approvedTokenCreators[_msgSender()],
            "caller is not the owner or approved creator"
        );
        _;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    function initialize(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _storeAddress
    ) public initializer {
        __ERC721_init(_tokenName, _tokenSymbol);
        __ERC2981_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        _status = _NOT_ENTERED;
        // counter starts from 0, increase to 1
        _tokenIdCounter.increment();
        setStoreAddress(_storeAddress);
    }

    /// @dev Set store address. Only called by the owner.
    function setStoreAddress(address _storeAddress) public override onlyOwner {
        artworkStore = IArtworkStore(_storeAddress);
        emit NewArtworkStore(_storeAddress);
    }

    /// @inheritdoc ITRLabCore
    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint256 _bps
    ) public override onlyOwner {
        Royalty memory r = Royalty({receiver: _receiver, bps: _bps});
        _setRoyalty(_tokenId, r);
    }

    /// @dev set the royalty of tokens. Can only be called by owner at emergency
    /// @param _tokenIds uint256[] the ids of the token
    /// @param _receiver address the receiver address of the royalty
    /// @param _bps uint256 the royalty percentage in bps
    function setTokensRoyalty(
        uint256[] calldata _tokenIds,
        address _receiver,
        uint256 _bps
    ) public override onlyOwner {
        Royalty memory r = Royalty({receiver: _receiver, bps: _bps});
        for (uint256 idx = 0; idx < _tokenIds.length; idx++) {
            uint256 id = _tokenIds[idx];
            _setRoyalty(id, r);
        }
    }

    /// @dev Set approved creator. Only called by the owner.
    function setApprovedCreator(address[] calldata creators, bool ok) external onlyOwner {
        for (uint256 idx = 0; idx < creators.length; idx++) {
            approvedTokenCreators[creators[idx]] = ok;
        }
    }

    /// @inheritdoc ITRLabCore
    function getArtwork(uint256 _artworkId) external view override returns (LibArtwork.Artwork memory artwork) {
        artwork = _getArtwork(_artworkId);
    }

    /// @inheritdoc ITRLabCore
    function createArtwork(
        uint32 _totalSupply,
        string calldata _metadataPath,
        address _royaltyReceiver,
        uint256 _royaltyBps
    ) external override whenNotPaused onlyOwnerOrCreator {
        _createArtwork(_msgSender(), _totalSupply, _metadataPath, _royaltyReceiver, _royaltyBps);
    }

    /// @inheritdoc ITRLabCore
    function createArtworkAndReleases(
        uint32 _totalSupply,
        string calldata _metadataPath,
        uint32 _numReleases,
        address _royaltyReceiver,
        uint256 _royaltyBps
    ) external override whenNotPaused onlyOwnerOrCreator {
        uint256 artworkId = _createArtwork(_msgSender(), _totalSupply, _metadataPath, _royaltyReceiver, _royaltyBps);
        _batchArtworkRelease(_msgSender(), artworkId, _numReleases);
    }

    /// @inheritdoc ITRLabCore
    function releaseArtwork(uint256 _artworkId, uint32 _numReleases)
        external
        override
        whenNotPaused
        onlyOwnerOrCreator
    {
        _batchArtworkRelease(_msgSender(), _artworkId, _numReleases);
    }

    /// @inheritdoc ITRLabCore
    function releaseArtworkForReceiver(
        address _receiver,
        uint256 _artworkId,
        uint32 _numReleases
    ) external override whenNotPaused onlyOwnerOrCreator {
        _batchArtworkRelease(_receiver, _artworkId, _numReleases);
    }

    /// @notice get the next token id, won't change state
    function getNextTokenId() public view override returns (uint256) {
        return _tokenIdCounter.current();
    }

    /// @notice burns an artwork, Once this function succeeds, this artwork
    /// will no longer be able to mint any more tokens.  Existing tokens need to be
    /// burned individually though.
    /// @param  _artworkId the id of the artwork to burn
    function burnArtwork(uint256 _artworkId) public onlyOwner {
        _burnArtwork(_artworkId);
    }

    /// @dev pause the contract
    function pause() public onlyOwner {
        _pause();
    }

    /// @dev unpause the contract
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public whenNotPaused {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    /// @notice returns ipfs uri of token
    /// @param tokenId uint256 id of token
    /// @return the ipfs uri
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }

    /**
     * Creates a new artwork object. Returns the artwork id.
     */
    function _createArtwork(
        address _creator,
        uint32 _totalSupply,
        string calldata _metadataPath,
        address _royaltyReceiver,
        uint256 _royaltyBps
    ) internal returns (uint256) {
        return artworkStore.createArtwork(_creator, _totalSupply, _metadataPath, _royaltyReceiver, _royaltyBps);
    }

    /**
     * Creates _count number of NFT token for artwork
     * Bumps up the print index by _count.
     * @param  _nftOwner address the owner of the NFT token
     * @param  _artworkId uint256 the artwork id
     * @param  _count uint256 how many tokens of this batch
     */
    function _batchArtworkRelease(
        address _nftOwner,
        uint256 _artworkId,
        uint32 _count
    ) internal nonReentrant {
        // Sanity check of _count number. Negative number will throw overflow exception
        require(_count < 10000, "Cannot print more than 10K tokens at once");
        LibArtwork.Artwork memory _artwork = _getArtwork(_artworkId);
        // If artwork not exists, its creator is address(0)
        require(_artwork.creator != address(0), "artwork not exists");

        // Get the old print index before increment.
        uint32 currentPrintIndex = _artwork.printIndex;

        // Increase print index before mint logic, check if increment valid. Saving gas if count exceeds maxSupply.
        _incrementArtworkPrintIndex(_artworkId, _count);

        string memory _tokenURI = _artwork.metadataPath;
        Royalty memory royalty = Royalty({receiver: _artwork.royaltyReceiver, bps: _artwork.royaltyBps});

        for (uint32 i = 0; i < _count; i++) {
            uint32 newPrintEdition = currentPrintIndex + 1 + i;
            LibArtwork.ArtworkRelease memory _artworkRelease = LibArtwork.ArtworkRelease({
                printEdition: newPrintEdition,
                artworkId: _artworkId
            });

            uint256 tokenId = _nextTokenId();
            tokenIdToArtworkRelease[tokenId] = _artworkRelease;

            // This will assign ownership and also emit the Transfer event as per ERC721
            _safeMint(_nftOwner, tokenId);
            _setTokenURI(tokenId, _tokenURI);
            _setRoyalty(tokenId, royalty);
            emit ArtworkReleaseCreated(tokenId, _nftOwner, _artworkId, newPrintEdition, _tokenURI);
        }
        emit ArtworkPrintIndexUpdated(_artworkId, currentPrintIndex + _count);
    }

    function _incrementArtworkPrintIndex(uint256 _artworkId, uint32 _count) internal {
        artworkStore.incrementArtworkPrintIndex(_artworkId, _count);
    }

    // this function changes _tokenIdCounter status
    function _nextTokenId() internal returns (uint256) {
        uint256 _nextId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        return _nextId;
    }

    function _getArtwork(uint256 artworkId) internal view returns (LibArtwork.Artwork memory) {
        return artworkStore.getArtwork(artworkId);
    }

    /**
     * Burns an artwork. Once this function succeeds, this artwork
     * will no longer be able to mint any more tokens.  Existing tokens need to be
     * burned individually though.
     * @param  _artworkId the id of the digital media to burn
     */
    function _burnArtwork(uint256 _artworkId) internal {
        LibArtwork.Artwork memory _artwork = _getArtwork(_artworkId);

        uint32 increment = _artwork.totalSupply - _artwork.printIndex;
        _incrementArtworkPrintIndex(_artworkId, increment);
        emit ArtworkBurned(_artworkId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
        delete tokenIdToArtworkRelease[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC2981Upgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
