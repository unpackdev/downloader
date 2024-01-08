// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IERC20Adapter is IERC20 {
    function emitTransfer(
        address _from,
        address _to,
        uint256 _value
    ) external;
}
