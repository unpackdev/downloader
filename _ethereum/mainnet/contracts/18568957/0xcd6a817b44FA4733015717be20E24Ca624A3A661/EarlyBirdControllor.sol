// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./EarlyBird.sol";
import "./Ownable.sol";

import "./AccessControlDefaultAdminRules.sol";

contract EarlyBirdControllor is EarlyBird, AccessControlDefaultAdminRules {

    bytes32 public constant MARKET_ROLE = keccak256("MARKET_ROLE"); 

    constructor() AccessControlDefaultAdminRules(
        1 days,
        msg.sender
    ) {
        _setRoleAdmin(MARKET_ROLE, DEFAULT_ADMIN_ROLE);
    }

    /*
     * @dev Set the early bird addresses.
     * @param _addrs The early bird addresses.
     */
    function setEarlyBirds(address[] memory _addrs) public override onlyRole(MARKET_ROLE) {
        super.setEarlyBirds(_addrs);
    }

    /*
     * @dev Set the early bird round.
     * @param round_ The early bird round.
     */
    function setEarlyBirdRound(bool round_) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        super.setEarlyBirdRound(round_);
    }
}
