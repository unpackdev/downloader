// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "./CollectionV2.sol";
import "./AccessControl.sol";


contract LegacyMintBatch is AccessControl {

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mintBatch(
        address collectionAddr,
        uint256[] calldata tokenIds,
        address wallet
    ) public onlyRole(DEFAULT_ADMIN_ROLE)  {
        IMintableInterface collection = IMintableInterface(collectionAddr);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            collection.mint(wallet, tokenIds[i]);
        }
    }
}
