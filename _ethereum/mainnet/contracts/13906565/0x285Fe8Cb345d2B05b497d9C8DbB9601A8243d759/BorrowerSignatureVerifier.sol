// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {EIP712} from "draft-EIP712.sol";
import {SignatureValidator} from "SignatureValidator.sol";
import {IBorrowerSignatureVerifier} from "IBorrowerSignatureVerifier.sol";

contract BorrowerSignatureVerifier is EIP712, IBorrowerSignatureVerifier {
    string constant DOMAIN_NAME = "TrueFi";
    string constant DOMAIN_VERSION = "1.0";
    bytes32 constant NEW_LOAN_PARAMETERS_TYPEHASH =
        keccak256("NewLoanParameters(uint256 instrumentId,uint256 newTotalDebt,uint256 newRepaymentDate)");

    constructor() EIP712(DOMAIN_NAME, DOMAIN_VERSION) {}

    function verify(
        address borrower,
        uint256 instrumentId,
        uint256 newTotalDebt,
        uint256 newRepaymentDate,
        bytes memory signature
    ) external view returns (bool) {
        bytes32 hashed = hashTypedData(instrumentId, newTotalDebt, newRepaymentDate);
        return SignatureValidator.isValidSignature(borrower, hashed, signature);
    }

    function hashTypedData(
        uint256 instrumentId,
        uint256 newTotalDebt,
        uint256 newRepaymentDate
    ) public view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(NEW_LOAN_PARAMETERS_TYPEHASH, instrumentId, newTotalDebt, newRepaymentDate)));
    }
}
