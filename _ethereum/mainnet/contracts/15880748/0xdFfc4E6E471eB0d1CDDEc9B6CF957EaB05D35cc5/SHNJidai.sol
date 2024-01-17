// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./TwoStage.sol";

contract SHNJidai is TwoStage {
    function initialize(
        bytes32 whitelistMerkleTreeRoot_,
        address royaltiesRecipient_,
        uint256 royaltiesValue_,
        address[] memory shareholders,
        uint256[] memory shares
    ) public initializerERC721A initializer {
        __ERC721A_init("SHOUNEN", "SHN");
        __Ownable_init();
        __AdminManager_init_unchained();
        __Supply_init_unchained(5555);
        __AdminMint_init_unchained();
        __Whitelist_init_unchained();
        __BalanceLimit_init_unchained();
        __UriManager_init_unchained(
            "https://ipfs.io/ipfs/QmSqBvu4AMtxMg5TYrzxHdqVXJD2dsGq6bkLJJJS7sTxvR/",
            ".json"
        );
        __CustomPaymentSplitter_init(shareholders, shares);
        __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);
        updateMerkleTreeRoot(uint8(Stage.Whitelist), whitelistMerkleTreeRoot_);
        updateBalanceLimit(uint8(Stage.Whitelist), 1);
        updateBalanceLimit(uint8(Stage.Public), 1);
        setPrice(uint8(Stage.Whitelist), 0.03 ether);
        setPrice(uint8(Stage.Public), 0.03 ether);
    }

    function _startTokenId()
        internal
        pure
        override(ERC721AUpgradeable)
        returns (uint256)
    {
        return 1;
    }
}
