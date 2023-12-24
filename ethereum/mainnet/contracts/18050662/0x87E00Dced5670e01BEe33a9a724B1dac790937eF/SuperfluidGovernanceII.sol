// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.19;

import "./UUPSProxy.sol";
import "./Ownable.sol";
import "./UUPSProxiable.sol";
import "./SuperfluidGovernanceBase.sol";
import "./ISuperfluid.sol";

/**
 * @title A proxy for governance which is both ownable and upgradable
 * @author Superfluid
 * IMPORTANT! Make sure the inheritance order remains in sync with the logic contract (Ownable first)!
 */
// solhint-disable-next-line no-empty-blocks
contract SuperfluidGovernanceIIProxy is Ownable, UUPSProxy { }

contract SuperfluidGovernanceII is
    Ownable,
    UUPSProxiable,
    SuperfluidGovernanceBase
{
    error SF_GOV_II_ONLY_OWNER();
    function _requireAuthorised() private view {
        if (owner() != _msgSender()) revert SF_GOV_II_ONLY_OWNER();
    }

    /**************************************************************************
    * UUPSProxiable
    **************************************************************************/

    function proxiableUUID() public pure override returns (bytes32) {
        return keccak256("org.superfluid-finance.contracts.SuperfluidGovernanceII.implementation");
    }

    function updateCode(address newAddress)
        external override
    {
        _requireAuthorised();
        _updateCodeAddress(newAddress);
    }

    /**************************************************************************
    * SuperfluidGovernanceBase
    **************************************************************************/

    function _requireAuthorised(ISuperfluid /*host*/)
        internal view override
    {
        _requireAuthorised();
    }
}
