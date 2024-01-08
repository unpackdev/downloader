// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract BubbleGumEvents {
  event Blow(
    uint indexed id,
    uint indexed size,
    address indexed chewer
  );

  event Frens(
    uint indexed id,
    uint indexed amt,
    address indexed chewer
  );

  event Destroy(
    uint indexed id,
    address indexed chewer
  );

  event Join(
    uint indexed a,
    uint indexed b,
    uint indexed id
  );

  event Stake(
    uint indexed id,
    address indexed chewer
  );

  event Unstake(
    uint indexed id,
    address indexed chewer
  );

  event Snap(
    uint indexed amount,
    address indexed chewer
  );
}