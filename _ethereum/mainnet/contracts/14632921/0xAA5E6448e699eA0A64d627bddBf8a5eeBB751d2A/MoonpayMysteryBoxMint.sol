// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

pragma experimental ABIEncoderV2;

import "./AccessControl.sol";

interface IMysteryBox {
    enum Tiers {
        TierOne,
        TierTwo,
        TierThree
    }

    function buyCreditMysteryBox(
        address _user,
        Tiers _tier,
        string calldata _purchaseId
    ) external;

    function getAvailable(Tiers _tier) external view returns (uint256);
}

contract MoonpayMysteryBoxMint is AccessControl {
    mapping(string => bool) private debounce;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mintBatch(
        address collectionAddr,
        IMysteryBox.Tiers[] calldata tierIds,
        address[] calldata wallets,
        string[] calldata transactionIds
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tierIds.length == wallets.length, "Input length must match");
        require(
            tierIds.length == transactionIds.length,
            "Input length must match"
        );
        IMysteryBox mysterybox = IMysteryBox(collectionAddr);
        for (uint256 i = 0; i < tierIds.length; i++) {
            if (
                mysterybox.getAvailable(tierIds[i]) > 0 &&
                debounce[transactionIds[i]] == false
            ) {
                mysterybox.buyCreditMysteryBox(
                    wallets[i],
                    tierIds[i],
                    transactionIds[i]
                );
                debounce[transactionIds[i]] = true;
            }
        }
    }
}
