// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

// import "./IERC721.sol";

/**
* @dev Required interface of an ERC721 compliant contract, optional metadata extension, as defined in the
* https://eips.ethereum.org/EIPS/eip-721[EIP].
*   Note: the ERC-165 identifier for this interface is 0x5b5e139f.
*/
interface IERC721Metadata /* is IERC721 */ {
  // **************************************
  // *****            VIEW            *****
  // **************************************
    /// @dev A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory);
    /// @dev An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory);
    /// @dev A distinct Uniform Resource Identifier (URI) for a given asset.
    ///   Throws if `tokenId_` is not a valid NFT. URIs are defined in RFC 3986.
    ///   The URI may point to a JSON file that conforms to the "ERC721 Metadata JSON Schema".
    function tokenURI(uint256 tokenId_) external view returns (string memory);
  // **************************************
}
