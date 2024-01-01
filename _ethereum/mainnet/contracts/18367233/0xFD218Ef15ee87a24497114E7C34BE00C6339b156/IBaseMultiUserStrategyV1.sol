// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./ICoreUUPS_ABIVersionAware.sol";
import "./IERC20Upgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";

interface IBaseMultiUserStrategyV1 is IERC20Upgradeable, IERC20MetadataUpgradeable, ICoreUUPS_ABIVersionAware {}
