// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./IVaultRestricted.sol";
import "./IVaultIndexActions.sol";
import "./IRewardDrip.sol";
import "./IVaultBase.sol";
import "./IVaultImmutable.sol";

interface IVault is IVaultRestricted, IVaultIndexActions, IRewardDrip, IVaultBase, IVaultImmutable {}
