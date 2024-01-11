// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract JunkyardK9000 is ERC721, Ownable {
  string internal uri = "https://api.junkyarddogs.io/k9000?tokenId=";
  uint256 public totalSupply = 0;
  uint256 public maxSupply = 88;
  mapping(uint256=>address) public minters;
  uint256[] public builtK9000;

  constructor() ERC721("JunkyardK9000", "JYK") {}

  function craft(uint256 tokenId, bytes memory signature) public {
    require(minters[tokenId] == address(0), "K9000 already built");
    require(totalSupply < maxSupply, "Supply exhausted");
    bytes32 messageHash = keccak256(abi.encodePacked("craft k9000", msg.sender, tokenId));
    bytes32 digest = ECDSA.toEthSignedMessageHash(messageHash);

    address signer = ECDSA.recover(digest, signature);
    require(signer == owner(), "Invalid signature");
    
    minters[tokenId] = msg.sender;
    builtK9000.push(tokenId);
    totalSupply += 1;

    _mint(msg.sender, tokenId);
  }

  function setUri(string memory u) public onlyOwner {
    uri = u;
  }

  function _baseURI() override internal view virtual returns (string memory) {
    return uri;
  }
}