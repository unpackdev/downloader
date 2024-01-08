// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Ownable.sol";

import "./IFacelessNFT.sol";

contract Migration is Ownable {
  IFacelessNFT public facelessNFT;

  constructor(address nftAddress) {
    facelessNFT = IFacelessNFT(nftAddress);
  }

  function burnable() external view returns (bool) {
    bool isBurnable = false;
    for (uint16 i = 847; i <= 1001; i++) {
      if (msg.sender == facelessNFT.ownerOf(i)) {
        isBurnable = true;
        break;
      }
    }
    return isBurnable;
  }

  function burn() external {
    for (uint16 i = 847; i <= 1001; i++) {
      if (msg.sender == facelessNFT.ownerOf(i)) {
        facelessNFT.transferFrom(msg.sender, address(0), i);
      }
    }
  }
}
