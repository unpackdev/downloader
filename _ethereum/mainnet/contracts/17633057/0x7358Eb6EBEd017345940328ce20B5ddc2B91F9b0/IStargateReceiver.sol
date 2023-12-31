// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IStargateReceiver {
    event ReceivedOnDestination(address token, uint256 amountLD);

    /*
     * @dev Called by the Stargate Router on the destination chain upon bridging funds
     * @dev unused @param _srcChainId The remote chainId sending the tokens
     * @dev unused @param _srcAddress The remote Bridge address
     * @dev unused @param _nonce The message ordering nonce
     * @param _token The token contract on the local chain
     * @param amountLD The qty of local _token contract tokens
     * @param payload The bytes containing the execution paramaters
     */
    function sgReceive(
        uint16, // _srcChainId
        bytes memory, // _srcAddress
        uint256, // _nonce
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external;
}
