// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

/// @title TNFP Token Contract
/// @author NFP Swap
/// @notice Contract for minting TNFP tokens for a given NFT
contract TnfpToken is ERC1155, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _lastfNfpId;

    mapping(uint256 => string) private _tokenURIs;
    mapping(address => mapping(uint256 => mapping(uint => bool)))
        private _mintedProductTypes;
    address _tNfpTokenTraderAddress;

    constructor() ERC1155("https://nfp-swap.org/tnfp/{id}.json") {}

    event TnfpMinted(
        uint indexed itemId,
        address indexed nftAddress,
        uint256 indexed nftTokenId,
        uint256 amount,
        uint productType,
        address owner
    );

    /// @notice Set the trusted trader address
    function setTraderAddress(address tNfpTokenTraderAddress) public onlyOwner {
        _tNfpTokenTraderAddress = tNfpTokenTraderAddress;
    }

    /// @notice Allow TNFP token to be burned
    function burn(uint256 amount, uint256 id) public {
        _burn(msg.sender, id, amount);
    }

    /// @notice Allow batches of TNFP token to be burned
    function burnBatch(uint256[] memory amounts, uint256[] memory ids) public {
        _burnBatch(msg.sender, ids, amounts);
    }

    /// @notice Mint a TNFP token for a given NFT
    function mint(
        string memory tokenURI,
        address nftAddress,
        uint256 nftTokenId,
        uint256 amount,
        uint productType
    )
        public
        onlyNftOwner(msg.sender, nftAddress, nftTokenId)
        returns (uint256)
    {
        return
            _finaliseMint(
                tokenURI,
                nftAddress,
                nftTokenId,
                amount,
                productType,
                msg.sender
            );
    }

    /// @notice Mint a TNFP token for trusted market place for a given NFT owned by a user
    function mintProxy(
        string memory tokenURI,
        address nftAddress,
        uint256 nftTokenId,
        uint256 amount,
        uint productType,
        address originator
    )
        public
        onlyMarketPlace
        onlyNftOwner(originator, nftAddress, nftTokenId)
        returns (uint256)
    {
        return
            _finaliseMint(
                tokenURI,
                nftAddress,
                nftTokenId,
                amount,
                productType,
                _tNfpTokenTraderAddress
            );
    }

    /// @notice Final mint process for TNFP token
    function _finaliseMint(
        string memory tokenURI,
        address nftAddress,
        uint256 nftTokenId,
        uint256 amount,
        uint productType,
        address to
    ) private returns (uint256) {
        require(
            _mintedProductTypes[nftAddress][nftTokenId][productType] == false,
            "TNFP already minted for this NFT with product type"
        );
        _lastfNfpId.increment();
        uint256 newTokenId = _lastfNfpId.current();
        _setTokenUri(newTokenId, tokenURI);
        _mint(to, newTokenId, amount, "");
        _mintedProductTypes[nftAddress][nftTokenId][productType] = true;

        emit TnfpMinted(
            newTokenId,
            nftAddress,
            nftTokenId,
            amount,
            productType,
            to
        );

        return newTokenId;
    }

    /// @notice Mint a batch of TNFP tokens for a set of NFTs
    function mintBatch(
        string[] memory tokenURIs,
        address[] memory nftAddressses,
        uint256[] memory nftTokenIds,
        uint256[] memory amounts,
        uint256[] memory productTypes
    ) public returns (uint256[] memory) {
        require(
            amounts.length == nftAddressses.length,
            "Arrays should be the same length"
        );
        require(
            amounts.length == nftTokenIds.length,
            "Arrays should be the same length"
        );
        require(
            amounts.length == productTypes.length,
            "Arrays should be the same length"
        );
        uint256 totalItems = amounts.length;
        for (uint256 i = 0; i < totalItems; i++) {
            ERC721 nft = ERC721(nftAddressses[i]);
            require(
                _msgSender() == nft.ownerOf(nftTokenIds[i]),
                "You must own the NFT being minted to a tNFP"
            );
            require(
                _mintedProductTypes[nftAddressses[i]][nftTokenIds[i]][
                    productTypes[i]
                ] == false,
                "TNFP already minted for this NFT with product type"
            );
        }
        uint256[] memory newTokenIds = new uint256[](totalItems);
        for (uint256 i = 0; i < totalItems; i++) {
            _lastfNfpId.increment();
            newTokenIds[i] = _lastfNfpId.current();
            _setTokenUri(newTokenIds[i], tokenURIs[i]);
        }
        _mintBatch(msg.sender, newTokenIds, amounts, "");
        return newTokenIds;
    }

    /// @notice Returns token number of minted TNFPs
    function totalMinted() public view returns (uint256) {
        return _lastfNfpId.current();
    }

    /// @notice Determines if NFT already has a TNFP minted for a particular NFT/Product type.
    function isProductMinted(
        address nftAddress,
        uint256 nftTokenId,
        uint productType
    ) public view returns (bool) {
        return _mintedProductTypes[nftAddress][nftTokenId][productType];
    }

    /// @notice Get the unique token uri for a TNFP.
    function uri(uint256 tokenId) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    /// @notice Set the unique token URI for a particular TNFP which is stored to IPFS.
    function _setTokenUri(uint256 tokenId, string memory tokenURI) private {
        _tokenURIs[tokenId] = tokenURI;
    }

    /// @notice Modifier that only allows calls to be made by trusted TNFP marketplace
    modifier onlyMarketPlace() {
        require(
            _msgSender() == _tNfpTokenTraderAddress,
            "Can only be called by tnfp marketplace"
        );
        _;
    }

    /// @notice Modifier to check airdrop is still active
    modifier onlyNftOwner(
        address ownerAddress,
        address nftAddress,
        uint256 nftTokenId
    ) {
        ERC721 nft = ERC721(nftAddress);
        require(
            ownerAddress == nft.ownerOf(nftTokenId),
            "You must own the NFT being minted to a tNFP"
        );
        _;
    }
}
