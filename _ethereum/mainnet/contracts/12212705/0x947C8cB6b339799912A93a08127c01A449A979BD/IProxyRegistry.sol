// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./Ownable.sol";

interface IProxyRegistry {
  function proxies(address) external view returns(address);
}
