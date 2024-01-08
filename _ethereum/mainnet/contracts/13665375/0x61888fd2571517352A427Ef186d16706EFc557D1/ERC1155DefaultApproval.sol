// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./ERC1155Upgradeable.sol";

abstract contract ERC1155DefaultApproval is ERC1155Upgradeable {
    mapping(address => bool) private defaultApprovals;

    event DefaultApproval(address indexed operator, bool hasApproval);

    function __ERC1155DefaultApproval_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155_init_unchained("");
    }

    function _setDefaultApproval(address operator, bool hasApproval) internal {
        defaultApprovals[operator] = hasApproval;
        emit DefaultApproval(operator, hasApproval);
    }

    function isApprovedForAll(address _owner, address _operator) public virtual override view returns (bool) {
        return defaultApprovals[_operator] || super.isApprovedForAll(_owner, _operator);
    }
    uint256[50] private __gap;
}
