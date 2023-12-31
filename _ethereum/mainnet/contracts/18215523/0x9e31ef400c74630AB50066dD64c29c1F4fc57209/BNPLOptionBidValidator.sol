// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./WasabiBNPL.sol";
import "./ZhartaLending.sol";
import "./IWasabiBNPL.sol";
import "./INFTLending.sol";
import "./WasabiStructs.sol";

/**
 * @dev Verifies BNPL options against WasabiConduit objects
 */
library BNPLOptionBidValidator {

    address constant ZHARTA_LENDING = 0x6209A1b9751F67594427a45b5225bC3492009788;

    /// @notice Validates the given bid for the option
    /// @param _bnplAddress the BNPL contract address
    /// @param _optionId the id of the option the validate
    function validateBidForBNPLOption(
        address _bnplAddress,
        uint256 _optionId,
        WasabiStructs.Bid calldata _bid
    ) external view {
        WasabiBNPL bnpl = WasabiBNPL(payable(_bnplAddress));
        (address lending, uint256 loanId) = bnpl.optionToLoan(_optionId);

        INFTLending.LoanDetails memory loanDetails;
        if (lending == ZHARTA_LENDING) {
            loanDetails = ZhartaLending(payable(lending)).getLoanDetailsForBorrower(loanId, _bnplAddress);
        } else {
            loanDetails = INFTLending(lending).getLoanDetails(loanId);
        }

        WasabiStructs.OptionData memory optionData = bnpl.getOptionData(_optionId);

        require(
            optionData.optionType == _bid.optionType,
            "Option types don't match"
        );
        require(
            optionData.strikePrice == _bid.strikePrice,
            "Strike prices don't match"
        );

        uint256 diff = optionData.expiry > _bid.expiry
            ? optionData.expiry - _bid.expiry
            : _bid.expiry - optionData.expiry;
        require(diff <= _bid.expiryAllowance, "Not within expiry range");

        require(loanDetails.nftAddress == _bid.collection, "Collections don't match");
    }
}