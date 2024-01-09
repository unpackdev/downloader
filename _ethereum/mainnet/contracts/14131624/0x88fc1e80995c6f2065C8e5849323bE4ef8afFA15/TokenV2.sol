// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import "./Token.sol";

contract TokenDisabled is Token {

    function name() public override pure returns (string memory) {
        return "Test";
    }

    function symbol() public override pure returns (string memory) {
        return "Test";
    }

    function transfer(address, uint256) public override pure returns (bool) {
        revert("disabled");
    }

    function approve(address, uint256) public override pure returns (bool) {
        revert("disabled");
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public override pure returns (bool) {
        revert("disabled");
    }

    function increaseAllowance(address, uint256) public override pure returns (bool) {
        revert("disabled");
    }

    function decreaseAllowance(address, uint256) public override pure returns (bool) {
        revert("disabled");
    }

    uint256[50] private __gap;
}
