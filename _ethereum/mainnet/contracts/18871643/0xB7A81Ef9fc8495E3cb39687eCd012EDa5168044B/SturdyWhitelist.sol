// SPDX-License-Identifier: ISC
pragma solidity ^0.8.21;

// ======================= SturdyWhitelist ==========================

import "./Ownable2Step.sol";

contract SturdyWhitelist is Ownable2Step {
    /// @notice Sturdy Deployer Whitelist mapping.
    mapping(address => bool) public sturdyDeployerWhitelist;

    constructor() Ownable2Step() {}

    /// @notice The ```SetSturdyDeployerWhitelist``` event fires whenever a status is set for a given address.
    /// @param _address address being set.
    /// @param _bool approval being set.
    event SetSturdyDeployerWhitelist(address indexed _address, bool _bool);

    /// @notice The ```setSturdyDeployerWhitelist``` function sets a given address to true/false for use as a custom deployer.
    /// @param _addresses addresses to set status for.
    /// @param _bool status of approval.
    function setSturdyDeployerWhitelist(address[] calldata _addresses, bool _bool) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            sturdyDeployerWhitelist[_addresses[i]] = _bool;
            emit SetSturdyDeployerWhitelist(_addresses[i], _bool);
        }
    }
}
