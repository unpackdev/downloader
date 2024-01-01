// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./Address.sol";
import "./AccessControlUpgradeable.sol";
import "./IMinimalTreasury.sol";

contract MinimalTreasury is IMinimalTreasury, AccessControlUpgradeable {
    using Address for address payable;

    function initialize() public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function withdraw(address payable _to, uint256 _amount) external
    onlyRole(DEFAULT_ADMIN_ROLE) {
        _assertNonZero(_to);
        _assertSufficientFunds(_amount);

        _to.sendValue(_amount);
        emit Withdrawn(_to, _amount);
    }

    function _assertSufficientFunds(uint256 _amount) internal view returns (uint256) {
        if (_amount > address(this).balance) {
            revert InsufficientFunds();
        }

        return _amount;
    }

    function _assertNonZero(address _address) internal pure returns (address) {
        if (_address == address(0)) {
            revert ZeroAddress();
        }
        return _address;
    }
}
