// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MagicFolkOld.sol";
import "./MagicFolk.sol";

contract MigrationProxy {
    MagicFolkOld _oldContract;
    MagicFolk _newContract;

    constructor(address oldContract, address newContract) {
        _oldContract = MagicFolkOld(oldContract);
        _newContract = MagicFolk(newContract);
    }

    function burn(uint256[] calldata tokenIds) external {
        uint256 qty = tokenIds.length;
        for (uint256 i = 0; i < qty; i++) {
            _oldContract.transferFrom(msg.sender, address(this), tokenIds[i]);
        }
        _newContract.migrationMint(msg.sender, qty);
    }
}
