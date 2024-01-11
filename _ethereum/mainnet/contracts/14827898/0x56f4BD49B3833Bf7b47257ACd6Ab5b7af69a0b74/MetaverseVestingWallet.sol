//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.13;

import "./VestingWallet.sol";

contract MetaverseVestingWallet is VestingWallet {
  // starts
  // 2022-05-23 00:00:00 JST - 1653231600
  //
  // end:
  // 2024-05-31 00:00:00 JST - 1717081200

  constructor()
    VestingWallet(
      address(0xCbcCB2272fea8c684ea977EEc4D9A7b14e1D8202),
      1653231600,
      (1717081200 - 1653231600)
    )
  {}
}
