// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

import "./TheCollectorsNFTVaultBaseFacet.sol";
import "./TheCollectorsNFTVaultTokenManagerFacet.sol";

/*
    @dev
    Unfortunately we are shutting down :(
*/
contract TheCollectorsNFTVaultWindDownFacet is TheCollectorsNFTVaultBaseFacet {
    using Counters for Counters.Counter;
    using Strings for uint256;

    function migrate(uint64 vaultId) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        address payable assetsHolder = _as.assetsHolders[vaultId];

        require(msg.sender == 0x8C47db74F053e81d2d8A00079c4430588605005d, "You are not Gemzy");

        IAssetsHolderImpl(assetsHolder).transferToken(
            vaultExtension.isERC1155, msg.sender, vault.collection, vault.tokenId
        );
    }

}
