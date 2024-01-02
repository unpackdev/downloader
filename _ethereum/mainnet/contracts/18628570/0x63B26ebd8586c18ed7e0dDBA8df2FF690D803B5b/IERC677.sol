// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "./IERC20.sol";

interface IERC677 is IERC20 {
    function transferAndCall(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool success);
}
