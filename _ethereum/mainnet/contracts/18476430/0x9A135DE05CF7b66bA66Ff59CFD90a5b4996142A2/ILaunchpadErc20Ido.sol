// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ILaunchpadErc20IdoActions.sol";
import "./ILaunchpadErc20IdoErrors.sol";
import "./ILaunchpadErc20IdoEvents.sol";
import "./ILaunchpadErc20IdoState.sol";
import "./IIdoStorage.sol";


interface ILaunchpadErc20Ido is ILaunchpadErc20IdoActions, ILaunchpadErc20IdoErrors, ILaunchpadErc20IdoEvents, ILaunchpadErc20IdoState {
}