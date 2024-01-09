// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract ToggleableSale is Ownable {
  bool public isSaleActive;
  bool public isPresaleActive;
  uint256 public saleStartBlock;
  uint256 public presaleStartBlock;

  modifier whenSaleActive() {
    require(
      isSaleActive || (saleStartBlock > 0 && block.number >= saleStartBlock),
      'Sale is not active'
    );
    _;
  }

  modifier whenPresaleActive() {
    require(
      isPresaleActive || (presaleStartBlock > 0 && block.number >= presaleStartBlock),
      'Presale is not active'
    );
    _;
  }

  function setSaleState(bool _isActive, uint256 startBlock) external onlyOwner {
    isSaleActive = _isActive;
    saleStartBlock = startBlock;
  }

  function setPresaleState(bool _isActive, uint256 startBlock) external onlyOwner {
    isPresaleActive = _isActive;
    presaleStartBlock = startBlock;
  }
}
