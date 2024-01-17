// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ICurveCrvCvxCrvPool {
  function add_liquidity(
    uint256[2] memory _amounts,
    uint256 _min_mint_amount
  ) external returns(uint256);

  function coins(
    uint256 index
  ) external view returns(address);

}
