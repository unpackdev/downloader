// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

interface IERC777OperatorBatchFunctions {
    function operatorBatchTransfer(
        address sender,
        address[] calldata recipients,
        uint256[] calldata amounts,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    function operatorBatchMint(
        address[] calldata recipients,
        uint256[] calldata amounts,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    function operatorBatchBurn(
        address[] calldata holders,
        uint256[] calldata amounts,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
}
