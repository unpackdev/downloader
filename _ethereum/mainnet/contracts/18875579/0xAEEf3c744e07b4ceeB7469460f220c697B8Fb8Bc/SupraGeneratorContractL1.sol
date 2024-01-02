// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./SupraGeneratorContract.sol";

/// @title VRF Generator Contract for L1 chains
/// @author Supra Developer
/// @notice This contract will generate random number based on the router contract request
/// @dev All function calls are currently implemented without side effects

contract SupraGeneratorContractL1 is
    SupraGeneratorContract
{
    constructor(
        bytes32 _domain,
        address _supraRouterContract,
        uint256[4] memory _publicKey,
        uint256 _instanceId,
        uint256 _blsPreCompileGasCost,
        uint256 _gasAfterPaymentCalculation
    ) public SupraGeneratorContract(_domain, _supraRouterContract, _publicKey, _instanceId, _blsPreCompileGasCost,_gasAfterPaymentCalculation) {}

    /// @dev Calculate the transaction fee for the callback transaction for Arbitrum
    /// @param _startGas The gas at the start of the transaction
    /// @param _gasAfterPaymentCalculation calculated gas value to be used based on iterative tests
    /// @return paymentWithoutFee The total estimated transaction fee for callback
    function calculatePaymentAmount(
        uint256 _startGas,
        uint256 _gasAfterPaymentCalculation
    ) internal override view returns (uint256) {
        // TransactionFee =  ChainGasCost  * ( gasAfterPaymentCalculation + gasUsedL1)
        uint256 paymentWithoutFee = tx.gasprice *
            (_gasAfterPaymentCalculation + _startGas - gasleft());
        return paymentWithoutFee;
    }

}
