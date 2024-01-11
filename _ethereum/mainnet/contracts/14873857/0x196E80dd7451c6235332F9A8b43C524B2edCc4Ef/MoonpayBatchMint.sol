// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "./CollectionV2.sol";
import "./AccessControl.sol";

contract MoonpayBatchMint is AccessControl {
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mintBatch(
        address[] calldata collectionAddrs,
        uint256[] calldata tokenIds,
        address[] calldata wallets
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            collectionAddrs.length == tokenIds.length,
            "Input length must match"
        );
        require(
            collectionAddrs.length == wallets.length,
            "Input length must match"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            IMintableInterface collection = IMintableInterface(
                collectionAddrs[i]
            );
            try collection.mint(wallets[i], tokenIds[i]) {} catch {}
        }
    }
}
