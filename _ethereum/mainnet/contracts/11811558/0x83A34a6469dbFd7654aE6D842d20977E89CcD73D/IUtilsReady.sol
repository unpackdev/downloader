// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;
import "./IGovernable.sol";
import "./ICollectableDust.sol";
import "./IPausable.sol";
import "./IMigratable.sol";

interface IUtilsReady is IGovernable, ICollectableDust, IPausable, IMigratable{
}
