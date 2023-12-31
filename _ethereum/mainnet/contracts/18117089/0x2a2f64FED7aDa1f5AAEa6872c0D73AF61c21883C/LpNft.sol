// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./ILpNft.sol";
import "./IMetadataGenerator.sol";
import "./MetadataGeneratorError.sol";
import "./IDittoPool.sol";
import "./IDittoPoolFactory.sol";
import "./OwnerTwoStep.sol";

import "./IERC721.sol";
import "./ERC721.sol";

/**
 * @title LpNft
 * @notice LpNft is an ERC721 NFT collection that tokenizes market makers' liquidity positions in the Ditto protocol.
 */
contract LpNft is ILpNft, ERC721, OwnerTwoStep {
    IDittoPoolFactory internal _dittoPoolFactory;

    ///@dev stores which pool each lpId corresponds to
    mapping(uint256 => IDittoPool) internal _lpIdToPool;

    /// @dev dittoPool address is the key of the mapping, underlying NFT address traded by that pool is the value
    mapping(address => IERC721) internal _approvedDittoPoolToNft;

    IMetadataGenerator internal _metadataGenerator;

    ///@dev NFTs are minted sequentially, starting at tokenId 1
    uint96 internal _nextId = 1;

    // ***************************************************************
    // * ========================= EVENTS ========================== *
    // ***************************************************************

    event LpNftAdminUpdatedMetadataGenerator(address metadataGenerator);
    event LpNftAdminUpdatedDittoPoolFactory(address dittoPoolFactory);

    // ***************************************************************
    // * ========================= ERRORS ========================== *
    // ***************************************************************
    error LpNftDittoFactoryOnly();
    error LpNftDittoPoolOnly();

    // ***************************************************************
    // * ==================== ADMIN FUNCTIONS ====================== *
    // ***************************************************************

    /**
     * @notice Constructor. Records the DittoPoolFactory address. Sets the owner of this contract. 
     *   Assigns the metadataGenerator address.
     */
    constructor(
        address initialOwner_,
        address metadataGenerator_
    ) ERC721("Ditto V1 LP Positions", "DITTO-V1-POS") {
        _transferOwnership(initialOwner_);
        _metadataGenerator = IMetadataGenerator(metadataGenerator_);
    }

    ///@inheritdoc ILpNft
    function setDittoPoolFactory(IDittoPoolFactory dittoPoolFactory_) external onlyOwner {
        _dittoPoolFactory = dittoPoolFactory_;
        emit LpNftAdminUpdatedDittoPoolFactory(address(dittoPoolFactory_));
    }

    ///@inheritdoc ILpNft
    function setMetadataGenerator(IMetadataGenerator metadataGenerator_) external onlyOwner {
        _metadataGenerator = metadataGenerator_;

        emit LpNftAdminUpdatedMetadataGenerator(address(metadataGenerator_));
    }

    ///@inheritdoc ILpNft
    function setApprovedDittoPool(address dittoPool_, IERC721 nft_) external onlyDittoPoolFactory {
        _approvedDittoPoolToNft[dittoPool_] = nft_;
    }

    // ***************************************************************
    // * =============== PROTECTED POOL FUNCTIONS ================== *
    // ***************************************************************

    ///@inheritdoc ILpNft
    function mint(address to_) public onlyApprovedDittoPools returns (uint256 lpId) {
        lpId = _nextId;

        _lpIdToPool[lpId] = IDittoPool(msg.sender);

        _safeMint(to_, lpId);
        unchecked {
            ++_nextId;
        }
    }

    ///@inheritdoc ILpNft
    function burn(uint256 lpId_) external onlyApprovedDittoPools {
        delete _lpIdToPool[lpId_];

        _burn(lpId_);
    }

    ///@inheritdoc ILpNft
    function emitMetadataUpdate(uint256 lpId_) external onlyApprovedDittoPools {
        emit MetadataUpdate(lpId_);
    }

    ///@inheritdoc ILpNft
    function emitMetadataUpdateForAll() external onlyApprovedDittoPools {
        if (totalSupply > 0) {
            emit BatchMetadataUpdate(1, totalSupply);
        }
    }

    // ***************************************************************
    // * ==================== AUTH MODIFIERS ======================= *
    // ***************************************************************
    /**
     * @notice Modifier that restricts access to the DittoPoolFactory contract 
     *   that created this NFT collection.
     */
    modifier onlyDittoPoolFactory() {
        if (msg.sender != address(_dittoPoolFactory)) {
            revert LpNftDittoFactoryOnly();
        }
        _;
    }

    /**
     * @notice Modifier that restricts access to DittoPool contracts that have been 
     *   approved to mint and burn liquidity position NFTs by the DittoPoolFactory.
     */
    modifier onlyApprovedDittoPools() {
        if (address(_approvedDittoPoolToNft[msg.sender]) == address(0)) {
            revert LpNftDittoPoolOnly();
        }
        _;
    }

    // ***************************************************************
    // * ====================== VIEW FUNCTIONS ===================== *
    // ***************************************************************

    ///@inheritdoc ILpNft
    function isApproved(address spender_, uint256 lpId_) external view returns (bool) {
        address ownerOf = ownerOf[lpId_];
        return (
            spender_ == ownerOf || isApprovedForAll[ownerOf][spender_]
                || spender_ == getApproved[lpId_]
        );
    }

    ///@inheritdoc ILpNft
    function isApprovedDittoPool(address pool_) external view returns (bool) {
        return address(_approvedDittoPoolToNft[pool_]) != address(0);
    }

    ///@inheritdoc ILpNft
    function getPoolForLpId(uint256 lpId_) external view returns (IDittoPool) {
        return _lpIdToPool[lpId_];
    }

    ///@inheritdoc ILpNft
    function getPoolAndOwnerForLpId(uint256 lpId_)
        external
        view
        returns (IDittoPool pool, address owner)
    {
        pool = _lpIdToPool[lpId_];
        owner = ownerOf[lpId_];
    }

    ///@inheritdoc ILpNft
    function getNftForLpId(uint256 lpId_) external view returns (IERC721) {
        return _approvedDittoPoolToNft[address(_lpIdToPool[lpId_])];
    }

    ///@inheritdoc ILpNft
    function getLpValueToken(uint256 lpId_) public view returns (uint256) {
        return _lpIdToPool[lpId_].getTokenBalanceForLpId(lpId_);
    }

    ///@inheritdoc ILpNft
    function getAllHeldNftIds(uint256 lpId_) external view returns (uint256[] memory) {
        return _lpIdToPool[lpId_].getNftIdsForLpId(lpId_);
    }

    ///@inheritdoc ILpNft
    function getNumNftsHeld(uint256 lpId_) public view returns (uint256) {
        return _lpIdToPool[lpId_].getNftCountForLpId(lpId_);
    }

    ///@inheritdoc ILpNft
    function getLpValueNft(uint256 lpId_) public view returns (uint256) {
        return getNumNftsHeld(lpId_) * _lpIdToPool[lpId_].basePrice();
    }

    ///@inheritdoc ILpNft
    function getLpValue(uint256 lpId_) external view returns (uint256) {
        return getLpValueToken(lpId_) + getLpValueNft(lpId_);
    }

    ///@inheritdoc ILpNft
    function dittoPoolFactory() external view returns (IDittoPoolFactory) {
        return _dittoPoolFactory;
    }

    ///@inheritdoc ILpNft
    function nextId() external view returns (uint256) {
        return _nextId;
    }

    ///@inheritdoc ILpNft
    function metadataGenerator() external view returns (IMetadataGenerator) {
        return _metadataGenerator;
    }

    // ***************************************************************
    // * ================== ERC721 INTERFACE ======================= *
    // ***************************************************************

    /**
     *  @notice returns storefront-level metadata to be viewed on marketplaces.
     */
    function contractURI() external view returns (string memory) {
        return _metadataGenerator.payloadContractUri();
    }

    /**
     * @notice returns the metadata for a given token, to be viewed on marketplaces and off-chain
     * @dev see [EIP-721](https://eips.ethereum.org/EIPS/eip-721) EIP-721 Metadata Extension
     * @param lpId_ the tokenId of the NFT to get metadata for
     */
    function tokenURI(uint256 lpId_) public view override returns (string memory) {
        IDittoPool pool = IDittoPool(_lpIdToPool[lpId_]);
        uint256 tokenCount = getLpValueToken(lpId_);
        uint256 nftCount = getNumNftsHeld(lpId_);
        try _metadataGenerator.payloadTokenUri(lpId_, pool, tokenCount, nftCount) returns (string memory tokenUri) {
            return tokenUri;
        } catch (bytes memory reason) {
            return MetadataGeneratorError.errorTokenUri(lpId_, address(pool), tokenCount, nftCount, reason);
        }
    }

    /**
     * @notice Whether or not this contract supports the given interface. 
     *   See [EIP-165](https://eips.ethereum.org/EIPS/eip-165)
     */
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165
            || interfaceId == 0x80ac58cd // ERC165 Interface ID for ERC721
            || interfaceId == 0x49064906 // ERC165 Interface ID for ERC4906
            || interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }
}
