// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IOneWarCouncil {
    function burn(uint256 _value) external;

    function redeemableCouncilTokens(uint256[] calldata _settlements) external view returns (uint256);

    function redeemCouncilTokens(uint256[] calldata _settlements) external;
}
