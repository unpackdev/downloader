// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

interface IimUSD {

    function creditsToUnderlying(uint256 _credits)
      external
      view
      returns(uint256);
}
