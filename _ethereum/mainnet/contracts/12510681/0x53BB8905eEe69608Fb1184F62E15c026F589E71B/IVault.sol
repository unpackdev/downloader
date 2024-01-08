// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./DataTypes.sol";

interface IVault {
    function execute(
        address[] calldata targets,
        bytes[] calldata datas,
        DataTypes.CallType[] calldata callTypes
    ) external;
}
