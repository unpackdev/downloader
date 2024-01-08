// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

/******************************************************************************\
* Author: Evert Kors <dev@sherlock.xyz> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import "./IERC20.sol";
import "./IERC173.sol";
import "./IDiamondLoupe.sol";
import "./IDiamondCut.sol";
import "./ISherX.sol";
import "./ISherXERC20.sol";
import "./IGov.sol";
import "./IGovDev.sol";
import "./IPayout.sol";
import "./IManager.sol";
import "./IPoolBase.sol";
import "./IPoolStake.sol";
import "./IPoolStrategy.sol";

interface ISherlock is
  IERC173,
  IDiamondLoupe,
  IDiamondCut,
  ISherX,
  ISherXERC20,
  IERC20,
  IGov,
  IGovDev,
  IPayout,
  IManager,
  IPoolBase,
  IPoolStake,
  IPoolStrategy
{}
