// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ProtocolERC20Interface {
    function push(address token, uint256 amt)
        external
        payable
        returns (uint256 _amt);

    function pull(
        address token,
        uint256 amt,
        address to
    ) external payable returns (uint256 _amt);
}
