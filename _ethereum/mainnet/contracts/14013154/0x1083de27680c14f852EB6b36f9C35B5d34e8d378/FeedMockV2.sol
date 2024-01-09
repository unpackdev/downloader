// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Strings.sol";
import "./Feed.sol";

contract FeedMockV2 is Feed {
  using Strings for uint256;

  function tokenURI(uint256 tokenId)
    public
    view
    override(Feed)
    returns (string memory)
  {
    return string(abi.encodePacked(BASE_URI, tokenId.toString(), "/v2"));
  }
}
