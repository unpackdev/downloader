// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC1155.sol";
import "./IERC20.sol";

interface IHighstreetBrands is IERC1155 {
  function setMaxSupply(uint256 id_, uint256 amount_) external;
  function grantMinterRole(address addr_) external;
  function mint(
    address to_,
    uint256 id_,
    uint256 amount_,
    bytes memory data_
  ) external;

  function burn(
    address account,
    uint256 id,
    uint256 amount
  ) external;
  function totalSupply(uint256 id) external view returns (uint256);
}

interface HIGH is IERC20 {
  function faucet(uint256 amount_) external;
}