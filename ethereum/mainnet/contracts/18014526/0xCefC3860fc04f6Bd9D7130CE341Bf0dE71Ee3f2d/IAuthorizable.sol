// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOwnableV2.sol";

interface IAuthorizable {
  event Authorized(address indexed account, bool value);

  function isAuthorized(address account) external view returns (bool);
  function authorize(address account, bool value) external;
}
