// SPDX-License-Identifier: MIT

/*********************************
************;;;;; ;;;;;;**********
***********;KKKKK KKKKKK;*********
***********;KKooo oooooo;*********
**********;.KK... ....o.;*********
**********;.KK... o.....;*********
***********KKKo.. .o.o..;*********
***********;KKo.. ......;*********
*************KKKo ...KK***********
***********;;;KKK KKKK;;**********
*********;;KKKKKK KKKKKK;;********
********;KKKKKooo oooKKKKK;*******
********;KK;K.... ....K;KK;*******
********;KK;K.... ....K;KK;*******
**********************************/

pragma solidity ^0.8.20;

import "./ERC721A.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract MetaMorons is ERC721A, ERC2981, Ownable, ReentrancyGuard {
  uint public maxSupply = 5000;
  uint256 public maxMintPerTx = 2;
  bool public isMinting = false;
  string private baseUri = "";

  constructor() Ownable(msg.sender) ERC721A("MetaMorons", "MORON") {
    _safeMint(msg.sender, 50);
  }

  function mint(uint32 numberOfTokens) external {
    require(isMinting, "Minting is currently paused.");
    require(numberOfTokens <= maxMintPerTx, "Exceeds max number of tokens per transaction.");
    require(_totalMinted() + numberOfTokens <= maxSupply, "Exceeds total supply.");
    _safeMint(msg.sender, numberOfTokens);
  }

  function privateMint(uint32 numberOfTokens, address receiver) external onlyOwner {
    require(_totalMinted() + numberOfTokens <= maxSupply, "Exceeds total supply.");
    _safeMint(receiver, numberOfTokens);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "Token does not exist.");
    return bytes(_baseURI()).length > 0 ? string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json")) : "";
  }

  function changeMintState() external onlyOwner {
    isMinting = !isMinting;
  }

  function setBaseUri(string memory uri) external onlyOwner {
    baseUri = uri;
  }

  function setMaxMintPerTx(uint256 max) external onlyOwner {
    maxMintPerTx = max;
  }

  function withdraw() external payable onlyOwner {
    (bool success,) = payable(owner()).call{value: address(this).balance}("");
    require(success);
  }

  function setRoyalties(address receiver, uint96 feeNumerator) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
    return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseUri;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
}