// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./PaymentSplitter.sol";

contract AKCDistributor is Ownable, PaymentSplitter {

    constructor(
        address[] memory _recipients,
        uint256[] memory _shares
    ) PaymentSplitter(_recipients, _shares) {}
}
