// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./console.sol";

contract BoundedExpansions is ERC721A, Ownable {

  constructor() ERC721A("BoundedExpansions", "BE_VDL3") {}

  function mint(uint256 quantity) external payable onlyOwner {
    // _safeMint's second argument now takes in a quantity, not a tokenId.
    _safeMint(msg.sender, quantity);
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overriden in child contracts.
   */
  function _baseURI() internal override pure returns (string memory) {
    return 'https://bafybeie33swatvcfhcc64adn4bcupuk5jwfpbybauuqsmahdqdti3ptpye.ipfs.dweb.link/metadata/';
  }

  /**
   * To change the starting tokenId, please override this function.
   */
  function _startTokenId() internal override pure returns (uint256) {
    return 1;
  }

}

