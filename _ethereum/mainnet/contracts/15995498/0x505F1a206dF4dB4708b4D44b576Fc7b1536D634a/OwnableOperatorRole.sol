// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./AccessControl.sol";

contract OwnableOperatorRole is Ownable, AccessControl {


    modifier onlyOperator() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "OperatorRole: caller does not have the Operator role");
        _;
    }

    function addOperator(address account) external onlyOwner {
        _setupRole(DEFAULT_ADMIN_ROLE, account);
    }

    function removeOperator(address account) external onlyOwner {
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
    }
}
