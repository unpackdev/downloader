// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract GodjiraPunks is ERC721A, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using ECDSA for bytes32;
  using Strings for uint256;

  uint256 public constant MAX_GODJIRA_PUNKS = 2222;
  uint256 public MAX_GODJIRA_PUNKS_PER_PURCHASE = 20;
  uint256 public constant GODJIRA_PUNKS_PRICE = 0.0099 ether;
  uint256 public constant RESERVED_GODJIRA_PUNKS = 5;
  
  string public tokenBaseURI;
  bool public mintActive = false;
  bool public reservesMinted = false;
  bool public reveal = false;

  /**
   * @dev Contract Methods
   */
  constructor(
    uint256 _maxGodjiraPunksPerPurchase
  ) ERC721A("Godjira Punks", "GP", _maxGodjiraPunksPerPurchase, MAX_GODJIRA_PUNKS) {}
  /********
   * Mint *
   ********/
  function publicMint(uint256 _quantity) external payable {
    require(mintActive, "Sale is not active.");
    require(_quantity <= MAX_GODJIRA_PUNKS_PER_PURCHASE, "Quantity is more than allowed per transaction.");
    require(msg.value >= GODJIRA_PUNKS_PRICE.mul(_quantity), "The ether value sent is not correct");

    _safeMintGodjiraPunks(_quantity);
  }

  function _safeMintGodjiraPunks(uint256 _quantity) internal {
    require(_quantity > 0, "You must mint at least 1 Godjira Punk nft");
    require(totalSupply().add(_quantity) <= MAX_GODJIRA_PUNKS, "This purchase would exceed max supply");
    _safeMint(msg.sender, _quantity);
  }

  /*
   * Note: Mint reserved Godjira Punks.
   */

  function mintReservedGodjiraPunks() external onlyOwner {
    require(!reservesMinted, "Reserves have already been minted.");
    require(totalSupply().add(RESERVED_GODJIRA_PUNKS) <= MAX_GODJIRA_PUNKS, "This mint would exceed max supply");
    _safeMint(msg.sender, RESERVED_GODJIRA_PUNKS);

    reservesMinted = true;
  }

  function setMintActive(bool _active) external onlyOwner {
    mintActive = _active;
  }

  function setReveal(bool _reveal) external onlyOwner {
    reveal = _reveal;
  }

  function setTokenBaseURI(string memory _baseURI) external onlyOwner {
    tokenBaseURI = _baseURI;
  }

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    if (!reveal) {
      return string(abi.encodePacked(tokenBaseURI));
    }

    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked(tokenBaseURI, _tokenId.toString(), ".json"));
  }

  /**************
   * Withdrawal *
   **************/

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}
