// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

error MaxSupplyReached();
error MaxPerWalletReached();
error NotEnoughETH();
error WithdrawalError();

import "./ERC721A.sol";
import "./Owned.sol";

contract the50club is Owned(msg.sender), ERC721A {

  address public treasury = 0x4FA97DABBe009821A0926F386824E89752C0FaFd;

  uint256 public constant maxSupply = 21;
  uint256 public constant maxPerWallet = 3;
  uint256 public constant price = 50 ether;
  string private baseURI;

  constructor() ERC721A("the50club", "t50c") {}

  function mint(uint256 quantity) external payable {
    if (_totalMinted() + quantity > maxSupply) revert MaxSupplyReached();
    if (_numberMinted(msg.sender) + quantity > maxPerWallet) revert MaxPerWalletReached();
    if (msg.value != price * quantity) revert NotEnoughETH();

    _mint(msg.sender, quantity);
  }

  // METADATA

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function setBaseURI(string calldata _newURI) external onlyOwner {
    baseURI = _newURI;
  }

  // WITHDRAW

  function withdraw() external onlyOwner {
    (bool success, ) = treasury.call{value: address(this).balance}("");
    if (!success) revert WithdrawalError();
  }
}