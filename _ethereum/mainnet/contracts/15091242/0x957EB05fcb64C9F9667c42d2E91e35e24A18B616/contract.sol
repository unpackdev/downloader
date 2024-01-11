// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract StoryDaoPOAPNftNyc2022 is ERC1155, Ownable {
    mapping (uint256 => string) private _uris;

    constructor() ERC1155("") {
      _uris[0] = "";
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
      return(_uris[tokenId]);
    }

    function setTokenUri(uint256 tokenId, string calldata _uri) public onlyOwner {
      _uris[tokenId] = _uri;
    }

    function setTokenUriBatch(uint256[] calldata tokenIds, string[] calldata _newUris) public onlyOwner {
      for (uint256 i=0; i < tokenIds.length; i++) {
        _uris[tokenIds[i]] = _newUris[i];
      }
    }

    function mintTo(address to, uint256 tokenId) public onlyOwner {
      _mint(to, tokenId, 1, "");
    }

    function mintBatchSingleToken(address[] calldata to, uint256 tokenId) public onlyOwner {
      for (uint256 i=0; i < to.length; i++) {
        _mint(to[i], tokenId, 1, "");
      }
    }

    function mintBatchMultiToken(address[] calldata to, uint256[] calldata tokenIds) public onlyOwner {
      for (uint256 i=0; i < to.length; i++) {
        _mint(to[i], tokenIds[i], 1, "");
      }
    }
}
