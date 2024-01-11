// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./IERC20.sol";

interface ISwitchEvent {
    function emitSwapped(
        address from,
        address recipient,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 fromAmount,
        uint256 destAmount,
        uint256 reward
    )
    external;
}
