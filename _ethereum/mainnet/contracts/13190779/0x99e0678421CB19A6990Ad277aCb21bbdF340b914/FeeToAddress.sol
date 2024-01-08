// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./Ownable.sol";

abstract contract FeeToAddress is Ownable {
    uint256 public feeToAddress;
    address public feeBeneficiary;

    event FeeBeneficiaryChanged(address newBeneficiary);

    function setToAddressFee(uint256 newFeeToAddressPercent) external onlyOwner {
        feeToAddress = newFeeToAddressPercent;
    }

    function setFeeBeneficiary(address newBeneficiary) external onlyOwner {
        feeBeneficiary = newBeneficiary;
        emit FeeBeneficiaryChanged(newBeneficiary);
    }

}