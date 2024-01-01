// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Policy.sol";
import "./Policed.sol";
import "./Proposal.sol";
import "./ECO.sol";
import "./ECOx.sol";

/** @title DeployRootPolicyFundw
 * A proposal to send some root policy funds to another
 * address (multisig, lockup, etc)
 */
contract AccessRootPolicyFunds is Policy, Proposal {
    address public immutable recipient;

    uint256 public immutable ecoAmount;

    uint256 public immutable ecoXAmount;

    constructor(
        address _recipient,
        uint256 _ecoAmount,
        uint256 _ecoXAmount
    ) {
        recipient = _recipient;
        ecoAmount = _ecoAmount;
        ecoXAmount = _ecoXAmount;
    }

    function name() public pure override returns (string memory) {
        return "Layer 3 Ecollective subDAO funding request";
    }

    function description() public pure override returns (string memory) {
        return
            "The Layer 3 Ecollective is a dedicated assembly of individuals deeply devoted to developing, maintaining, and growing the community associated with the Eco currency, the Eco protocol, and its accompanying products. Guided by the Econstitution and Builders Ecollective principles, our mission focuses on evangelizing, creating, onboarding, governing, and monetizing within the community.";
    }

    function url() public pure override returns (string memory) {
        return
            "https://forums.eco.org/t/layer-3-ecollective-subdao-funding-request/318";
    }

    function enacted(address) public override {
        bytes32 _ecoID = keccak256("ECO");
        ECO eco = ECO(policyFor(_ecoID));

        bytes32 _ecoXID = keccak256("ECOx");
        ECOx ecoX = ECOx(policyFor(_ecoXID));

        // if either ecoAmount or ecoXAmount are zero, parts related to that token should instead be removed
        eco.transfer(recipient, ecoAmount);
        ecoX.transfer(recipient, ecoXAmount);
    }
}
