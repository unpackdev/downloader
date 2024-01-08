// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./VariableExpiringMultiParty.sol";

/**
 * @title Provides convenient Variable Expiring Multi Party contract utilities.
 * @dev Using this library to deploy VEMP's allows calling contracts to avoid importing the full VEMP bytecode.
 */
library VariableExpiringMultiPartyLib {
    /**
     * @notice Returns address of new VEMP deployed with given `params` configuration.
     * @dev Caller will need to register new VEMP with the Registry to begin requesting prices. Caller is also
     * responsible for enforcing constraints on `params`.
     * @param params is a `ConstructorParams` object from VariableExpiringMultiParty.
     * @return address of the deployed VariableExpiringMultiParty contract
     */
    function deploy(VariableExpiringMultiParty.ConstructorParams memory params) public returns (address) {
        VariableExpiringMultiParty derivative = new VariableExpiringMultiParty(params);
        return address(derivative);
    }
}
