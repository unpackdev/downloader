// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import "./HabitatV1Challenge.sol";
import "./HabitatBase.sol";
import "./HabitatAccount.sol";
import "./HabitatWallet.sol";
import "./HabitatCommunity.sol";
import "./HabitatVault.sol";
import "./HabitatVoting.sol";
import "./HabitatModule.sol";
import "./HabitatStakingPool.sol";

/// @notice Composition of the full Habitat Rollup contracts (v1)
// Audit-1: ok
contract HabitatV1 is
  HabitatBase,
  HabitatAccount,
  HabitatWallet,
  HabitatCommunity,
  HabitatVault,
  HabitatVoting,
  HabitatModule,
  HabitatStakingPool,
  HabitatV1Challenge
{
  /// @inheritdoc NutBerryCore
  function MAX_BLOCK_SIZE () public view override returns (uint24) {
    return 31744;
  }

  /// @inheritdoc NutBerryCore
  function INSPECTION_PERIOD () public view virtual override returns (uint16) {
    // in blocks, (3600 * 24 * 7) seconds / 14s per block
    return 43200;
  }

  /// @inheritdoc NutBerryCore
  function INSPECTION_PERIOD_MULTIPLIER () public view override returns (uint256) {
    return 3;
  }

  /// @inheritdoc NutBerryCore
  function _CHALLENGE_IMPLEMENTATION_ADDRESS () internal override returns (address addr) {
    assembly {
      // loads the target contract adddress from the proxy slot
      addr := sload(not(0))
    }
  }

  /// @inheritdoc UpgradableRollup
  function ROLLUP_MANAGER () public virtual override pure returns (address) {
    // Habitat multisig - will be replaced by the community governance proxy in the future
    return 0xc97f82c80DF57c34E84491C0EDa050BA924D7429;
  }

  /// @inheritdoc HabitatBase
  function STAKING_POOL_FEE_DIVISOR () public virtual override pure returns (uint256) {
    // 1%
    return 100;
  }

  /// @inheritdoc HabitatBase
  function EPOCH_GENESIS () public virtual override pure returns (uint256) {
    // Date.parse('2021-06-23') / 1000
    return 1624406400;
  }

  /// @inheritdoc HabitatBase
  function SECONDS_PER_EPOCH () public virtual override pure returns (uint256) {
    // 7 days
    return 604800;
  }
}
