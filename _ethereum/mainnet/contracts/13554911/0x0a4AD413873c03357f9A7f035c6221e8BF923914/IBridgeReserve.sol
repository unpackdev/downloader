// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./BridgeBeams.sol";

interface IBridgeReserve {
  function projectToParameters(uint256 _id)
    external
    view
    returns (BridgeBeams.ReserveParameters memory);

  function projectToMinters(uint256 _id, address _minter)
    external
    view
    returns (bool);
}
