// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AccessControl.sol";

contract BustadAssetOracleSimulatorV2 is AccessControl {
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");

    event AddedRealEstate(
        string indexed cadastralNumber,
        /* string note, */
        uint256 value,
        uint256 date,
        uint256 share
    );

    event RemovedRealEstate(
        string indexed cadastralNumber,
        /* string note, */
        uint256 sellPrice,
        uint256 purchasePrice,
        uint256 date,
        uint256 share
    );

    event UpdateRealEstateValue(
        string indexed cadastralNumber,
        /* string note, */
        uint256 indexed value,
        uint256 indexed date
    );

    event TestEvent(
        string indexed testData        
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addRealEstate(
        string calldata cadastralNumber,
        /* string calldata note, */
        uint256 value,
        uint256 date,
        uint256 share
    ) external onlyRole(MAINTAINER_ROLE) {
        emit AddedRealEstate(cadastralNumber, /* note, */ value, date, share);
    }

    function removeRealEstate(
        string calldata cadastralNumber,
        /* string calldata note, */
        uint256 sellPrice,
        uint256 purchasePrice,
        uint256 date,
        uint256 share
    ) external onlyRole(MAINTAINER_ROLE) {
        emit RemovedRealEstate(
            cadastralNumber,
            /* note, */
            sellPrice,
            purchasePrice,
            date,
            share
        );
    }

    function updateRealEstateValue(
        string calldata cadastralNumber,
        /* string calldata note, */
        uint256 value,
        uint256 date
    ) external onlyRole(MAINTAINER_ROLE) {
        emit UpdateRealEstateValue(
            cadastralNumber,
            /* note, */
            value,
            date
        );
    }

    function test(
        string calldata testdata        
    ) external onlyRole(MAINTAINER_ROLE) {
        emit TestEvent(testdata);
    }
}
