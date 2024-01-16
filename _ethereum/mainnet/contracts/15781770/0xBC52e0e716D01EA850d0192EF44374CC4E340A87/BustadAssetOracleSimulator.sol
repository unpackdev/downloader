// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AccessControl.sol";

contract BustadAssetOracleSimulator is AccessControl {
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");

    event AddedRealEstate(
        string cadastralNumber,
        string note,
        uint256 estimatedValue,
        uint256 purchaseDate,
        uint256 share
    );

    event RemovedRealEstate(
        string cadastralNumber,
        string note,
        uint256 estimatedValue,
        uint256 sellDate,
        uint256 share
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addRealEstate(
        string calldata cadastralNumber,
        string calldata note,
        uint256 estimatedValue,
        uint256 purchaseDate,
        uint256 share
    ) external onlyRole(MAINTAINER_ROLE) {
        emit AddedRealEstate(
            cadastralNumber,
            note,
            estimatedValue,
            purchaseDate,
            share
        );
    }

    function removeRealEstate(
        string calldata cadastralNumber,
        string calldata note,
        uint256 estimatedValue,
        uint256 sellDate,
        uint256 share
    ) external onlyRole(MAINTAINER_ROLE) {
        emit RemovedRealEstate(
            cadastralNumber,
            note,
            estimatedValue,
            sellDate,
            share
        );
    }
}
