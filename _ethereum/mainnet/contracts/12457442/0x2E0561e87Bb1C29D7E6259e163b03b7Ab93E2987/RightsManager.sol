// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

library RightsManager {
  struct Rights {
  bool canPauseSwapping;
  bool canChangeSwapFee;
  bool canChangeWeights;
  bool canAddRemoveTokens;
  bool canWhitelistLPs;
  bool canChangeCap;
  }
}