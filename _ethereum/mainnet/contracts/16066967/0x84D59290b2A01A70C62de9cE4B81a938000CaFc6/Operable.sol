// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Context.sol";
import "./Strings.sol";

abstract contract Operable is Context {
    mapping(address => bool) _operators;

    modifier onlyOperator() {
        _checkOperatorRole(_msgSender());
        _;
    }

    function isOperator(address _operator) public view returns (bool) {
        return _operators[_operator];
    }

    function _grantOperatorRole(address _candidate) internal {
        require(
            !_operators[_candidate],
            string(
                abi.encodePacked(
                    "account ",
                    Strings.toHexString(uint160(_msgSender()), 20),
                    " is already has an operator role"
                )
            )
        );
        _operators[_candidate] = true;
    }

    function _revokeOperatorRole(address _candidate) internal {
        _checkOperatorRole(_candidate);
        delete _operators[_candidate];
    }

    function _checkOperatorRole(address _operator) internal view {
        require(
            _operators[_operator],
            string(
                abi.encodePacked(
                    "account ",
                    Strings.toHexString(uint160(_msgSender()), 20),
                    " is not an operator"
                )
            )
        );
    }
}