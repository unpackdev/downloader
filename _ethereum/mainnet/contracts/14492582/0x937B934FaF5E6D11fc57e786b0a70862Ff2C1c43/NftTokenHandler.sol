// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

library NftTokenHandler {
  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
  bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

  function isOwner(
      address nftContract, 
      uint256 tokenId, 
      address account 
  ) internal view returns (bool) {

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC721)) {
        return IERC721(nftContract).ownerOf(tokenId) == account;
      }

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC1155)) {
        return IERC1155(nftContract).balanceOf(account, tokenId) > 0;
      }

      return false;

  }

  function isApproved(
      address nftContract, 
      uint256 tokenId, 
      address owner, 
      address operator
    ) internal view returns (bool) {

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC721)) {
        return IERC721(nftContract).getApproved(tokenId) == operator;
      }

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC1155)) {
        return IERC1155(nftContract).isApprovedForAll(owner, operator);
      }

      return false;
    }

  function transfer(
      address nftContract, 
      uint256 tokenId, 
      address from, 
      address to, 
      bytes memory data 
    ) internal {

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC721)) {
        return IERC721(nftContract).safeTransferFrom(from, to, tokenId);
      }

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC1155)) {
        return IERC1155(nftContract).safeTransferFrom(from, to, tokenId, 1, data);
      }

      revert("Unidentified NFT contract.");
    }
}