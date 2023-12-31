// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @title Interface for interactor which acts after `fullfill Order` transfers.
 * @notice DLN Destincation contract call receiver contract with information about order
*/
interface IExternalCallAdapter {
    /**
     * @notice Callback method that gets called after maker funds transfers
     * @param _orderId Hash of the order being processed
     * @param _callAuthority Address that can cancel external call and send tokens to fallback address
     * @param _tokenAddress  token that was transferred to adapter
     * @param _transferredAmount Actual amount that was transferred to adapter
     * @param _externalCall call data
     * @param _externalCallRewardBeneficiary Reward beneficiary address that will receiv execution fee. If address is 0 will not execute external call.
     */
    function receiveCall(
        bytes32 _orderId,
        address _callAuthority,
        address _tokenAddress,
        uint256 _transferredAmount,
        bytes calldata _externalCall,
        address _externalCallRewardBeneficiary
    ) external;
}