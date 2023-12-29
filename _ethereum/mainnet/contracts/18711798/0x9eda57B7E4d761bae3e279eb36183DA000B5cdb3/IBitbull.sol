// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.19;

interface IBitbull {

    function buy(
        string memory _ref,
        string memory _slug,
        address _paymentToken,
        uint256 _paymentAmount
    ) external payable returns (uint256);

}