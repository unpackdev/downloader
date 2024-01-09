// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

interface IRoyalty {
    function initialize(
        address _tokenContract,
        address[] memory payees,
        uint256[] memory shares_
    ) external;
    function grantRole(bytes32 role, address account) external;
    function ADMIN_ROLE() external returns(bytes32);
}
