// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Address.sol";
import "./FarmEndpointV2.sol";
import "./Console.sol";

contract CurveFarm is FarmEndpointV2 {
  using Address for address;

  address constant PUUL_TOKEN = 0x897581168bB658954a811a03de8394EBd42852Ef;

  constructor (address pool, address[] memory rewards) public FarmEndpointV2(pool, rewards) {
  }


}