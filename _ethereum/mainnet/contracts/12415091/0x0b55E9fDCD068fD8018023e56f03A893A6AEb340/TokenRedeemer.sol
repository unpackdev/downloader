// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./FixedPoint.sol";
import "./TransferHelper.sol";

// Simple contract used to redeem tokens using a DSProxy from an emp.
contract TokenRedeemer {
    function redeem(address financialContractAddress, FixedPoint.Unsigned memory numTokens)
        public
        returns (FixedPoint.Unsigned memory)
    {
        IFinancialContract fc = IFinancialContract(financialContractAddress);
        TransferHelper.safeApprove(fc.tokenCurrency(), financialContractAddress, numTokens.rawValue);
        return fc.redeem(numTokens);
    }
}

interface IFinancialContract {
    function redeem(FixedPoint.Unsigned memory numTokens) external returns (FixedPoint.Unsigned memory amountWithdrawn);

    function tokenCurrency() external returns (address);
}
