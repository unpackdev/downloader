// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./IMapleLoanEvents.sol";

/// @title MapleLoanInitializer is intended to initialize the storage of a MapleLoan proxy.
interface IMapleLoanInitializer is IMapleLoanEvents {

    function encodeArguments(
        address borrower_,
        address[2] memory assets_,
        uint256[3] memory termDetails_,
        uint256[3] memory amounts_,
        uint256[4] memory rates_
    ) external pure returns (bytes memory encodedArguments_);

    function decodeArguments(bytes calldata encodedArguments_)
        external pure returns (
            address borrower_,
            address[2] memory assets_,
            uint256[3] memory termDetails_,
            uint256[3] memory amounts_,
            uint256[4] memory rates_
        );

}
