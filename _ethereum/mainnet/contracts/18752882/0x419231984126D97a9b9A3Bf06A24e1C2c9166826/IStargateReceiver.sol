// SPDX-License-Identifier: BUSL-1.1
// Ref'd from: https://stargateprotocol.gitbook.io/stargate/interfaces/evm-solidity-interfaces/istargatereceiver.sol

pragma solidity 0.8.19;

interface IStargateReceiver {
    event Received(
        uint16 _chainId, bytes _srcAddress, uint256 _nonce, address _token, uint256 amountLD, bytes _payload
    );

    error InvalidSender();

    /// @param _chainId The remote chainId sending the tokens
    /// @param _srcAddress The remote Bridge address
    /// @param _nonce The message ordering nonce
    /// @param _token The token contract on the local chain
    /// @param _amountLD The qty of local _token contract tokens
    /// @param _payload The bytes containing the _tokenOut, _deadline, _amountOutMin, _toAddr
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 _amountLD,
        bytes memory _payload
    ) external;
}
