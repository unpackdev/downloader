//SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity ^0.8.8;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC165Storage.sol";
import "./IERC165.sol";
import "./ERC721.sol";
import "./IERC721Metadata.sol";

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

/*
 * @title CancerNFT
 * @dev How to use this:
 *   - Ideally, first finalize your NFTs on IPFS. They should be in a folder,
 *     named 0 to N (no file extension) in order to be auto-linked during minting.
 *     Use the ipfs URL with a suffix of '/' to refer to your collection during deployment.
 *   - If you cannot finalize the NFT collection on IPFS by deployment, that's ok.
 *     Instead, you can come back later and call `setTokenURI` in order to set individual IPFS hashes.
 *   - Either way, you should eventually call `transferOwnership` in order to finalize the collection.
 *
 */
contract CancerNFT is ERC721, IERC2981, Ownable {
    // ERC165
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    mapping(bytes4 => bool) private _supportedInterfaces;

    /// Each NFT can have its own settings
    /// @param royaltyRecipient The address the royalty goes to
    /// @param royaltyFraction A fraction as a number between 0 and 100
    struct NFT {
        address royaltyRecipient;
        uint8 royaltyFraction;
    }

    /// The index of the NFT corresponds to its path in IPFS
    mapping(uint256 => NFT) tokens;
    uint256 public totalSupply;

    string public baseURI;

    event BaseURIChanged(string x, string y);
    event RoyaltyFractionChanged(uint256 indexed tokenId, uint8 x, uint8 y);
    event RoyaltyRecipientChanged(uint256 indexed tokenId, address x, address y);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) ERC721(name_, symbol_) {
        _registerInterface(_INTERFACE_ID_ERC2981);
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        baseURI = baseURI_;
    }

    // Governance Functions, which should be disabled eventually via `transferOwnership()`

    /// Minting 500 at a time just fits in a large block, 250 will be an average block
    /// @param number How many NFTs to mint
    /// @param royaltyRecipient The address that should receive royalties for this batch
    /// @param royaltyFraction The fraction as a number between 0 and 100 to apply for royalties
    function mint(
        uint256 number,
        address royaltyRecipient,
        uint8 royaltyFraction
    ) external onlyOwner {
        require(royaltyFraction >= 0 && royaltyFraction <= 100, "0 to 100 only");
        require(royaltyRecipient != address(0), "not the 0 address");
        address to = owner();
        for (uint256 i = 0; i < number; i++) {
            _mintHelper(to, royaltyRecipient, royaltyFraction);
        }
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        emit BaseURIChanged(baseURI, baseURI_);
        baseURI = baseURI_;
    }

    function setRoyaltyFraction(uint256 tokenId, uint8 royaltyFraction) external onlyOwner {
        emit RoyaltyFractionChanged(tokenId, tokens[tokenId].royaltyFraction, royaltyFraction);
        tokens[tokenId].royaltyFraction = royaltyFraction;
    }

    function setRoyaltyRecipient(uint256 tokenId, address royaltyRecipient) external onlyOwner {
        emit RoyaltyRecipientChanged(tokenId, tokens[tokenId].royaltyRecipient, royaltyRecipient);
        tokens[tokenId].royaltyRecipient = royaltyRecipient;
    }

    // NFT Metadata

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, "/", Strings.toString(tokenId)));
    }

    // ERC2981 - Royalty Suggestions

    function royaltyInfo(uint256 tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return (tokens[tokenId].royaltyRecipient, uint256((_salePrice * tokens[tokenId].royaltyFraction) / 100));
    }

    // Internal

    function _mintHelper(
        address to,
        address royaltyRecipient,
        uint8 royaltyFraction
    ) internal {
        _safeMint(to, totalSupply);
        tokens[totalSupply].royaltyRecipient = royaltyRecipient;
        tokens[totalSupply].royaltyFraction = royaltyFraction;
        totalSupply++;
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
