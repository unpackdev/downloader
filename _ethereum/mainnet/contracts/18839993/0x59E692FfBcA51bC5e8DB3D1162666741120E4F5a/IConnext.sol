// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IConnext {
    function xcall(
        uint32 destination,
        address recipient,
        address tokenAddress,
        address delegate,
        uint256 amount,
        uint256 slippage,
        bytes memory callData
    ) external payable returns (bytes32);

    function xcall(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData,
    uint256 _relayerFee
  ) external returns (bytes32);

}