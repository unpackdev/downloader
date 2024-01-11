// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface Token {

}

interface IBancorV3Network {
    function tradeBySourceAmount(
        Token sourceToken,
        Token targetToken,
        uint256 sourceAmount,
        uint256 minReturnAmount,
        uint256 deadline,
        address beneficiary
    ) external payable returns (uint256);
}
