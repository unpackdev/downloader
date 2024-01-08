// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./OwnerManagable.sol";

contract MintAuthorization is OwnerManagable {
    address public immutable layer2;

    constructor(
        address _owner,
        address _layer2,
        address[] memory _initialMinters,
        address[] memory _initialUpdaters
    ) {
        // Initially allow the deploying account to add minters/updaters
        owner = msg.sender;

        layer2 = _layer2;

        for (uint256 i = 0; i < _initialMinters.length; i++) {
            addActiveMinter(_initialMinters[i]);
        }

        for (uint256 i = 0; i < _initialUpdaters.length; i++) {
            addUpdater(_initialUpdaters[i]);
        }

        // From now on, only the specified owner can add/remove minters/updaters
        owner = _owner;
    }
}
