//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import "./IOKPC.sol";

interface IOKPCGenesisArtwork {
  function getGenesisArtwork(uint256)
    external
    view
    returns (uint256, IOKPC.Art memory);
}
