// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*//////////////////////////////////////////////////////////////////////////
                            Chainalysis Sanctions Oracle
//////////////////////////////////////////////////////////////////////////*/

interface ChainalysisSanctionsOracle {
    function isSanctioned(address addr) external view returns (bool);
}

/*//////////////////////////////////////////////////////////////////////////
                              Errors
//////////////////////////////////////////////////////////////////////////*/

error SanctionedAddress();

/*//////////////////////////////////////////////////////////////////////////
                            Sanctions Compliance
//////////////////////////////////////////////////////////////////////////*/

/// @title Sanctions Compliance
/// @notice Abstract contract to comply with U.S. sanctioned addresses
/// @dev Uses the Chainalysis Sanctions Oracle for checking sanctions
/// @author transientlabs.xyz
/// @custom:last-updated 2.5.0
contract SanctionsCompliance {
    /*//////////////////////////////////////////////////////////////////////////
                                State Variables
    //////////////////////////////////////////////////////////////////////////*/

    ChainalysisSanctionsOracle public oracle;

    /*//////////////////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////////////////*/

    event SanctionsOracleUpdated(address indexed prevOracle, address indexed newOracle);

    /*//////////////////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////////////////*/

    constructor(address initOracle) {
        _updateSanctionsOracle(initOracle);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Internal Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Internal function to change the sanctions oracle
    /// @param newOracle The new sanctions oracle address
    function _updateSanctionsOracle(address newOracle) internal {
        address prevOracle = address(oracle);
        oracle = ChainalysisSanctionsOracle(newOracle);

        emit SanctionsOracleUpdated(prevOracle, newOracle);
    }

    /// @notice Internal function to check the sanctions oracle for an address
    /// @dev Disable sanction checking by setting the oracle to the zero address
    /// @param sender The address that is trying to send money
    /// @param shouldRevertIfSanctioned A flag indicating if the call should revert if the sender is sanctioned. Set to false if wanting to get a result.
    /// @return isSanctioned Boolean indicating if the sender is sanctioned
    function _isSanctioned(address sender, bool shouldRevertIfSanctioned) internal view returns (bool isSanctioned) {
        if (address(oracle) == address(0)) {
            return false;
        }
        isSanctioned = oracle.isSanctioned(sender);
        if (shouldRevertIfSanctioned && isSanctioned) revert SanctionedAddress();
        return isSanctioned;
    }
}
