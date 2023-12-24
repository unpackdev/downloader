// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ILocker {
    function safeExecute(
        address payable _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool success, bytes memory result);

    function governance() external view returns (address);
    function proxy() external view returns (address);
}
