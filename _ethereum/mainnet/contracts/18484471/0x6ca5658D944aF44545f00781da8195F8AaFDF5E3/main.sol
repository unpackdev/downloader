// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./variables.sol";

contract Events {
    event LogExecute(
        address newUserModule,
        address newAdminModule,
        address newLeverageModule,
        address newRebalanceModule,
        address newRefinanceModule,
        address newDsaModule,
        address newWIthdrawalsModule,
        uint256 blockTimestamp
    );
}

contract InitializeVault is NewSignatures, Events {
    /***********************************|
    |              ERRORS               |
    |__________________________________*/
    error InitializeVault__NotGovernance();

    /***********************************|
    |              MODIFIERS            |
    |__________________________________*/
    modifier onlyGovernance() {
        if (msg.sender != GOVERNANCE) {
            revert InitializeVault__NotGovernance();
        }
        _;
    }

    /// @dev Executes Lite vault upgrade with initializing version 2.
    function execute() public onlyGovernance {
        // Remove old implementations
        vault.removeImplementation(OLD_USER_MODULE);
        vault.removeImplementation(OLD_ADMIN_MODULE);
        vault.removeImplementation(OLD_LEVERAGE_MODULE);
        vault.removeImplementation(OLD_REBALANCER_MODULE);
        vault.removeImplementation(OLD_REFINANCE_MODULE);
        vault.removeImplementation(OLD_DSA_MODULE);

        // Add new signatures
        vault.addImplementation(NEW_USER_MODULE, userSigs());
        vault.addImplementation(NEW_ADMIN_MODULE, adminSigs());
        vault.addImplementation(NEW_LEVERAGE_MODULE, leverageSigs());
        vault.addImplementation(NEW_REBALANCER_MODULE, rebalancerSigs());
        vault.addImplementation(NEW_REFINANCE_MODULE, refinanceSigs());
        vault.addImplementation(NEW_DSA_MODULE, dsaSigs());
        vault.addImplementation(NEW_WITHDRAWALS_MODULE, withdrawalsSigs());

        // Update dummy implementation
        vault.setDummyImplementation(NEW_DUMMY_IMPLEMENTATION);

        // Call Initialize V2
        vault.initializeV2();

        // Tranfer ownership back to governance
        vault.setAdmin(GOVERNANCE);

        emit LogExecute(
            NEW_USER_MODULE,
            NEW_ADMIN_MODULE,
            NEW_LEVERAGE_MODULE,
            NEW_REBALANCER_MODULE,
            NEW_REFINANCE_MODULE,
            NEW_DSA_MODULE,
            NEW_WITHDRAWALS_MODULE,
            block.timestamp
        );
    }
}
