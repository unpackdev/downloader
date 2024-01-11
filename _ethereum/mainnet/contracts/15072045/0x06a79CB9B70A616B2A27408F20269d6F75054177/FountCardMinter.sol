// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./ERC1155Receiver.sol";

contract FountCardMinter is Ownable {
  IERC1155 public collection;
  uint256 constant FOUNT_CARD_ID = 1;

  uint256 public price = 0.09 ether;

  bool public saleActive = false;

  constructor(address collectionAddr) {
    collection = IERC1155(collectionAddr);
  }

  function setSaleActive(bool active) public onlyOwner {
    saleActive = active;
  }

  function purchaseCard() public payable {
    require(saleActive, "Sale is closed");
    require(msg.value == price, "Incorrect payable amount");

    collection.safeTransferFrom(address(this), _msgSender(), FOUNT_CARD_ID, 1, "");
  }

  function ownerTransferTo(address to, uint256 amount) public onlyOwner {
    collection.safeTransferFrom(address(this), to, FOUNT_CARD_ID, amount, "");
  }

  function withdraw(address payable receiver) public onlyOwner {
    receiver.transfer(address(this).balance);
  }

  // IERC1155Receiver

  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) external pure returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }
}
