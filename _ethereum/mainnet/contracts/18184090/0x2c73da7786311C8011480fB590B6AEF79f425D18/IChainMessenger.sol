// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IController.sol";

interface IChainMessenger {
    function relayMessage(address committer, IController.Group memory group) external;
}
