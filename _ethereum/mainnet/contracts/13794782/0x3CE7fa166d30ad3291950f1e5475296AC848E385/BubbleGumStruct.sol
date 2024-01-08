// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract BubbleGumStruct {
  enum Var {
    TOTAL_GENESIS,
    TARGET_SUPPLY,
    FEE_GENESIS,
    FEE_BLOW,
    FEE_JOIN,
    PROBA_BURST,
    PROBA_SHARE,
    PROBA_DROP,
    PROBA_FREN,
    STAKE_SPLIT,
    CHEW_RATE
  }

  struct Meta {
    bool isGenesis;
    uint size;
    uint8 flavor;
    uint intensity;
    uint lastSnap;
  }
}