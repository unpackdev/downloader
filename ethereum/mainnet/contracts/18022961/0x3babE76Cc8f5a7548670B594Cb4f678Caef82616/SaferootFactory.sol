// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Clones.sol";
import "./Saferoot.sol";
import "./SaferootDefinitions.sol";
import "./ErrorReporter.sol";

/**
 * @title SaferootFactory Contract
 * @author Staging Labs
 * @notice SaferootFactory creates a onetime saferootImplementation contract used as the delegated contract logic
 *         for the different Saferoot instances to reduce bytecode/deployment costs.
 */
contract SaferootFactory is
    ErrorReporter
{
    address public immutable saferootImplementation;

    event SaferootDeployed(
        address contractAddress,
        address service,
        address user,
        address backup
    );

    /**
     * @notice create and store immutable implementation contract
     */
    constructor() {
        saferootImplementation = address(new Saferoot());
    }

    /**
     * @notice Deploy a new Saferoot contract
     * @param _service address of service
     * @param _backup backup wallet address
     */
    function createSaferoot(
        address _service,
        address _backup
    ) external returns (address) {
        if (_service == address(0) || _backup == address(0)) {
            revert ZeroAddress();
        }

        address clone = Clones.clone(saferootImplementation);
        Saferoot(clone).initialize(
            _service,
            msg.sender,
            _backup
        );
        emit SaferootDeployed(
            clone,
            _service,
            msg.sender,
            _backup
        );
        return clone;
    }

    /**
     * @notice Deploy a new Saferoot contract with safeguards
     * @param _service address of service
     * @param _backup backup wallet address
     * @param _safeguardEntries starting safeguards for deployment
     */
    function createSaferootWithSafeguards(
        address _service,
        address _backup,
        SafeguardEntry[] calldata _safeguardEntries
    ) external returns (address) {
        if (_service == address(0) || _backup == address(0)) {
            revert ZeroAddress();
        }
        address clone = Clones.clone(saferootImplementation);
        Saferoot(clone).initializeAndAddSafeguard(
            _service,
            msg.sender,
            _backup,
            _safeguardEntries
        );
        emit SaferootDeployed(
            clone,
            _service,
            msg.sender,
            _backup
        );

        return clone;
    }
}