// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./Governable.sol";
import "./IDistributionLogic.sol";
import "./DistributionStorage.sol";
import "./IBeacon.sol";
import "./BeaconStorage.sol";
import "./Pausable.sol";

/**
 * @title DistributionProxy
 * @author MirrorXYZ
 */
contract DistributionProxy is
    BeaconStorage,
    Governable,
    DistributionStorage,
    Pausable
{
    constructor(
        address beacon_,
        address owner_,
        address team_,
        address token_,
        bytes32 rootNode_,
        address ensRegistry_,
        address treasury_
    )
        BeaconStorage(beacon_)
        Governable(owner_)
        DistributionStorage(rootNode_, ensRegistry_)
        Pausable(true)
    {
        // Initialize the logic, supplying initialization calldata.
        team = team_;
        token = token_;
        treasury = treasury_;
    }

    fallback() external payable {
        address logic = IBeacon(beacon).logic();

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), logic, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    receive() external payable {}
}
