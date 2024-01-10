// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC1155Holder.sol";
import "./IERC1155.sol";

contract CharityMint is ERC1155Holder, ReentrancyGuard, Ownable {
  address public contractAddress =
    address(0x6faD73936527D2a82AEA5384D252462941B44042);
  uint256 public tokenId = 55;
  uint256 public salePrice = 0.05 ether;
  uint256 public maxMint = 50;

  enum State {
    Closed,
    PublicSale
  }

  State private _state;

  constructor() {}

  function setMaxMint(uint256 _max) public onlyOwner {
    maxMint = _max;
  }

  function setContractAddress(address _contractAddress) public onlyOwner {
    contractAddress = _contractAddress;
  }

  function setTokenId(uint256 _tokenId) public onlyOwner {
    tokenId = _tokenId;
  }

  function setSalePrice(uint256 _amount) public onlyOwner {
    salePrice = _amount;
  }

  function setSaleToClosed() public onlyOwner {
    _state = State.Closed;
  }

  function setSaleToPublic() public onlyOwner {
    _state = State.PublicSale;
  }

  function publicMint(uint256 amount) external payable nonReentrant {
    require(amount <= maxMint, "not allowed to mint this much at once");
    require(_state == State.PublicSale, "Publicsale is not active");
    require(msg.value >= amount * salePrice, "Ether value sent is incorrect.");

    IERC1155(contractAddress).safeTransferFrom(
      address(this),
      msg.sender,
      tokenId,
      amount,
      "0x0"
    );
  }

  function withdrawAll(address recipient) public onlyOwner {
    uint256 balance = address(this).balance;
    payable(recipient).transfer(balance);
  }

  function withdrawAllViaCall(address payable _to) public onlyOwner {
    uint256 balance = address(this).balance;
    (bool sent, bytes memory data) = _to.call{value: balance}("");
    require(sent, "Failed to send Ether");
  }

  function emergencyWithdrawTokens(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    address _contractAddress
  ) public onlyOwner {
    IERC1155(_contractAddress).safeBatchTransferFrom(
      address(this),
      _to,
      _ids,
      _amounts,
      "0x0"
    );
  }
}
