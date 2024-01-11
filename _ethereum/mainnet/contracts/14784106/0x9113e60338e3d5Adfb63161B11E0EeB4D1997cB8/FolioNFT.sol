// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./ERC721Royalty.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

/// @title ED3N NFT
/// @author passage.xyz
/// @notice folio x passage

contract FolioNFT is ERC721, ERC721Royalty, ERC721URIStorage, Ownable {
    using Strings for uint256;

    mapping (uint256 => uint256) public lastTransferTime;
    string private defaultMetadataBaseURI;
    string private unlockedMetadataBaseURI;
    string private unlockedSpecialMetadataBaseURI;
    
    /// @notice Upon deployment, this mints two tokens
    /// @param _defaultMetadataBaseURI The base URI for the metadata when the tokens are in the hidden state
    /// @param _unlockedMetadataBaseURI The base URI for the metadata when the tokens are in the unlocked state
    /// @param _unlockedSpecialMetadataBaseURI The base URI for the metadata when the tokens are in the special unlocked state
    /// @param _tokenName The name of the collection (e.g. SecretSong)
    /// @param _tokenSymbol The symbol for the collection (e.g. SONG)
    /// @param _mintWallet The address of the wallet that will receive the two minted tokens upon deployment
    /// @param _royaltyWallet The address of the wallet to designated to receive royalty payments
    /// @param _royaltyPercent The number representing the percentage of royalty fees out of 100 (e.g. 10 = 10% royalty)
    constructor(
        string memory _defaultMetadataBaseURI,
        string memory _unlockedMetadataBaseURI,
        string memory _unlockedSpecialMetadataBaseURI,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _mintWallet,
        address _royaltyWallet,
        uint96 _royaltyPercent
    ) ERC721(_tokenName, _tokenSymbol) {
        defaultMetadataBaseURI = _defaultMetadataBaseURI;
        unlockedMetadataBaseURI = _unlockedMetadataBaseURI;
        unlockedSpecialMetadataBaseURI = _unlockedSpecialMetadataBaseURI;
        
        super._setDefaultRoyalty(_royaltyWallet, _royaltyPercent);

        mint(_mintWallet, 1);
        mint(_mintWallet, 2);
    }

    function mint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId);
    }

    function resetTimestamp(uint256 tokenId) internal {
        lastTransferTime[tokenId] = block.timestamp;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        resetTimestamp(tokenId);
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // setting denominator to 100 to make it easier
    function _feeDenominator() internal pure virtual override returns (uint96) {
        return 100;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Updates the royalty details to a new wallet address and percentage
    /// @param royaltyWallet The address of the wallet to designated to receive royalty payments
    /// @param royaltyPercent The number representing the percentage of royalty fees out of 100 (e.g. 10 = 10% royalty)
    function setRoyalty(
        address royaltyWallet,
        uint96 royaltyPercent
    ) external onlyOwner {
        super._setDefaultRoyalty(royaltyWallet, royaltyPercent);
    }

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) public view virtual override returns (address receiver, uint256 royaltyAmount) {
        return super.royaltyInfo(_tokenId, _salePrice);
    }

    /// @notice Determines the URI for a given token based on the duration of asset possesstion
    /// @dev Throws if `tokenId` is not a valid NFT
    /// @param tokenId - the NFT asset queried for its URI
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        if (lastTransferTime[tokenId] < (block.timestamp - 14 days)) {
            return bytes(unlockedSpecialMetadataBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        unlockedSpecialMetadataBaseURI,
                        tokenId.toString()
                    )
                )
                : "";
        } else if (lastTransferTime[tokenId] >= (block.timestamp - 14 days)
            && lastTransferTime[tokenId] < (block.timestamp - 7 days)) {
            return bytes(unlockedMetadataBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        unlockedMetadataBaseURI,
                        tokenId.toString()
                    )
                )
                : "";
        } else {
            return bytes(defaultMetadataBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        defaultMetadataBaseURI,
                        tokenId.toString()
                    )
                )
                : "";
        }
    }
}
