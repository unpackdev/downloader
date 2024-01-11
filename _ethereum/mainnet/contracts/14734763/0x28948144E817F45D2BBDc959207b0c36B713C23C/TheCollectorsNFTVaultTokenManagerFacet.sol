// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*

████████╗██╗  ██╗███████╗     ██████╗ ██████╗ ██╗     ██╗     ███████╗ ██████╗████████╗ ██████╗ ██████╗ ███████╗
╚══██╔══╝██║  ██║██╔════╝    ██╔════╝██╔═══██╗██║     ██║     ██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██╔════╝
   ██║   ███████║█████╗      ██║     ██║   ██║██║     ██║     █████╗  ██║        ██║   ██║   ██║██████╔╝███████╗
   ██║   ██╔══██║██╔══╝      ██║     ██║   ██║██║     ██║     ██╔══╝  ██║        ██║   ██║   ██║██╔══██╗╚════██║
   ██║   ██║  ██║███████╗    ╚██████╗╚██████╔╝███████╗███████╗███████╗╚██████╗   ██║   ╚██████╔╝██║  ██║███████║
   ╚═╝   ╚═╝  ╚═╝╚══════╝     ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝

███╗   ██╗███████╗████████╗    ██╗   ██╗ █████╗ ██╗   ██╗██╗  ████████╗
████╗  ██║██╔════╝╚══██╔══╝    ██║   ██║██╔══██╗██║   ██║██║  ╚══██╔══╝
██╔██╗ ██║█████╗     ██║       ██║   ██║███████║██║   ██║██║     ██║
██║╚██╗██║██╔══╝     ██║       ╚██╗ ██╔╝██╔══██║██║   ██║██║     ██║
██║ ╚████║██║        ██║        ╚████╔╝ ██║  ██║╚██████╔╝███████╗██║
╚═╝  ╚═══╝╚═╝        ╚═╝         ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝

████████╗ ██████╗ ██╗  ██╗███████╗███╗   ██╗    ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗
╚══██╔══╝██╔═══██╗██║ ██╔╝██╔════╝████╗  ██║    ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗
   ██║   ██║   ██║█████╔╝ █████╗  ██╔██╗ ██║    ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝
   ██║   ██║   ██║██╔═██╗ ██╔══╝  ██║╚██╗██║    ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗
   ██║   ╚██████╔╝██║  ██╗███████╗██║ ╚████║    ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║
   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝

███████╗ █████╗  ██████╗███████╗████████╗
██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝
█████╗  ███████║██║     █████╗     ██║
██╔══╝  ██╔══██║██║     ██╔══╝     ██║
██║     ██║  ██║╚██████╗███████╗   ██║
╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝   ╚═╝

*/

import "./TheCollectorsNFTVaultBaseFacet.sol";

/*
    @dev
    The facet that handling all NFT vault token logic and can be called only by @TheCollectorsNFTVaultDiamond
    This contract is part of a diamond / facets implementation as described
    in EIP 2535 (https://eips.ethereum.org/EIPS/eip-2535)
*/
contract TheCollectorsNFTVaultTokenManagerFacet is TheCollectorsNFTVaultBaseFacet, INFTTokenTransferHandler, IERC2981 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    constructor() ERC721("", "") {}

    // =========== EIP2981 ===========

    function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return (_as.royaltiesRecipient, (_salePrice * _as.royaltiesBasisPoints) / LibDiamond.PERCENTAGE_DENOMINATOR);
    }

    // ==================== Royalties management ====================

    /*
        @dev
        The wallet to receive royalties base on EIP 2981
    */
    function setRoyaltiesRecipient(address _royaltiesRecipient) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.royaltiesRecipient = _royaltiesRecipient;
    }

    /*
        @dev
        The wallet to receive royalties base on EIP 2981
    */
    function setRoyaltiesBasisPoints(uint256 _royaltiesBasisPoints) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.royaltiesBasisPoints = _royaltiesBasisPoints;
    }

    // ==================== Token management ====================

    /*
        @dev
        Claiming the partial vault NFT that represents the participate share of the original token the vault bought.
        Additionally, sending back any leftovers the participate is eligible to get in case the purchase amount
        was lower than the total amount that the vault was funded for
    */
    function claimVaultTokenAndGetLeftovers(uint256 vaultId) external nonReentrant {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.vaults[vaultId].votingFor == LibDiamond.VoteFor.Selling || _as.vaults[vaultId].votingFor == LibDiamond.VoteFor.CancellingSellOrder, "E1");
        address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
        for (uint256 i; i < participants.length; i++) {
            if (_as.vaultParticipants[vaultId][i].participant == msg.sender) {
                // Only if participate doesn't already have a partial NFT
                require(_as.vaultParticipants[vaultId][i].partialNFTVaultTokenId == 0, "E2");
                // Only participants who has ownership can claim vault token
                // Can check ownership > 0 and not call @_getPercentage because this method can be
                // called only after purchasing
                // Using ownership > 0 will save gas
                require(_as.vaultParticipants[vaultId][i].ownership > 0, "E3");
                _as.vaultParticipants[vaultId][i].partialNFTVaultTokenId = _as.tokenIdTracker.current();
                _as.vaultTokens[_as.tokenIdTracker.current()] = vaultId;
                _mint(msg.sender, _as.tokenIdTracker.current());
                if (_as.vaultParticipants[vaultId][i].leftovers > 0) {
                    // No need to update the participant object before because we use nonReentrant
                    // By not using another variable the contract size is smaller
                    IAssetsHolderImpl(_as.assetsHolders[vaultId]).sendValue(payable(_as.vaultParticipants[vaultId][i].participant), _as.vaultParticipants[vaultId][i].leftovers);
                    _as.vaultParticipants[vaultId][i].leftovers = 0;
                }
                emit VaultTokenClaimed(vaultId, msg.sender, _as.tokenIdTracker.current());
                _as.tokenIdTracker.increment();
                // Not having a break here as one address can hold multiple seats
            }
        }
    }

    /*
        @dev
        Burning the partial vault NFT in order to get the proceeds from the NFT sale.
        Additionally, sending back the staked Collector to the original owner in case a collector was staked.
        Sending the protocol fee in case the participate did not stake a Collector
    */
    function redeemToken(uint256 tokenId) external nonReentrant {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        // Making sure the sender is the owner of the token
        // No need to send it to the vault (avoiding an approve request)
        // Cannot call twice to this function because after first redeem the owner of tokenId is address(0)
        require(ownerOf(tokenId) == msg.sender, "E1");
        uint256 vaultId = _as.vaultTokens[tokenId];
        // Making sure the asset holder is not the owner of the token to know that it was sold
        require(isVaultSoldNFT(vaultId), "E2");
        address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
        for (uint256 i; i < participants.length; i++) {
            if (_as.vaultParticipants[vaultId][i].partialNFTVaultTokenId == tokenId) {
                _burn(tokenId);
                uint256 percentage = _getPercentage(vaultId, 0, tokenId);
                // The actual ETH the vault got from the sale deducting marketplace fees and collection royalties
                uint256 salePriceDeductingFees = _as.vaults[vaultId].listFor * (LibDiamond.PERCENTAGE_DENOMINATOR - _as.vaults[vaultId].marketplaceAndRoyaltiesFees) / (LibDiamond.PERCENTAGE_DENOMINATOR * 100);
                // The participate share from the proceeds
                uint256 profits = salePriceDeductingFees * percentage / 1e18;
                // Protocol fee, will be zero if a Collector was staked
                uint256 stakingFee = _as.vaultParticipants[vaultId][i].collectorOwner != address(0) ? 0 : profits * LibDiamond.STAKING_FEE / LibDiamond.PERCENTAGE_DENOMINATOR;
                // Liquidity fee, will be zero if a Collector was staked
                uint256 liquidityFee = _as.vaultParticipants[vaultId][i].collectorOwner != address(0) ? 0 : profits * LibDiamond.LIQUIDITY_FEE / LibDiamond.PERCENTAGE_DENOMINATOR;
                // Sending proceeds
                IAssetsHolderImpl(_as.assetsHolders[vaultId]).sendValue(
                    payable(_as.vaultParticipants[vaultId][i].participant),
                    profits - stakingFee - liquidityFee
                );
                if (stakingFee > 0) {
                    IAssetsHolderImpl(_as.assetsHolders[vaultId]).sendValue(payable(_as.stakingWallet), stakingFee);
                }
                if (liquidityFee > 0) {
                    IAssetsHolderImpl(_as.assetsHolders[vaultId]).sendValue(payable(_as.liquidityWallet), liquidityFee);
                }
                if (_as.vaultParticipants[vaultId][i].collectorOwner != address(0)) {
                    // In case the partial NFT was sold to someone else, the original collector owner still
                    // going to get their token back
                    IAssetsHolderImpl(
                        _as.assetsHolders[vaultId]).transferToken(false, _as.vaultParticipants[vaultId][i].collectorOwner,
                        address(LibDiamond.THE_COLLECTORS), _as.vaultParticipants[vaultId][i].stakedCollectorTokenId
                    );
                }
                emit VaultTokenRedeemed(vaultId, _as.vaultParticipants[vaultId][i].participant, tokenId);
                // In previous version the participant was removed from the vault but after
                // adding the executeTransaction functionality it was decided to keep the participant in case
                // the vault will need to execute a transaction after selling the NFT
                // i.e a previous owner of an NFT collection is eligible for whitelisting in new collection

                // Removing partial NFT from storage
                delete _as.vaultTokens[tokenId];
                // Keeping the break here although participants can hold more than 1 seat if they would buy the
                // vault NFT after the vault bought the original NFT
                // If needed, the participant can just call this method again
                break;
            }
        }
    }

    /*
        @dev
        Overriding transfer as the partial NFT can be sold or transfer to another address
        In case that happens, the new owner is becomes a participate in the vault
        This is the reason why @vote method does not have a break inside the for loop
    */
    function transferNFTVaultToken(
        address from,
        address to,
        uint256 tokenId
    ) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        // Checking the proxy registry is the sender, if it is than this is an opensea sale of the vault token
        if (msg.sender == LibDiamond.OPENSEA_PROXY_REGISTRY.proxies(from)) {
            // Buyer / Seller protection
            // In order to make sure no side is getting rekt, a token of a sold vault cannot be traded
            // but just redeemed so there won't be a situation where a token that only worth 10 ETH
            // is sold for more, or the other way around
            require(!isVaultSoldNFT(_as.vaultTokens[tokenId]), "Cannot sell, only redeem");
        }
        super._transfer(from, to, tokenId);
        if (from != address(0) && to != address(0)) {
            uint256 vaultId = _as.vaultTokens[tokenId];
            address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
            for (uint256 i; i < participants.length; i++) {
                if (_as.vaultParticipants[vaultId][i].partialNFTVaultTokenId == tokenId) {
                    // Replacing owner
                    // Leftovers will be 0 because when claiming vault NFT the contract sends back the leftovers
                    _as.vaultParticipants[vaultId][i].participant = to;
                    // Resetting votes
                    _as.vaultParticipants[vaultId][i].vote = false;
                    _as.vaultParticipants[vaultId][i].voted = false;
                    break;
                }
            }
        }
    }

    // ==================== views ====================

    function royaltiesRecipient() external view returns (address) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.royaltiesRecipient;
    }

    function royaltiesBasisPoints() external view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.royaltiesBasisPoints;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isNFTApprovedForAll(address owner, address operator) external view returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (LibDiamond.OPENSEA_PROXY_REGISTRY.proxies(owner) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

}
