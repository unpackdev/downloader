// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "./IMintableERC20.sol";
import "./AccessControlMixin.sol";

contract GenesisETH is ERC20, IMintableERC20, AccessControlMixin {
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    constructor(address depositManager_) ERC20("Genesis", "GENESIS") {
        _setupContractId("Genesis erc20");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PREDICATE_ROLE, depositManager_);
    }

    /**
     * @dev See {IMintableERC20-mint}.
     */
    function mint(address user, uint256 amount) external override only(PREDICATE_ROLE) {
        _mint(user, amount);
    }
}
