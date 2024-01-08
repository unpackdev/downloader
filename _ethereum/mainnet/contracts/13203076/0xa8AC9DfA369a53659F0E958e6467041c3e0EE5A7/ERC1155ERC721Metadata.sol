// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./IERC721Metadata.sol";
import "./IERC1155Metadata.sol";
import "./ERC1155ERC721.sol";

/// @title A metadata extension implementation for ERC1155 and ERC721
contract ERC1155ERC721Metadata is ERC1155ERC721, IERC721Metadata, IERC1155Metadata {
    mapping(uint256 => string) internal _tokenURI;

    bytes4 constant private INTERFACE_SIGNATURE_ERC1155Metadata = 0x0e89341c;
    bytes4 constant private INTERFACE_SIGNATURE_ERC721Metadata = 0x5b5e139f;
    
    /// @notice Query if a contract implements an interface
    /// @param _interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `_interfaceId`,
    ///  `false` otherwise
    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        pure
        virtual
        override
        returns (bool)
    {
        if (_interfaceId == INTERFACE_SIGNATURE_ERC1155Metadata ||
            _interfaceId == INTERFACE_SIGNATURE_ERC721Metadata) {
            return true;
        } else {
            return super.supportsInterface(_interfaceId);
        }
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given token.
    /// @dev URIs are defined in RFC 3986.
    /// The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".        
    /// @return URI string
    function uri(uint256 _tokenId)
        external
        view
        override
        returns (string memory)
    {
       return _tokenURI[_tokenId]; 
    }

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name()
        external
        pure
        override
        returns (string memory)
    {
        return "DigiQuick";
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol()
        external
        pure
        override
        returns (string memory)
    {
        return "DQ";
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId)
        external
        view
        override
        returns (string memory)
    {
        require(_nftOwners[_tokenId] != address(0), "Nft not exist");
        return _tokenURI[_tokenId];
    }

    function _setTokenURI(
        uint256 _tokenId,
        string memory _uri
    )
        internal
    {
        _tokenURI[_tokenId] = _uri;
    }
}
