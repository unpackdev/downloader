// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;

import "./OwnableUpgradeable.sol";

contract ERC721GenOperatorRole is OwnableUpgradeable {
    mapping (address => bool) operators;

    function __ERC721GenOperatorRole_init(address operator) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC721GenOperatorRole_init_unchained(operator);
    }

    function __ERC721GenOperatorRole_init_unchained(address operator) internal initializer {
        operators[operator] = true;
    }

    modifier onlyOperator() {
        require(operators[_msgSender()], "OperatorRole: caller is not the operator");
        _;
    }

    uint256[50] private __gap;
}
