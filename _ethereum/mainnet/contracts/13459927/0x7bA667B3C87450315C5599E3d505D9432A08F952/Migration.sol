// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Ownable.sol";

import "./IFacelessNFT.sol";

contract Migration is Ownable {
  IFacelessNFT public facelessNFT;
  IFacelessNFT public oldFacelessNFT;

  constructor(address oldNftAddress, address nftAddress) {
    oldFacelessNFT = IFacelessNFT(oldNftAddress);
    facelessNFT = IFacelessNFT(nftAddress);
  }

  function migrate(address minter) external onlyOwner {
    for (uint16 i = 847; i <= 1001; i++) {
      if (minter == oldFacelessNFT.ownerOf(i)) {
        // oldFacelessNFT.transferFrom(minter, address(0), i);
        facelessNFT.mint(minter, i);
      }
    }
  }
}
