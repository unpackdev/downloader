// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "./IERC1155.sol";
import "./IERC2981.sol";
import "./IERC1155MetadataURI.sol";

interface ILoveNFTShared is IERC1155, IERC1155MetadataURI, IERC2981 {
  struct MintRequest {
    uint256 tokenId;
    uint256 price;
    uint128 startTimestamp;
    uint128 endTimestamp;
    string uri;
    address royaltyRecipient;
    uint96 royaltyFraction;
    bytes32 uid;
  }

  function redeem(address account, MintRequest calldata _req, bytes calldata signature) external;

  function exists(uint256 tokenId) external view returns (bool);

  function feeDenominator() external pure returns (uint96);

  function decodeTokenId(uint256 tokenId) external pure returns (address, uint256, uint256);

  function encodeTokenId(address creator, uint256 index, uint256 collection) external pure returns (uint256);
}
