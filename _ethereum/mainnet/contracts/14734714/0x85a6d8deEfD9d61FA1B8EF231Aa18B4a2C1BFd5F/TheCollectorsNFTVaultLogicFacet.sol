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

██╗      ██████╗  ██████╗ ██╗ ██████╗    ███████╗ █████╗  ██████╗███████╗████████╗
██║     ██╔═══██╗██╔════╝ ██║██╔════╝    ██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝
██║     ██║   ██║██║  ███╗██║██║         █████╗  ███████║██║     █████╗     ██║
██║     ██║   ██║██║   ██║██║██║         ██╔══╝  ██╔══██║██║     ██╔══╝     ██║
███████╗╚██████╔╝╚██████╔╝██║╚██████╗    ██║     ██║  ██║╚██████╗███████╗   ██║
╚══════╝ ╚═════╝  ╚═════╝ ╚═╝ ╚═════╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝   ╚═╝

*/

import "./TheCollectorsNFTVaultBaseFacet.sol";

/*
    @dev
    The facet that handling all vaults logic and can be called only by @TheCollectorsNFTVaultDiamond
    This contract is part of a diamond / facets implementation as described
    in EIP 2535 (https://eips.ethereum.org/EIPS/eip-2535)
*/
contract TheCollectorsNFTVaultLogicFacet is TheCollectorsNFTVaultBaseFacet {
    using Counters for Counters.Counter;
    using Strings for uint256;

    constructor() ERC721("", "") {}

    // ==================== Protocol management ====================

    /*
        @dev
        Is used to fetch the JSON file of the vault token
    */
    function setBaseTokenURI(string memory __baseTokenURI) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.baseTokenURI = __baseTokenURI;
    }

    /*
        @dev
        The wallet to hold ETH for liquidity
    */
    function setLiquidityWallet(address _liquidityWallet) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.liquidityWallet = _liquidityWallet;
    }

    /*
        @dev
        The wallet to hold ETH for staking
    */
    function setStakingWallet(address _stakingWallet) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.stakingWallet = _stakingWallet;
    }

    // ==================== Vault management ====================

    /*
        @dev
        Creates a new vault, can be called by anyone.
        The msg.sender doesn't have to be part of the vault.
    */
    function createVault(
        string memory vaultName,
        address collection,
        uint256 sellOrCancelSellOrderConsensus,
        uint256 buyConsensus,
        uint256 gracePeriodForSellingOrCancellingSellOrder,
        address[] memory _participants,
        bool privateVault,
        uint256 maxParticipants,
        uint256 minimumFunding
    ) external {
        // At least one participant
        require(_participants.length > 0 && _participants.length <= maxParticipants, "E1");
        require(bytes(vaultName).length > 0, "E2");
        require(collection != address(0), "E3");
        require(sellOrCancelSellOrderConsensus >= 51 ether && sellOrCancelSellOrderConsensus <= 100 ether, "E4");
        require(buyConsensus >= 51 ether && buyConsensus <= 100 ether, "E5");
        // Min 7 days, max 6 months
        // The amount of time to wait before undecided votes for selling/canceling sell order are considered as yes
        require(gracePeriodForSellingOrCancellingSellOrder >= 7 * 24 * 60 * 60
            && gracePeriodForSellingOrCancellingSellOrder <= 6 * 30 * 24 * 60 * 60, "E6");
        // Private vaults don't need to have a minimumFunding
        require(privateVault || minimumFunding > 0, "E7");
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        emit VaultCreated(_as.vaultIdTracker.current(), collection, privateVault);
        for (uint256 i; i < _participants.length; i++) {
            _as.vaultParticipants[_as.vaultIdTracker.current()][i] = LibDiamond.Participant(_participants[i], 0, 0, false, address(0), 0, 0, false, 0);
            // Not going to check if the participant already exists (avoid duplicated) when creating a vault,
            // because it is the creator responsibility and does not have any bad affect over the vault
            emit ParticipantJoinedVault(_as.vaultIdTracker.current(), _participants[i]);
        }
        _as.vaults[_as.vaultIdTracker.current()] = LibDiamond.Vault(_as.vaultIdTracker.current(), vaultName, collection, 0, LibDiamond.VoteFor.WaitingToSetTokenInfo, 0, 0,
            sellOrCancelSellOrderConsensus, 0, buyConsensus, gracePeriodForSellingOrCancellingSellOrder, 0, maxParticipants);
        _as.vaultsExtensions[_as.vaultIdTracker.current()] = LibDiamond.VaultExtension(
            !privateVault, privateVault ? 0 : minimumFunding, 0, !IERC165(collection).supportsInterface(type(IERC721).interfaceId), false
        );
        Address.functionDelegateCall(
            _as.nftVaultAssetsHolderCreator,
            abi.encodeWithSelector(IAssetsHolderCreator.createNFTVaultAssetsHolder.selector, _as.vaultIdTracker.current())
        );
        _as.vaultParticipantsAddresses[_as.vaultIdTracker.current()] = _participants;
        _as.vaultIdTracker.increment();
    }

    /*
        @dev
        Allow people to join a public vault but only if it hasn't bought the NFT yet
        The person who wants to join needs to send more than the minimum amount of ETH to join the vault
    */
    function joinPublicVault(uint256 vaultId) external payable {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        // NFT wasn't bought yet
        _requireVotingForBuyingOrWaitingForSettingTokenInfo(vaultId);
        // Vault exists and it is public
        require(_as.vaultsExtensions[vaultId].publicVault, "E2");
        // There is room
        require(_as.vaultParticipantsAddresses[vaultId].length < _as.vaults[vaultId].maxParticipants, "E3");
        // The sender is a not a participant of the vault yet
        require(!_isParticipantExists(vaultId, msg.sender), "E4");
        // The sender sent enough ETH
        require(msg.value >= _as.vaultsExtensions[vaultId].minimumFunding, "E5");
        address[] storage participants = _as.vaultParticipantsAddresses[vaultId];
        participants.push(msg.sender);
        _as.vaultParticipants[vaultId][participants.length - 1] = LibDiamond.Participant(msg.sender, 0, 0, false, address(0), 0, 0, false, 0);
        emit ParticipantJoinedVault(vaultId, msg.sender);
        fundVault(vaultId);
    }

    /*
        @dev
        Adding a person to a private vault by another participant of the vault
    */
    function addParticipant(uint256 vaultId, address participant) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        // NFT wasn't bought yet
        _requireVotingForBuyingOrWaitingForSettingTokenInfo(vaultId);
        // Private vault
        require(!_as.vaultsExtensions[vaultId].publicVault, "E2");
        // There is room
        require(_as.vaultParticipantsAddresses[vaultId].length < _as.vaults[vaultId].maxParticipants, "E3");
        // The sender is a participant of the vault
        require(_isParticipantExists(vaultId, msg.sender), "E4");
        require(!_isParticipantExists(vaultId, participant), "E5");
        address[] storage participants = _as.vaultParticipantsAddresses[vaultId];
        for (uint256 i; i < participants.length; i++) {
            if (_as.vaultParticipants[vaultId][i].participant == msg.sender) {
                // Only participant that paid can add others to a private vault
                // Can check paid > 0 and not ownership > 0 because this method can be used only before purchasing
                // Using paid > 0 will save gas
                // Also using @_getPercentage can return > 0 if no one paid
                require(_as.vaultParticipants[vaultId][i].paid > 0, "E6");
                break;
            }
        }
        participants.push(participant);
        _as.vaultParticipants[vaultId][participants.length - 1] = LibDiamond.Participant(participant, 0, 0, false, address(0), 0, 0, false, 0);
        emit ParticipantJoinedVault(vaultId, participant);
    }

    /*
        @dev
        Setting the token id to purchase and max buying price. After setting token info,
        participants can vote for or against buying it.
        In case the vault is private, the vault's collection can also be changed. The reasoning behind it is that
        a private vault's participants know each other so less likely to be surprised if the collection has changed.
        Participants can call this method again in order to change the token info and max buying price. Everytime
        this function is called all the votes are reset and the voting starts again.
        In case the % of ownership for buying is higher than the buying consensus (DAO decided to buy),
        only a participant who voted yes can change the token info and max buying price and reset the process.
        The logic behind that is that the vault consist of people who know each other so less likely to be
        attacked by two participants who need to work together. In any case, the participants can always withdraw
        their ETH as long as the vault didn't buy the NFT and just open a new vault without the bad actors.
    */
    function setTokenInfoAndMaxBuyPrice(uint256 vaultId, address collection, uint256 tokenId, uint256 maxBuyPrice) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        // Can call this method only if haven't set a token before or already set but haven't bought the token yet
        _requireVotingForBuyingOrWaitingForSettingTokenInfo(vaultId);
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        /*
            @dev
            Checking if vaults[vaultId].votingFor == VoteFor.WaitingToSetTokenInfo because tokenId-to-buy can be 0
            Only private vaults can change collections
        */
        if (!_as.vaultsExtensions[vaultId].publicVault) {
            require(collection != address(0), "E2");
            if (vault.collection != collection) {
                // Re setting the isERC1155 property because there is a new collection
                _as.vaultsExtensions[vaultId].isERC1155 = !IERC165(collection).supportsInterface(type(IERC721).interfaceId);
            }
            vault.collection = collection;
        }
        vault.tokenId = tokenId;
        vault.votingFor = LibDiamond.VoteFor.Buying;
        _as.vaultsExtensions[vaultId].maxPriceToBuy = maxBuyPrice;
        address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
        bool isParticipant;
        bool participantVoteYes;
        uint256 votesPercentage;
        for (uint256 i; i < participants.length; i++) {
            votesPercentage += _as.vaultParticipants[vaultId][i].vote ? _getPercentage(vaultId, i, 0) : 0;
            if (_as.vaultParticipants[vaultId][i].participant == msg.sender) {
                // Only participants who paid can be part of the decisions making
                // Can check paid > 0 and not ownership > 0 because this method can be used only before purchasing
                // Using paid > 0 will save gas
                // Also using @_getPercentage can return > 0 if no one paid
                require(_as.vaultParticipants[vaultId][i].paid > 0, "E3");
                isParticipant = true;
                participantVoteYes = _as.vaultParticipants[vaultId][i].vote;
                emit NFTTokenWasSet(vault.id, vault.collection, tokenId, maxBuyPrice);
                _vote(vaultId, _as.vaultParticipants[vaultId][i], true, vault.votingFor);
            } else {
                // Resetting the vote so a previous vote won't be considers for the new token id
                _as.vaultParticipants[vaultId][i].vote = false;
                _as.vaultParticipants[vaultId][i].voted = false;
            }
        }
        require(isParticipant, "E4");
        // As written in the method documentation, even if the votesPercentage is higher than the buy consensus
        // a participant who voted yes can still reset the process
        require(votesPercentage < vault.buyConsensus || participantVoteYes, "E5");
    }

    /*
        @dev
        Setting a listing price for the NFT sell order.
        Later, participants can vote for or against selling it at this price.
        Participants can call this method again in order to change the listing price.
        In case the % of ownership for selling is higher than selling consensus (DAO decided to sell),
        only a participant who voted yes can change the listing price and reset the process.
    */
    function setListingPrice(uint256 vaultId, uint256 listFor) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        require(vault.votingFor == LibDiamond.VoteFor.Selling, "E1");
        vault.listFor = listFor;
        bool isVaultPassedConsensus = isVaultPassedSellOrCancelSellOrderConsensus(vaultId);
        address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
        bool isParticipant;
        bool participantVoteYes;
        for (uint256 i; i < participants.length; i++) {
            if (_as.vaultParticipants[vaultId][i].participant == msg.sender) {
                // Only participants who has ownership can be part of the decision making
                // Can check ownership > 0 and not call @_getPercentage because this method can be
                // called only after purchasing
                // Using ownership > 0 will save gas
                require(_as.vaultParticipants[vaultId][i].ownership > 0, "E2");
                participantVoteYes = _getParticipantSellOrCancelSellOrderVote(vaultId, i);
                isParticipant = true;
                _resetVotesAndGracePeriod(vaultId);
                emit ListingPriceWasSet(vault.id, vault.collection, vault.tokenId, listFor);
                _vote(vaultId, _as.vaultParticipants[vaultId][i], true, vault.votingFor);
                break;
            }
        }
        require(isParticipant, "E3");
        // As written in the method documentation, even if the votesPercentage is higher than the sell consensus
        // a participant who voted yes can still reset the process
        require(!isVaultPassedConsensus || participantVoteYes, "E4");
    }

    /*
        @dev
        Voting for either buy the token, listing it for sale or cancel the sell order
    */
    function vote(uint256 vaultId, bool yes) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.vaults[vaultId].votingFor != LibDiamond.VoteFor.WaitingToSetTokenInfo, "E1");
        address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
        bool isParticipant;
        for (uint256 i; i < participants.length; i++) {
            if (_as.vaultParticipants[vaultId][i].participant == msg.sender) {
                isParticipant = true;
                // Only participants with ownership can be part of the decision making
                // Calling @_getPercentage because this method can be called before and after purchasing
                if (_getPercentage(vaultId, i, 0) > 0) {
                    _vote(vaultId, _as.vaultParticipants[vaultId][i], yes, _as.vaults[vaultId].votingFor);
                }
                /*
                    @dev
                    Not using a break here since participants can hold more than 1 seat if they bought the vault NFT
                    from the other participants after the vault bought the original NFT.
                    If we would have a break here, the vault could get to a limbo state where it
                    would not able to pass the consensus to sell the NFT and it would be stuck forever
                */
            }
        }
        require(isParticipant, "E3");
    }

    /*
        @dev
        Sending ETH to vault. The funds that will not be used for purchasing the
        NFT will be returned to the participate when calling the @claimVaultTokenAndGetLeftovers method
    */
    function fundVault(uint256 vaultId) public payable {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        // Can only fund the vault if the token was not purchased yet
        _requireVotingForBuyingOrWaitingForSettingTokenInfo(vaultId);
        address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
        bool isParticipant;
        for (uint256 i; i < participants.length; i++) {
            if (_as.vaultParticipants[vaultId][i].participant == msg.sender) {
                isParticipant = true;
                _as.vaultParticipants[vaultId][i].paid += msg.value;
                if (_as.vaultsExtensions[vaultId].publicVault) {
                    require(_as.vaultParticipants[vaultId][i].paid >= _as.vaultsExtensions[vaultId].minimumFunding, "E2");
                }
                // The asset holder is the contract that is holding the ETH and tokens
                Address.sendValue(_as.assetsHolders[vaultId], msg.value);
                emit VaultWasFunded(vaultId, msg.sender, msg.value);
                break;
            }
        }
        // Keeping this here, just for a situation where someone sends ETH using this function
        // and he is not a participant of the vault
        require(isParticipant, "E3");
    }

    /*
        @dev
        Withdrawing ETH from the vault, can only be called before purchasing the NFT.
        In case of a public vault, if the withdrawing make the participant to fund the vault less than the
        minimum amount, the participant will be removed from the vault and all of their investment will be returned
    */
    function withdrawFunds(uint256 vaultId, uint256 amount) external nonReentrant {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _requireVotingForBuyingOrWaitingForSettingTokenInfo(vaultId);
        address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
        for (uint256 i; i < participants.length; i++) {
            if (_as.vaultParticipants[vaultId][i].participant == msg.sender) {
                require(amount <= _as.vaultParticipants[vaultId][i].paid, "E2");
                if (_as.vaultsExtensions[vaultId].publicVault && (_as.vaultParticipants[vaultId][i].paid - amount) < _as.vaultsExtensions[vaultId].minimumFunding) {
                    // This is a public vault and there is minimum funding
                    // The participant is asking to withdraw amount that will cause their total funding
                    // to be less than the minimum amount. Returning all funds and removing from vault
                    amount = _as.vaultParticipants[vaultId][i].paid;
                }
                _as.vaultParticipants[vaultId][i].paid -= amount;
                IAssetsHolderImpl(_as.assetsHolders[vaultId]).sendValue(payable(_as.vaultParticipants[vaultId][i].participant), amount);
                if (_as.vaultParticipants[vaultId][i].paid == 0 && _as.vaultsExtensions[vaultId].publicVault) {
                    // Removing participant from public vault
                    _removeParticipant(vaultId, i);
                }
                emit FundsWithdrawn(vaultId, msg.sender, amount);
                break;
            }
        }
    }

    // ==================== views ====================

    function assetsHolders(uint256 vaultId) external view returns (address) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.assetsHolders[vaultId];
    }

    function vaults(uint256 vaultId) external view returns (LibDiamond.Vault memory) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.vaults[vaultId];
    }

    function vaultTokens(uint256 vaultId) external view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.vaultTokens[vaultId];
    }

    function vaultsExtensions(uint256 vaultId) external view returns (LibDiamond.VaultExtension memory) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.vaultsExtensions[vaultId];
    }

    function liquidityWallet() external view returns (address) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.liquidityWallet;
    }

    function stakingWallet() external view returns (address) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.stakingWallet;
    }

    function getVaultParticipants(uint256 vaultId) external view returns (LibDiamond.Participant[] memory) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Participant[] memory participants = new LibDiamond.Participant[](_as.vaultParticipantsAddresses[vaultId].length);
        for (uint256 i; i < participants.length; i++) {
            participants[i] = _as.vaultParticipants[vaultId][i];
        }
        return participants;
    }

    function getParticipantPercentage(uint256 vaultId, uint256 participantIndex) external view returns (uint256) {
        return _getPercentage(vaultId, participantIndex, 0);
    }

    function getTokenPercentage(uint256 tokenId) external view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _getPercentage(_as.vaultTokens[tokenId], 0, tokenId);
    }

    // ==================== Internals ====================

    /*
        @dev
        A helper function to remove element from array and reduce array size
    */
    function _removeParticipant(uint256 vaultId, uint256 index) internal {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        address[] storage participants = _as.vaultParticipantsAddresses[vaultId];
        _as.vaultParticipants[vaultId][index] = _as.vaultParticipants[vaultId][participants.length - 1];
        delete _as.vaultParticipants[vaultId][participants.length - 1];
        participants[index] = participants[participants.length - 1];
        participants.pop();
    }

    /*
        @dev
        Internal vote method to update participant vote, reset grace period if needed and emit an event
    */
    function _vote(uint256 vaultId, LibDiamond.Participant storage participant, bool yes, LibDiamond.VoteFor voteFor) internal {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        participant.vote = yes;
        if (voteFor == LibDiamond.VoteFor.Buying) {
            emit VotedForBuy(vaultId, participant.participant, yes, _as.vaults[vaultId].collection, _as.vaults[vaultId].tokenId);
        } else {
            // Resetting the grace period but only if this is the first vote
            // First time setting a listing price, voting to cancel a sell order or voting on a listing price
            // after the sell order was cancelled, the grace period will be reset
            bool firstProposalVote = true;
            address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
            for (uint256 i; i < participants.length; i++) {
                if (_as.vaultParticipants[vaultId][i].voted) {
                    firstProposalVote = false;
                    break;
                }
            }
            if (firstProposalVote) {
                // Resetting the end of grace period, after that date all undecided (un-voted) votes are considered as yes
                _as.vaults[vaultId].endGracePeriodForSellingOrCancellingSellOrder = block.timestamp + _as.vaults[vaultId].gracePeriodForSellingOrCancellingSellOrder;
            }
            if (voteFor == LibDiamond.VoteFor.Selling) {
                emit VotedForSell(vaultId, participant.participant, yes, _as.vaults[vaultId].collection, _as.vaults[vaultId].tokenId, _as.vaults[vaultId].listFor);
            } else if (voteFor == LibDiamond.VoteFor.CancellingSellOrder) {
                emit VotedForCancel(vaultId, participant.participant, yes, _as.vaults[vaultId].collection, _as.vaults[vaultId].tokenId, _as.vaults[vaultId].listFor);
            }
        }
        participant.voted = true;
    }

    // =========== Salvage ===========

    /*
        @dev
        Sends stuck ERC721 tokens to the owner.
        This is just in case someone sends in mistake tokens to this contract.
        Reminder, the asset holder contract is the one that holds the ETH and tokens
    */
    function salvageERC721Token(address collection, uint256 tokenId) external onlyOwner {
        IERC721(collection).safeTransferFrom(address(this), owner(), tokenId);
    }

    /*
        @dev
        Sends stuck ETH to the owner.
        This is just in case someone sends in mistake ETH to this contract.
        Reminder, the asset holder contract is the one that holds the ETH and tokens
    */
    function salvageETH() external onlyOwner {
        if (address(this).balance > 0) {
            Address.sendValue(payable(owner()), address(this).balance);
        }
    }

}
