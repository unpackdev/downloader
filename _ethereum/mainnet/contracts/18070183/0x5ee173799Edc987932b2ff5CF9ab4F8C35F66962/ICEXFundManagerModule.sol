// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IDABotFundManagerModule.sol";

interface ICEXFundManagerModule is IDABotFundManagerModule {
    function distributeReward(AwardingDetail[] calldata data) external;
}