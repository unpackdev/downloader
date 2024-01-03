// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface IKeep3rV1Helper {
    function getQuoteLimit(uint256 gasUsed) external view returns (uint256);
}
