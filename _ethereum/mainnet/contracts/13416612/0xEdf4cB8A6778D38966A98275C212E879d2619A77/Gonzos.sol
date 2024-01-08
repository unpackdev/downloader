// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Gonzos is ERC721, ERC721Enumerable, Ownable {
  bool public active = true;

  uint256 private _current = 1;

  uint256 public constant tokenPrice = 0.015 ether; // 0.015 ETH
  uint16 public constant tokensToWithhold = 100; // 20 per transaction.
  uint256 public constant limitPerTx = 10; // 20 per transaction.
  uint256 public constant totalLimit = 1000; // 10240 tokens.

  string private _baseUri = "https://cloudflare-ipfs.com/ipfs/QmYk3UeLazFx1XA22vYAfqxaYd7sMyFZ7hTG5E7V74LTZ9/";

  event Activate(address caller, bool from, bool to);

  event WithdrawBalance(address caller, uint256 amount);

  /** Checks that the current state exactly matches the required state. */
  modifier onlyActive() {
    require(active, "Cannot call method when not active");
    _;
  }

  constructor(
    string memory name,
    string memory token,
    address owner
  ) ERC721(name, token) {
  }

  function toggleActive() public onlyOwner {
    bool from = active;
    active = !active;
    emit Activate(msg.sender, from, active);
  }

  function mintTokens(uint16 count) public payable onlyActive {
    require(count <= limitPerTx, "Too many tokens requested");
    require(msg.value == count * tokenPrice, "Incorrect funds!");

    (uint256 start, uint256 end) = _next(count);
    require(end <= totalLimit, "Not enough tokens left to fulfill request");

    for (uint256 i = start; i <= end && i <= totalLimit; i++) {
      _safeMint(msg.sender, i);
    }
  }

  function reserveTokens() public onlyOwner {
    (uint256 start, uint256 end) = _next(tokensToWithhold);
    require(end <= totalLimit, "Not enough tokens left to fulfill request");

    for (uint256 i = start; i <= end && i <= totalLimit; i++) {
      _safeMint(msg.sender, i);
    }
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
    emit WithdrawBalance(msg.sender, balance);
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
    _baseUri = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return string(abi.encodePacked(_baseUri, "metadata/"));
  }

  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked(_baseUri, "details.json"));
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function destroy() public onlyOwner {
    selfdestruct(payable(msg.sender));
  }

  function _next(uint16 amount) internal returns (uint256, uint256) {
    unchecked {
      uint256 start = _current;
      _current += amount;
      return (start, _current - 1);
    }
  }
}
