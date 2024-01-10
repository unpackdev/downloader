// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import "./interfaces.sol";
import "./math.sol";
import "./basic.sol";
import "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    IStakeManagerProxy public constant stakeManagerProxy =
        IStakeManagerProxy(0x5e3Ef299fDDf15eAa0432E6e66473ace8c13D908);

    TokenInterface public constant maticToken =
        TokenInterface(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0);
}
