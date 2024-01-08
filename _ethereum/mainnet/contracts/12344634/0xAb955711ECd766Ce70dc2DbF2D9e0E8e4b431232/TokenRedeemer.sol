pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

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
