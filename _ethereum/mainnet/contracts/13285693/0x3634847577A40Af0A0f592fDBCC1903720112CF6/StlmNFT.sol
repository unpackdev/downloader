// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./Ownable.sol";

/// @title StlmNFT
/// @notice A contract for living modules in the starlink ecosystem
contract StlmNFT is ERC721("StarLink Living Module", "STLM"), Ownable {

    /// @notice event emitted when token URI is updated
    event StlmTokenUriUpdated(
        uint256 indexed _tokenId,
        string _tokenUri
    );

    /// @dev current max tokenId
    uint256 public tokenIdPointer;

    /**
     */
    constructor() public {
        tokenIdPointer = 0;
    }

    /**
     @notice Mints a living module
     @dev Only owner can mint token
     @param _beneficiary Recipient of the NFT
     @param _tokenUri URI for the token being minted
     @return uint256 The token ID of the token that was minted
     */
    function mint(address _beneficiary, string calldata _tokenUri) external onlyOwner returns (uint256) {
        tokenIdPointer = tokenIdPointer.add(1);
        uint256 tokenId = tokenIdPointer;
        _safeMint(_beneficiary, tokenId);
        _setTokenURI(tokenId, _tokenUri);
        emit StlmTokenUriUpdated(tokenId, _tokenUri);
        return tokenId;
    }

    /**
     @notice Batch mints living modules
     @dev Only owner can mint tokens
     @param _owners List of owners of tokens created
     @param _uris List of metadata uri of tokens creating
     @return uint256[] List of IDs of tokens created
     */
    function batchMint(address[] calldata _owners, string[] calldata _uris) external onlyOwner returns (uint256[] memory ) {
        require(_owners.length == _uris.length, "Length should be same");
        uint256[] memory tokenIds = new uint256[](_owners.length);
        for(uint256 i=0; i<_owners.length; i++) {
            tokenIdPointer = tokenIdPointer.add(1);
            uint256 tokenId = tokenIdPointer;
            _safeMint(_owners[i], tokenId);
            _setTokenURI(tokenId, _uris[i]);
            emit StlmTokenUriUpdated(tokenId, _uris[i]);
            tokenIds[i] = tokenId;
        }
        return tokenIds;
    }

    /**
     @notice Updates the token URI of a given token
     @dev Only admin or smart contract
     @param _tokenId The ID of the token being updated
     @param _tokenUri The new URI
     */
    function setTokenURI(uint256 _tokenId, string calldata _tokenUri) external onlyOwner {
        _setTokenURI(_tokenId, _tokenUri);
        emit StlmTokenUriUpdated(_tokenId, _tokenUri);
    }
}