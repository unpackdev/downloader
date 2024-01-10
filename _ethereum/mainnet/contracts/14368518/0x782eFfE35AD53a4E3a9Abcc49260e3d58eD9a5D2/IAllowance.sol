// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract IAllowance {
    mapping(address => bool) private allowedOperators;

    modifier allowedOperator() {
        require(allowedOperators[msg.sender] == true, 'Caller is not allowed');
        _;
    }

    /**
     * @dev Adds address to a specific list and allows to call methods with
     * allowedOperator modifier
     */
    function setAllowance(address operator) external virtual;

    /**
     * @dev Removes address from storage and forbids calling methods with
     * allowedOperator modifier
     */
    function removeAllowance(address operator) external virtual;

    function _setAllowance(address _operator) internal {
        require(_operator != address(0), 'Address should not be empty');
        allowedOperators[_operator] = true;
    }

    function _removeAllowance(address _operator) internal {
        require(_operator != address(0), 'Address should not be empty');
        allowedOperators[_operator] = false;
    }
}
