//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "./OwnerUpgradeable.sol";

abstract contract OwnerOperator is OwnableUpgradeable {
    mapping(address => bool) public operators;

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    modifier operatorOrOwner() {
        require(
            operators[msg.sender] || owner() == msg.sender,
            "OwnerOperator: !operator, !owner"
        );
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "OwnerOperator: !operator");
        _;
    }

    function addOperator(address operator) external virtual onlyOwner {
        require(
            operator != address(0),
            "OwnerOperator: operator is the zero address"
        );
        operators[operator] = true;
    }

    function removeOperator(address operator) external virtual onlyOwner {
        require(
            operator != address(0),
            "OwnerOperator: operator is the zero address"
        );
        operators[operator] = false;
    }
}
