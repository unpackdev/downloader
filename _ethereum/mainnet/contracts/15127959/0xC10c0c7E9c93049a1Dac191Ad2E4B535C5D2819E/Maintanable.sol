// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "./Ownable.sol";
import "./AccessControl.sol";
import "./Address.sol";

contract Maintanable is Ownable, AccessControl {
    using Address for address;

    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
    bytes32 public constant MAINTAINER_ROLE = keccak256('MAINTAINER_ROLE');

    modifier onlyMaintainer {
        require(msg.sender == owner() || hasRole(MAINTAINER_ROLE, msg.sender),
            'Maintanable: only owner and or maintainers can call this method');
        _;
    }

    constructor() {
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(MAINTAINER_ROLE, ADMIN_ROLE);

        _setupRole(ADMIN_ROLE, address(this));
        _setupRole(MAINTAINER_ROLE, owner());
    }

    function addMaintainer(address account) external onlyOwner returns (bool) {
        bytes4 selector = this.grantRole.selector;
        address(this).functionCall(abi.encodeWithSelector(selector, MAINTAINER_ROLE, account));
        return true;
    }

    function delMaintainer(address account) external onlyOwner returns (bool) {
        bytes4 selector = this.revokeRole.selector;
        address(this).functionCall(abi.encodeWithSelector(selector, MAINTAINER_ROLE, account));
        return true;
    }

    function isMaintainer(address account) external view returns (bool) {
        return hasRole(MAINTAINER_ROLE, account);
    }
}