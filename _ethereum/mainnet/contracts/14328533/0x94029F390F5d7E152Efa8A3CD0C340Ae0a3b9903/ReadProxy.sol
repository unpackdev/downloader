// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./OwnedwManager.sol";

// solhint-disable payable-fallback

// https://docs.synthetix.io/contracts/source/contracts/readproxy
contract ReadProxy is OwnedwManager {
    address public target;

    constructor(address _owner) public OwnedwManager(_owner, _owner) {}

    function setTarget(address _target) external onlyOwner {
        target = _target;
        emit TargetUpdated(target);
    }

    fallback() external {
        // The basics of a proxy read call
        // Note that msg.sender in the underlying will always be the address of this contract.
        assembly {
            calldatacopy(0, 0, calldatasize())

            // Use of staticcall - this will revert if the underlying function mutates state
            let result := staticcall(gas(), sload(target.slot), 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            if iszero(result) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }

    event TargetUpdated(address newTarget);
}
