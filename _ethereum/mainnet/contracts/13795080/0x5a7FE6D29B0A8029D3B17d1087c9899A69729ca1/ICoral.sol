// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./ISharks.sol";

interface ICoral {
  function addManyToCoral(address account, uint16[] calldata tokenIds) external;
  function randomTokenOwner(ISharks.SGTokenType tokenType, uint256 seed) external view returns (address);
}
