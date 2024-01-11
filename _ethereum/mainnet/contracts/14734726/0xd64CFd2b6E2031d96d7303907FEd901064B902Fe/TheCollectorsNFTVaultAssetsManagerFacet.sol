// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*

████████╗██╗  ██╗███████╗     ██████╗ ██████╗ ██╗     ██╗     ███████╗ ██████╗████████╗ ██████╗ ██████╗ ███████╗
╚══██╔══╝██║  ██║██╔════╝    ██╔════╝██╔═══██╗██║     ██║     ██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██╔════╝
   ██║   ███████║█████╗      ██║     ██║   ██║██║     ██║     █████╗  ██║        ██║   ██║   ██║██████╔╝███████╗
   ██║   ██╔══██║██╔══╝      ██║     ██║   ██║██║     ██║     ██╔══╝  ██║        ██║   ██║   ██║██╔══██╗╚════██║
   ██║   ██║  ██║███████╗    ╚██████╗╚██████╔╝███████╗███████╗███████╗╚██████╗   ██║   ╚██████╔╝██║  ██║███████║
   ╚═╝   ╚═╝  ╚═╝╚══════╝     ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝

███╗   ██╗███████╗████████╗    ██╗   ██╗ █████╗ ██╗   ██╗██╗  ████████╗     █████╗ ███████╗███████╗███████╗████████╗███████╗
████╗  ██║██╔════╝╚══██╔══╝    ██║   ██║██╔══██╗██║   ██║██║  ╚══██╔══╝    ██╔══██╗██╔════╝██╔════╝██╔════╝╚══██╔══╝██╔════╝
██╔██╗ ██║█████╗     ██║       ██║   ██║███████║██║   ██║██║     ██║       ███████║███████╗███████╗█████╗     ██║   ███████╗
██║╚██╗██║██╔══╝     ██║       ╚██╗ ██╔╝██╔══██║██║   ██║██║     ██║       ██╔══██║╚════██║╚════██║██╔══╝     ██║   ╚════██║
██║ ╚████║██║        ██║        ╚████╔╝ ██║  ██║╚██████╔╝███████╗██║       ██║  ██║███████║███████║███████╗   ██║   ███████║
╚═╝  ╚═══╝╚═╝        ╚═╝         ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝       ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝   ╚═╝   ╚══════╝

███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗     ███████╗ █████╗  ██████╗███████╗████████╗
████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗    ██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝
██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝    █████╗  ███████║██║     █████╗     ██║
██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗    ██╔══╝  ██╔══██║██║     ██╔══╝     ██║
██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║    ██║     ██║  ██║╚██████╗███████╗   ██║
╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝   ╚═╝

*/

import "./TheCollectorsNFTVaultBaseFacet.sol";

/*
    @dev
    The facet that handling all assets logic and can be called only by @TheCollectorsNFTVaultDiamond
    This contract is part of a diamond / facets implementation as described
    in EIP 2535 (https://eips.ethereum.org/EIPS/eip-2535)
*/
contract TheCollectorsNFTVaultAssetsManagerFacet is TheCollectorsNFTVaultBaseFacet {
    using Counters for Counters.Counter;
    using Strings for uint256;

    constructor() ERC721("", "") {}

    // ==================== Asset sale, buy & list ====================

    /*
        @dev
        Migrating a group of people who bought together an NFT to a vault.
        It is under the sender responsibility to send the right details.
        This is the use case. Bob, Mary and Jim are friends and bought together a BAYC for 60 ETH. Jim and Mary
        sent 20 ETH each to Bob, Bob added another 20 ETH and bought the BAYC on a marketplace.
        Now, Bob is holding the BAYC in his private wallet and has the responsibility to make sure it stay safe.
        In order to migrate, first Bob (or Jim or Mary) will need to create a vault with the BAYC collection, 3
        participants and enter Bob's, Mary's and Jim's addresses. After that, ONLY Bob can migrate by sending the right
        properties.
        @vaultId the vault's id
        @tokenId the tokens id of the collection (e.g BAYC's id)
        @_participants list of participants (e.g with Bob's, Mary's and Jim's addresses [in that order])
        @payments how much each participant paid
    */
    function migrate(uint256 vaultId, uint256 tokenId, address[] memory _participants, uint256[] memory payments) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        // Must be immediately after creating vault
        require(_as.vaults[vaultId].votingFor == LibDiamond.VoteFor.WaitingToSetTokenInfo, "E1");
        address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
        uint256 totalPaid;
        for (uint256 i; i < participants.length; i++) {
            totalPaid += _as.vaultParticipants[vaultId][i].paid;
        }
        // No one paid yet
        require(totalPaid == 0, "E2");
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        vault.tokenId = tokenId;
        _as.vaultsExtensions[vaultId].isMigrated = true;
        totalPaid = 0;
        for (uint256 i; i < participants.length; i++) {
            // Making sure participants sent in the same order
            require(_as.vaultParticipants[vaultId][i].participant == _participants[i], "E3");
            _as.vaultParticipants[vaultId][i].paid = payments[i];
            if (_as.vaultsExtensions[vaultId].publicVault) {
                // Public vault
                require(payments[i] >= _as.vaultsExtensions[vaultId].minimumFunding, "E4");
            } else {
                require(payments[i] > 0, "E4");
            }
            totalPaid += payments[i];
        }
        if (!_as.vaultsExtensions[vaultId].isERC1155) {
            IERC721(vault.collection).safeTransferFrom(msg.sender, _as.assetsHolders[vaultId], tokenId);
        } else {
            IERC1155(vault.collection).safeTransferFrom(msg.sender, _as.assetsHolders[vaultId], tokenId, 1, "");
        }

        // totalPaid = purchasePrice
        _afterPurchaseNFT(vaultId, totalPaid, false);
        emit NFTMigrated(vault.id, vault.collection, vault.tokenId, totalPaid);
    }

    /*
        @dev
        List the NFT for sell, meaning anyone can call @buyNFTFromVault and buy the NFT
        This method is not supposed to be used and just a fallback in case marketplace listing is not working
    */
    function listNFTForSale(uint256 vaultId) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.vaults[vaultId].votingFor == LibDiamond.VoteFor.Selling, "E1");
        require(_as.vaults[vaultId].listFor > 0, "E2");
        require(isVaultPassedSellOrCancelSellOrderConsensus(vaultId), "E3");
        require(_isParticipantExists(vaultId, msg.sender), "E4");
        if (!_as.vaultsExtensions[vaultId].isERC1155) {
            require(IERC721(_as.vaults[vaultId].collection).ownerOf(_as.vaults[vaultId].tokenId) == _as.assetsHolders[vaultId], "E5");
        } else {
            // If it was == 1, then it was open to attacks
            require(IERC1155(_as.vaults[vaultId].collection).balanceOf(_as.assetsHolders[vaultId], _as.vaults[vaultId].tokenId) > 0, "E5");
        }
        _resetVotesAndGracePeriod(vaultId);
        _as.vaults[vaultId].votingFor = LibDiamond.VoteFor.CancellingSellOrder;
        emit NFTListedForSale(vaultId, _as.vaults[vaultId].collection, _as.vaults[vaultId].tokenId, _as.vaults[vaultId].listFor);
    }

    /*
        @dev
        Cancel the NFT listing without going through marketplace
        This method is not supposed to be used and just a fallback in case marketplace did not manage to accept
        the sell order
    */
    function cancelNFTForSale(uint256 vaultId) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.vaults[vaultId].votingFor == LibDiamond.VoteFor.CancellingSellOrder, "E1");
        require(_isParticipantExists(vaultId, msg.sender), "E2");
        require(isVaultPassedSellOrCancelSellOrderConsensus(vaultId), "E3");
        if (!_as.vaultsExtensions[vaultId].isERC1155) {
            require(IERC721(_as.vaults[vaultId].collection).ownerOf(_as.vaults[vaultId].tokenId) == _as.assetsHolders[vaultId], "E4");
        } else {
            // If it was == 1, then it was open to attacks
            require(IERC1155(_as.vaults[vaultId].collection).balanceOf(_as.assetsHolders[vaultId], _as.vaults[vaultId].tokenId) > 0, "E4");
        }
        _resetVotesAndGracePeriod(vaultId);
        _as.vaults[vaultId].votingFor = LibDiamond.VoteFor.Selling;
        emit NFTSellOrderCanceled(vaultId, _as.vaults[vaultId].collection, _as.vaults[vaultId].tokenId);
    }

    /*
        @dev
        A method to allow anyone to purchase the token from the vault in the required price and the
        seller won't pay any fees. It is basically an OTC buy deal.
        The buyer can call this method only if the NFT is already for sale.
        This method can also be used as a failsafe in case marketplace sale is failing.
        No need to cancel previous order since the vault will not be used again
    */
    function buyNFTFromVault(uint256 vaultId) external nonReentrant payable {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        // No marketplace and royalties fees
        vault.marketplaceAndRoyaltiesFees = 0;
        // Making sure vault already bought the token, the token is for sale and has a list price
        require(vault.votingFor == LibDiamond.VoteFor.CancellingSellOrder && vault.listFor > 0, "E1");
        // Making sure the vault is still the owner of the token
        if (_as.vaultsExtensions[vaultId].isERC1155) {
            // If it was == 1, then it was open to attacks
            require(IERC1155(vault.collection).balanceOf(_as.assetsHolders[vaultId], vault.tokenId) > 0, "E2");
        } else {
            require(IERC721(vault.collection).ownerOf(vault.tokenId) == _as.assetsHolders[vaultId], "E2");
        }
        // Sender sent enough ETH to purchase the NFT
        require(msg.value == vault.listFor, "E3");
        // Transferring the token to the new owner
        IAssetsHolderImpl(_as.assetsHolders[vaultId]).transferToken(
            _as.vaultsExtensions[vaultId].isERC1155, msg.sender, vault.collection, vault.tokenId
        );
        // Transferring the ETH to the asset holder which is in charge of distributing the profits
        Address.sendValue(_as.assetsHolders[vaultId], msg.value);
        emit NFTSold(vaultId, vault.collection, vault.tokenId, vault.listFor);
    }

    /*
        @dev
        A method to allow anyone to sell the token that the vault is about to purchase to the vault
        without going through a marketplace. It is basically an OTC sell deal.
        The seller can call this method only if the vault is in buying state and there is a buy consensus.
        The sale price will be the lower between the total paid amount and the vault maxPriceToBuy.
        The user is sending the sellPrice to prevent a frontrun attacks where a participant is withdrawing
        ETH just before the transaction to sell the NFT thus making the sellers to get less than what they
        were expecting to get. The sellPrice will be calculated in the FE by taking the minimum
        between the total paid and max price to buy
    */
    function sellNFTToVault(uint256 vaultId, uint256 sellPrice) external nonReentrant {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _requireBuyConsensusAndValidatePurchasePrice(vaultId, sellPrice);

        if (!_as.vaultsExtensions[vaultId].isERC1155) {
            require(IERC721(_as.vaults[vaultId].collection).ownerOf(_as.vaults[vaultId].tokenId) == msg.sender, "E4");
            IERC721(_as.vaults[vaultId].collection).safeTransferFrom(msg.sender, _as.assetsHolders[vaultId], _as.vaults[vaultId].tokenId);
        } else {
            require(IERC1155(_as.vaults[vaultId].collection).balanceOf(msg.sender, _as.vaults[vaultId].tokenId) > 0, "E4");
            IERC1155(_as.vaults[vaultId].collection).safeTransferFrom(msg.sender, _as.assetsHolders[vaultId], _as.vaults[vaultId].tokenId, 1, "");
        }

        IAssetsHolderImpl(_as.assetsHolders[vaultId]).sendValue(payable(msg.sender), sellPrice);

        _afterPurchaseNFT(vaultId, sellPrice, true);
    }

    // ==================== The Collectors ====================

    /*
        @dev
        Unstaking a Collector NFT from the vault. Can be done only be the original owner of the collector and only
        if the participant already staked a collector and the vault haven't bought the token yet
    */
    function unstakeCollector(uint256 vaultId, uint256 stakedCollectorTokenId) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _requireVotingForBuyingOrWaitingForSettingTokenInfo(vaultId);
        require(LibDiamond.THE_COLLECTORS.ownerOf(stakedCollectorTokenId) == _as.assetsHolders[vaultId], "E2");
        address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
        for (uint256 i; i < participants.length; i++) {
            if (_as.vaultParticipants[vaultId][i].participant == msg.sender) {
                require(_as.vaultParticipants[vaultId][i].collectorOwner == msg.sender, "E3");
                _as.vaultParticipants[vaultId][i].collectorOwner = address(0);
                _as.vaultParticipants[vaultId][i].stakedCollectorTokenId = 0;
                IAssetsHolderImpl(_as.assetsHolders[vaultId]).transferToken(false, msg.sender, address(LibDiamond.THE_COLLECTORS), stakedCollectorTokenId);
                emit CollectorUnstaked(vaultId, msg.sender, stakedCollectorTokenId);
                break;
            }
        }
    }

    /*
        @dev
        Staking a Collector NFT in the vault to avoid paying the protocol fee.
        A participate can stake a Collector for the lifecycle of the vault (buying and selling) in order to
        not pay the protocol fee when selling the token.
        The Collector NFT will return to the original owner when redeeming the partial NFT of the vault
    */
    function stakeCollector(uint256 vaultId, uint256 collectorTokenId) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _requireVotingForBuyingOrWaitingForSettingTokenInfo(vaultId);
        require(LibDiamond.THE_COLLECTORS.ownerOf(collectorTokenId) == msg.sender, "E2");
        LibDiamond.THE_COLLECTORS.safeTransferFrom(msg.sender, _as.assetsHolders[vaultId], collectorTokenId);
        address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
        for (uint256 i; i < participants.length; i++) {
            if (_as.vaultParticipants[vaultId][i].participant == msg.sender) {
                // Only participants who paid can be part of the decisions making
                // Can check paid > 0 and not ownership > 0 because this method can be used only before purchasing
                // Using paid > 0 will save gas
                // Also using @_getPercentage can return > 0 if no one paid
                require(_as.vaultParticipants[vaultId][i].paid > 0, "E3");
                // Can only stake 1 collector
                require(_as.vaultParticipants[vaultId][i].collectorOwner == address(0), "E4");
                // Saving a reference for the original collector owner because a participate can sell his seat
                _as.vaultParticipants[vaultId][i].collectorOwner = msg.sender;
                _as.vaultParticipants[vaultId][i].stakedCollectorTokenId = collectorTokenId;
                emit CollectorStaked(vaultId, msg.sender, collectorTokenId);
                break;
            }
        }
    }

}
