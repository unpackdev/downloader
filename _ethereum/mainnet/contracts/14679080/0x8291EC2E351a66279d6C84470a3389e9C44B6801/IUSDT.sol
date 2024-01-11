//SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IUSDT {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function decimals() external view returns (uint8);
}
