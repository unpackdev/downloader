// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

error MaxSupplyReached();
error MaxPerWalletReached();
error NotEnoughETH();
error WithdrawalError();

import "./ERC721A.sol";
import "./Owned.sol";

contract the50clubtest is Owned(msg.sender), ERC721A {

  address public treasury = 0xe9Fb6EBfa53BeC6812ecEF2E8D2970aFf37C0C7D;

  uint256 public constant maxSupply = 21;
  uint256 public constant maxPerWallet = 3;
  uint256 public constant price = 0.1 ether;
  string private baseURI;

  constructor() ERC721A("the50club", "t50c") {}

  function mint(uint256 quantity) external payable {
    if (_totalMinted() + quantity >= maxSupply) revert MaxSupplyReached();
    if (_numberMinted(msg.sender) + quantity >= maxPerWallet) revert MaxPerWalletReached();
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