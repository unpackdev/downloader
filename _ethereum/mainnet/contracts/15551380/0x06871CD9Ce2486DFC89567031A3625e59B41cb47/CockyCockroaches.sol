// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract CockyCockroaches is ERC721A, Ownable {
  uint32 public maxSupply;
  bool public isMintActive;
  string private _baseTokenURI;
  address public RANDOM_RATS_ADDR = 0xa7b839c910F0Eb62ce1BF6Bb28E93282aa495B7a;
  uint256 public PRICE;

  mapping(address => bool) private _hasRatOwnerMinted;


  constructor(uint32 supply, uint256 price) ERC721A("Cocky-Cockroaches", "CC") {
    maxSupply = supply;
    PRICE = price;
    isMintActive = true;
  }

  function ratOwnerMint() external {
    require(isMintActive, "Mint is not active yet");
    require(totalSupply() + 1 <= maxSupply, "Mint would exceed max supply of CC");

    bytes memory payload = abi.encodeWithSignature("balanceOf(address)", msg.sender);

    (bool success, bytes memory data) = RANDOM_RATS_ADDR.call(payload);

    require(success);

    (uint256 owned) = abi.decode(data, (uint256));

    require(owned > 0, "You do not own a rat");
    require(_hasRatOwnerMinted[msg.sender] == false, "You already minted your free CC");

    _safeMint(msg.sender, 1);
    _hasRatOwnerMinted[msg.sender] = true;
  }

  function mint(uint256 quantity) external payable {
    require(isMintActive, "Mint is not active yet");
    require(totalSupply() + quantity <= maxSupply, "Mint would exceed max supply of CC");
    require(msg.value >= PRICE * quantity, "Not enough ETH to buy NFT");
    
    _safeMint(msg.sender, quantity);
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