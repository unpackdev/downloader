// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "./RoleConstant.sol";

contract $RoleConstant {
    bytes32 public constant __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() payable {
    }

    function $MINTER_ROLE() external pure returns (bytes32) {
        return RoleConstant.MINTER_ROLE;
    }

    function $BURNER_ROLE() external pure returns (bytes32) {
        return RoleConstant.BURNER_ROLE;
    }

    function $PAUSER_ROLE() external pure returns (bytes32) {
        return RoleConstant.PAUSER_ROLE;
    }

    function $UPGRADE_ADMIN_ROLE() external pure returns (bytes32) {
        return RoleConstant.UPGRADE_ADMIN_ROLE;
    }

    function $BLACKLISTER_ROLE() external pure returns (bytes32) {
        return RoleConstant.BLACKLISTER_ROLE;
    }

    function $MERCHANTS_ROLE() external pure returns (bytes32) {
        return RoleConstant.MERCHANTS_ROLE;
    }

    receive() external payable {}
}
