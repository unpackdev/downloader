// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.6.0;

import "./ERC777.sol";

import "./GovernanceInterface.sol";

/** 
 * @title L7L token is used to stake for governance of LE7EL
 
 * @dev L7L token is rewarded to players and used as an incentive measure.
 */
contract L7lToken is ERC777 {
    /** 
     * @dev Distribution of initial supply.
     *
     * Of total supply of 100m L7L:
     * 30% goes to LE7EL developers
     * 20% is reserved for future IDOs (held by DAO)
     * 50% is reserved for rewards to players (held by DAO)
     *
     * @param _governance Governance contract address.
     * @param defaultOperators Contract addresses which can freely interact with L7L tokens.
     */
    constructor(address _governance, address[] memory defaultOperators) public ERC777("LE7EL", "L7L", defaultOperators) {
        GovernanceInterface TrustedGovernance = GovernanceInterface(_governance);
        address beneficiaryAddress = TrustedGovernance.beneficiary();
        address managerAddress = TrustedGovernance.manager();

        _mint(managerAddress, 30000000 * 10 ** 18, "", "");
        _mint(beneficiaryAddress, 80000000 * 10 ** 18, "", "");
    }
}
