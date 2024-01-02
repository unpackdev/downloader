// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.19;

import "./IRewardsRedeemerFactory.sol";

import "./IRewardsRedeemer.sol";
import "./RewardsRedeemer.sol";

import "./Clones.sol";
import "./AccessControl.sol";

/**
 * See IRewardsRedeemerFactory.sol
 */
contract RewardsRedeemerFactory is IRewardsRedeemerFactory, AccessControl {
    /// CONSTANTS
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PARTNER_ROLE = keccak256("PARTNER_ROLE");

    /// STORAGE
    // solhint-disable-next-line var-name-mixedcase
    address public immutable RewardsRedeemerTemplate;

    mapping(address partner => IRewardsRedeemer redeemer) public redeemers;

    constructor() {
        _setupRole(ADMIN_ROLE, msg.sender);
        RewardsRedeemerTemplate = address(new RewardsRedeemer());
    }

    /* @inheritdoc IRewardsRedeemerFactory */
    function addPartner(address partner) external onlyRole(ADMIN_ROLE) {
        _grantRole(PARTNER_ROLE, partner);
    }

    /* @inheritdoc IRewardsRedeemerFactory */
    function removePartner(address partner) external onlyRole(ADMIN_ROLE) {
        _revokeRole(PARTNER_ROLE, partner);
    }

    /* @inheritdoc IRewardsRedeemerFactory */
    function createRewardsRedeemer(
        address rewardsToken
    ) external onlyRole(PARTNER_ROLE) returns (IRewardsRedeemer) {
        RewardsRedeemer rewardsRedeemer = RewardsRedeemer(Clones.clone(RewardsRedeemerTemplate));

        rewardsRedeemer.initialize(_msgSender(), rewardsToken);

        redeemers[_msgSender()] = rewardsRedeemer;

        emit RewardsRedeemerCreated(rewardsRedeemer, _msgSender());

        return rewardsRedeemer;
    }
}
