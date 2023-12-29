// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "./IAggregatorV3.sol";
import "./IConnext.sol";

interface IPriceBulletin is IAggregatorV3, IXReceiver {
  function setAuthorizedPublisher(address publisher, bool set) external;
}
