// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract RandomRats is ERC721A, Ownable {
  uint16 public maxSupply;
  bool public isMintActive;
  string private _baseTokenURI;

  constructor(uint16 supply) ERC721A("Random Rats", "RR") {
    maxSupply = supply;
    isMintActive = false;
  }

  function mint() external {
    require(isMintActive, "Mint is not active yet");
    require(totalSupply() + 1 <= maxSupply, "Mint would exceed max supply of RR");
    require(_numberMinted(msg.sender) < 1, "Mint would exceed your allowed mints");

    _safeMint(msg.sender, 1);
  }

  function withdraw() external onlyOwner {
    address payable to = payable(0xcA230E83F37D905B266d6b227dA2f4f162753CD2);
    to.transfer(address(this).balance);
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  function activateMint() external onlyOwner {
    require(isMintActive == false, "Mint is already active");

    isMintActive = true;
  }

  function deactivateMint() external onlyOwner {
    require(isMintActive == true, "Mint is already deactivated");

    isMintActive = false;
  }

  function burn(uint256 tokenId) external {
      super._burn(tokenId, true);
  }
}

