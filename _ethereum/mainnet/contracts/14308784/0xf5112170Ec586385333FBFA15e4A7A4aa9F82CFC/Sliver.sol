// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "./ERC20.sol";
import "./NativeMetaTransaction.sol";
import "./ContextMixin.sol";
import "./AccessControlMixin.sol";
import "./IMintableERC20.sol";

contract Sliver is ERC20, ContextMixin, AccessControlMixin, IMintableERC20 {
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    constructor(address predicateProxy) ERC20("Lucky Races Sliver", "$SLIVER") {
        _setupRole(PREDICATE_ROLE, predicateProxy);
        _setupRole(DEFAULT_ADMIN_ROLE, msgSender());
    }

    function mint(address user, uint256 amount) public only(PREDICATE_ROLE) {
        _mint(user, amount);
    }
}
