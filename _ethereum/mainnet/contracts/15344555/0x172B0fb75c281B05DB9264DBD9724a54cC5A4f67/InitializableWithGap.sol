// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.11;

import "./Initializable.sol";


contract InitializableWithGap is Initializable {
    uint256[50] private ______gap;
}
