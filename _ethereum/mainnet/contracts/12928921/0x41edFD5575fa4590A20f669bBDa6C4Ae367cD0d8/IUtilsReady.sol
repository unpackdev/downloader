// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./IGovernable.sol";
import "./ICollectableDust.sol";
import "./IPausable.sol";

interface IUtilsReady is IGovernable, ICollectableDust, IPausable {
}
