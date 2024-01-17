// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "./AccessControl.sol";

interface IMintableInterface {
    function mint(address collection, address buyer) external returns (uint256);

    function mintBatch(
        address collection,
        address buyer,
        uint256 count
    ) external returns (uint256[] memory);
}

contract MoonpayBatchMintAutoEdition is AccessControl {
    event MoonpayPurchase(
        address collection,
        address user,
        string purchaseId,
        uint256[] tokenIds
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mintBatch(
        address factory,
        address[] calldata collectionAddrs,
        address[] calldata wallets,
        uint256[] calldata quantity,
        string[] calldata transactionIds
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            collectionAddrs.length == wallets.length,
            "Input length must match"
        );
        require(
            collectionAddrs.length == wallets.length,
            "Input length must match"
        );
        require(
            collectionAddrs.length == quantity.length,
            "Input length must match"
        );
        require(
            collectionAddrs.length == transactionIds.length,
            "Input length must match"
        );
        for (uint256 i = 0; i < collectionAddrs.length; i++) {
            IMintableInterface factory = IMintableInterface(factory);

            mintPurchase(
                factory,
                collectionAddrs[i],
                wallets[i],
                quantity[i],
                transactionIds[i]
            );
        }
    }

    function mintPurchase(
        IMintableInterface factory,
        address collectionAddr,
        address wallet,
        uint256 quantity,
        string memory transactionId
    ) internal {
        try factory.mintBatch(collectionAddr, wallet, quantity) returns (
            uint256[] memory result
        ) {
            emit MoonpayPurchase(collectionAddr, wallet, transactionId, result);
        } catch {}
    }
}
