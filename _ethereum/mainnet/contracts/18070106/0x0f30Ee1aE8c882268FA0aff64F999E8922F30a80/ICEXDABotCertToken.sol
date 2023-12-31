// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IDABotCertToken.sol";

interface ICEXDABotCertToken is IDABotCertToken {
    function cexLock(uint assetAmount) external;
    function cexUnlock(uint assetAmount) external payable;
}