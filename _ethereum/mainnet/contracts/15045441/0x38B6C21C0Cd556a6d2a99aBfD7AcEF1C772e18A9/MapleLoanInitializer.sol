// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./IMapleLoanInitializer.sol";

import "./MapleLoanInternals.sol";

/// @title MapleLoanInitializer is intended to initialize the storage of a MapleLoan proxy.
contract MapleLoanInitializer is IMapleLoanInitializer, MapleLoanInternals {

    function encodeArguments(
        address borrower_,
        address[2] memory assets_,
        uint256[3] memory termDetails_,
        uint256[3] memory amounts_,
        uint256[4] memory rates_
    ) external pure override returns (bytes memory encodedArguments_) {
        return abi.encode(borrower_, assets_, termDetails_, amounts_, rates_);
    }

    function decodeArguments(bytes calldata encodedArguments_)
        public pure override returns (
            address borrower_,
            address[2] memory assets_,
            uint256[3] memory termDetails_,
            uint256[3] memory amounts_,
            uint256[4] memory rates_
        )
    {
        (
            borrower_,
            assets_,
            termDetails_,
            amounts_,
            rates_
        ) = abi.decode(encodedArguments_, (address, address[2], uint256[3], uint256[3], uint256[4]));
    }

    fallback() external {
        (
            address borrower_,
            address[2] memory assets_,
            uint256[3] memory termDetails_,
            uint256[3] memory amounts_,
            uint256[4] memory rates_
        ) = decodeArguments(msg.data);

        emit Initialized(borrower_, assets_, termDetails_, amounts_, rates_);

        _initialize(borrower_, assets_, termDetails_, amounts_, rates_);
    }

}
