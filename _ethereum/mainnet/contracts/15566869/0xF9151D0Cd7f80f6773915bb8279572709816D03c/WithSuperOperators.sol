//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./WithOwnerUpgradeable.sol";
import "./ContextUpgradeable.sol";

contract WithSuperOperators is ContextUpgradeable, WithOwnerUpgradeable {
    mapping(address => bool) internal _superOperators;

    event SuperOperator(address indexed superOperator, bool indexed enabled);

    /// @notice Enable or disable the ability of `superOperator` to transfer tokens of all (superOperator rights).
    /// @param superOperator address that will be given/removed superOperator right.
    /// @param enabled set whether the superOperator is enabled or disabled.
    function setSuperOperator(address superOperator, bool enabled) external onlyOwner {
        _superOperators[superOperator] = enabled;
        emit SuperOperator(superOperator, enabled);
    }

    /// @notice check whether address `who` is given superOperator rights.
    /// @param who The address to query.
    /// @return whether the address has superOperator rights.
    function isSuperOperator(address who) public view returns (bool) {
        return _superOperators[who];
    }
}
