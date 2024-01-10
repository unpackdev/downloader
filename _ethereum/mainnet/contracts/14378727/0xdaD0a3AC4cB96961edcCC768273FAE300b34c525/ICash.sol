// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;
import "./IERC20.sol";
import "./Ownable.sol";

interface ICASH is IERC20{
  function mint(address to, uint256 amount) external;
  function burn(address from, uint256 amount) external;
}
