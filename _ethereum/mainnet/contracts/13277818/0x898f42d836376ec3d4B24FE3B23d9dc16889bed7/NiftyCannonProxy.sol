// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";

/**
 * @title Nifty Cannon Proxy
 *
 * @notice Delegates calls to the NiftyCannon implementation contract,
 * such that functions on it execute in the context (address, storage)
 * of this proxy, allowing the implementation contract to be upgraded
 * without losing the accumulated state data.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract NiftyCannonProxy is TransparentUpgradeableProxy {

    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) payable TransparentUpgradeableProxy(_logic, _admin, _data) {}

}