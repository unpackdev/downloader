// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./OwnableUpgradeable.sol";

contract OperatorRole is OwnableUpgradeable {
    mapping (address => bool) operators;

    function __OperatorRole_init_unchained() internal {
        operators[_msgSender()] = true;
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function addOperator(address operator) external onlyOwner {
        operators[operator] = true;
    }

    function removeOperator(address operator) external onlyOwner {
        operators[operator] = false;
    }

    modifier onlyOperator() {
        require(operators[_msgSender()], "OperatorRole: caller is not the operator");
        _;
    }

    uint256[50] private __gap;
}