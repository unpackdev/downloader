// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseNFT.sol";
import "./INftTokenUri.sol";

contract Vacabee is BaseNFT {
    constructor(
        uint256 collectionLimit_,
        string memory baseUri_,
        uint256[] memory _tierPrices,
        uint256[] memory _membershipActivationPrices,
        uint256[] memory _tierLimits
    )
        BaseNFT(
            "Vacabee Travel Club",
            "VACABEE",
            collectionLimit_,
            baseUri_,
            _tierPrices,
            _membershipActivationPrices,
            _tierLimits
        )
    {}
}
