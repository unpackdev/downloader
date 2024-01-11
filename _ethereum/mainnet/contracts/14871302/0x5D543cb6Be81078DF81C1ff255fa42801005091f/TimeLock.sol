// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./TokenTimelock.sol";

contract TimeLock is TokenTimelock {
    constructor()
        TokenTimelock(
            IERC20(0xFAd4fbc137B9C270AE2964D03b6d244D105e05A6),
            0x8e38EC9dD65C911afd756C41A7e0c3E647805618,
            1693353599
        )
    {}
}
