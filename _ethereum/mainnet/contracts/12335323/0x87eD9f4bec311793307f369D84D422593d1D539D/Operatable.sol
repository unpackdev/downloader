// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Roles.sol";
//import "./ERC173.sol";
import "./Ownable.sol";

abstract contract Operatable is Ownable {
    using Roles for Roles.Role;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;
    Roles.Role private operators;

    constructor() {
        operators.add(msg.sender);
        _paused = false;
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender), "Must be operator");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function transferOwnership(address _newOwner)
        public
        override
        onlyOperator()
    {
        transferOwnership(_newOwner);
    }

    function isOperator(address account) public view returns (bool) {
        return operators.has(account);
    }

    function addOperator(address account) public onlyOperator() {
        operators.add(account);
        emit OperatorAdded(account);
    }

    function removeOperator(address account) public onlyOperator() {
        operators.remove(account);
        emit OperatorRemoved(account);
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    function pause() public onlyOperator() whenNotPaused() {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOperator() whenPaused() {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}
