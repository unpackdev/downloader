// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";

contract PumpItLoomdart is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {

  bool private _hasBeenMinted;
  string private _tokenURI;

  constructor(string memory tokenURI_) ERC721("PumpItLoomdart", "PIL") {
    _tokenURI = tokenURI_;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return _tokenURI;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function mint(address to) public onlyOwner {
    require(!_hasBeenMinted, "Token has already been minted.");
    _safeMint(to, 0);
    _hasBeenMinted = true;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
  internal
  whenNotPaused
  override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  // The following functions are overrides required by Solidity.

  function supportsInterface(bytes4 interfaceId)
  public
  view
  override(ERC721, ERC721Enumerable)
  returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
