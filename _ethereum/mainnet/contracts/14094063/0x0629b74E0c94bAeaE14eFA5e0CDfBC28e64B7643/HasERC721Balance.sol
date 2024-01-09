// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IConditional.sol";

contract HasERC721Balance is IConditional, Ownable {
  address public nftContract;
  uint256 public minTokenBalance = 1;

  constructor(address _nftContract) {
    nftContract = _nftContract;
  }

  function passesTest(address wallet) external view override returns (bool) {
    return IERC721(nftContract).balanceOf(wallet) >= minTokenBalance;
  }

  function setTokenAddress(address _nftContract) external onlyOwner {
    nftContract = _nftContract;
  }

  function setMinTokenBalance(uint256 _newMin) external onlyOwner {
    minTokenBalance = _newMin;
  }
}
