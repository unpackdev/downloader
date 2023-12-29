// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import "./Address.sol";
import {DefaultOperatorFiltererUpgradeable} from
    "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

import "./MythicsV1.sol";

/**
 * @title Mythics V2
 * @notice Adding capabilities to interact with the operator filter registry.
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 */
contract MythicsV2 is MythicsV1 {
    using Address for address;

    /**
     * @notice Calling the operator filter registry with given calldata.
     * @dev The registry contract did not foresee role-based contract access
     * control -- only the contract itself, or its (EIP-173) owner is allowed to
     * change subscription settings. To work around this, we enforce
     * authorisation here and forward arbitrary calldata to the registry.
     * Use with care!
     */
    function callOperatorFilterRegistry(bytes calldata cdata)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
        returns (bytes memory)
    {
        return address(OPERATOR_FILTER_REGISTRY).functionCall(cdata);
    }
}
