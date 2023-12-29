// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC721.sol";

interface IMoonboyzNFT is IERC721 {
  function totalSupply() external view returns (uint256);
}
