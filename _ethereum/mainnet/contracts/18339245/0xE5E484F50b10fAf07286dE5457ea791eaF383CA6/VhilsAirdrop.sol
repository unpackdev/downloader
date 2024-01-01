// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./Strings.sol";

contract VhilsStakingReward is Ownable, ERC1155Burnable, ERC1155Supply {
  mapping(uint256 => string) public uris;
  mapping(bytes32 => bool) public batchMinted;

  constructor() ERC1155("ipfs://QmccqHGBFz44a1bQh6KGyFyxb6vLteik4SaTkwy1Wc2Gd8/") Ownable() {}

  function uri(uint256 tokenId) public view override returns (string memory) {
    if (bytes(uris[tokenId]).length > 0) {
      return uris[tokenId];
    }
    return string(abi.encodePacked(super.uri(tokenId), Strings.toString(tokenId)));
  }

  function mint(address[] memory to, uint256[] memory tokenIds, bytes32 batchHash) public onlyOwner {
    require(to.length == tokenIds.length, "to and tokenIds length mismatch");
    require(keccak256(abi.encode(to, tokenIds)) == batchHash, "batch hash mismatch");
    require(!batchMinted[batchHash], "batch already minted");

    for (uint256 i = 0; i < to.length; i++) {
      _mint(to[i], tokenIds[i], 1, "");
    }
    batchMinted[batchHash] = true;
  }

  function setBaseURI(string memory newuri) public onlyOwner {
    _setURI(newuri);
  }

  function setTokenURI(uint256[] memory tokenIds, string[] memory newuris) public onlyOwner {
    require(tokenIds.length == newuris.length, "tokenIds and newuris length mismatch");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uris[tokenIds[i]] = newuris[i];
    }
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override(ERC1155, ERC1155Supply) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
}
