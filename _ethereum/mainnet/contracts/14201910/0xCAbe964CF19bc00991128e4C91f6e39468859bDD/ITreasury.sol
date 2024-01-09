// SPDX-License-Identifier: MIT
pragma solidity >=0.4 <0.9;
import "./IGalaxyToken.sol";

interface ITreasury {
  function destroyAndSend(address payable _recipient) external;
  function galaxytoken() external returns (IGalaxyToken);
}
