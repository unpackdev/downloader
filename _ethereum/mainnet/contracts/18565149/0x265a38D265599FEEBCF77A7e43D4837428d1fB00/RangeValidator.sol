// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "./IBaseOfferValidator.sol";

contract RangeValidator is IBaseOfferValidator {
    error TokenIdOutOfRangeError(uint256 min, uint256 max);

    function validateOffer(IBaseLoan.LoanOffer calldata, uint256 _tokenId, bytes calldata _validatorData)
        external
        pure
    {
        (uint256 minValue, uint256 maxValue) = abi.decode(_validatorData, (uint256, uint256));
        if (_tokenId < minValue || _tokenId > maxValue) {
            revert TokenIdOutOfRangeError(minValue, maxValue);
        }
    }
}
