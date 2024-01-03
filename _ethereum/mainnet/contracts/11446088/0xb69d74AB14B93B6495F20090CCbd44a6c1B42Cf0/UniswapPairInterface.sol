// SPDX-License-Identifier: UNLICENSED

/// SWC-103:  Floating Pragma
pragma solidity 0.6.12;

interface UniswapPairInterface {
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
