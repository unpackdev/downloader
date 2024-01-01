// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ITokensManagementFacet.sol";

interface ITokensManagementFacet {
    struct Storage {
        address vault;
    }

    function vault() external pure returns (address);

    function approve(address token, address to, uint256 amount) external;
}
