// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./TokenTimelock.sol";

contract TimeLock is TokenTimelock {
    constructor()
        TokenTimelock(
            IERC20(0xFAd4fbc137B9C270AE2964D03b6d244D105e05A6),
            0x9D7CC83565840C97Be1f81bAACAbA2AeC0cb416C,
            1693353599
        )
    {}
}
