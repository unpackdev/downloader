// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./TheCollectorsNFTVaultBaseFacet.sol";
import "./TheCollectorsNFTVaultOpenseaAssetsHolderProxy.sol";

/*
    @dev
    This facet includes the following fixes, updates, improvements, etc:

    1. Preventing private sale when listing NFT for sale in order to combat the attack vector of owning more shares
    than the list consensus and then list it for 0 ETH and sell it to yourself
    2. Adding the method withdraw NFT to owner only if owner holds 100% of the shares
    3. The following diamond cuts have been applied (in a different transaction):
    Removing TheCollectorsNFTVaultAssetsManagerFacet.listNFTForSale.selector;
    // Disabled for now do to the fact someone can have an ownership that is higher than the sell consensus
    // and list it for 0 and just buy it.
    // We do have a # of blocks delay between list and buy to make this attack dangerous for the attacker
    // but until this platform becomes more popular there won't be any MEV to listen to this method call
    Removing TheCollectorsNFTVaultAssetsManagerFacet.cancelNFTForSale.selector;
    // Disabled for now, as someone can cancel the sale from the contract but not from opensea and then
    // the NFT will still be for sale on opensea. We will address this functionality in the future
    4. When withdrawing eth from public vault and getting removed from the vault,
    send stacked collector back to the user
    5. Add a number of blocks delay between listing and selling to make the attack of one participant holding more
    than the cell consensus and listing the NFT for 0 price and buying it immediately very dangerous
    6. Changing minimum grace period to 30 days
*/
contract TheCollectorsNFTVaultUpdatesV1Facet is TheCollectorsNFTVaultBaseFacet {
    using Counters for Counters.Counter;
    using Strings for uint256;

    constructor() ERC721("", "") {}

    /*
        @dev
        Approving the sale order in Opensea exchange.
        Please be aware that a client will still need to call opensea API to show the listing on opensea website.
        Need to check if msg.sender is a participant since after grace period is over, all undecided votes
        are considered as yes which might make the sell consensus pass
    */
    function listNFTOnOpensea(
        uint256 vaultId,
        address[7] memory addrs,
        uint[9] memory uints,
        uint8 feeMethod,
        uint8 side,
        uint8 saleKind,
        uint8 howToCall,
        bytes memory _calldata,
        bytes memory replacementPattern,
        bytes memory staticExtradata
    ) external {

        _beforeListingNFTOnOpensea(vaultId, uints, _calldata, addrs[2], addrs[5], staticExtradata);

        TheCollectorsNFTVaultOpenseaAssetsHolderImpl(LibDiamond.appStorage().assetsHolders[vaultId]).listNFTOnOpensea(
            LibDiamond.appStorage().vaults[vaultId].collection,
            addrs,
            uints,
            feeMethod,
            side,
            saleKind,
            howToCall,
            _calldata,
            replacementPattern,
            staticExtradata
        );

        // The only way for this to fail is if Opensea has a bug in their contract
        require(
            LibDiamond.OPENSEA_EXCHANGE.validateOrder_(
                addrs,
                uints,
                feeMethod,
                side,
                saleKind,
                howToCall,
                _calldata,
                replacementPattern,
                staticExtradata,
                0,
                0x0000000000000000000000000000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000000000000000000000000000
            ), "E7"
        );

        _resetVotesAndGracePeriod(vaultId);

        LibDiamond.appStorage().vaults[vaultId].votingFor = LibDiamond.VoteFor.CancellingSellOrder;
        LibDiamond.appStorage().vaultsExtensions[vaultId].listingBlockNumber = block.number;

        emit NFTListedForSale(LibDiamond.appStorage().vaults[vaultId].id, LibDiamond.appStorage().vaults[vaultId].collection, LibDiamond.appStorage().vaults[vaultId].tokenId, LibDiamond.appStorage().vaults[vaultId].listFor);
    }

    /*
    @dev
        A helper function to validate whatever the vault is ready to list the token for sale
    */
    function _beforeListingNFTOnOpensea(uint256 vaultId, uint256[9] memory uints, bytes memory _calldata, address taker,
        address staticTarget, bytes memory staticCalldata) internal {

        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        // No private sales
        require(taker == address(0), "E0");
        require(vault.votingFor == LibDiamond.VoteFor.Selling, "E1");
        // Making sure that list for was set and the sell price is the agreed upon price
        require(vault.listFor > 0 && vault.listFor == uints[4], "E2");
        require(isVaultPassedSellOrCancelSellOrderConsensus(vaultId), "E3");
        require(_isParticipantExists(vaultId, msg.sender), "E4");
        require(staticTarget == address(this)
            && keccak256(abi.encodeWithSignature("validateSale(uint256)", vaultId)) == keccak256(staticCalldata), "E5");

        if (!_as.vaultsExtensions[vaultId].isERC1155) {
            require(IERC721(_as.vaults[vaultId].collection).ownerOf(_as.vaults[vaultId].tokenId) == _as.assetsHolders[vaultId], "E6");

            // Decoding opensea calldata to make sure it is going to list the right token
            (,, address token, uint256 tokenId,,) = abi.decode(BytesLib.slice(_calldata, 4, _calldata.length - 4), (
                address, address, address, uint256, bytes32, bytes32[]));

            require(_as.vaults[vaultId].collection == token && _as.vaults[vaultId].tokenId == tokenId, "CE");

        } else {
            // If it was == 1, then it was open to attacks
            require(IERC1155(_as.vaults[vaultId].collection).balanceOf(_as.assetsHolders[vaultId], _as.vaults[vaultId].tokenId) > 0, "E6");

            // Decoding opensea calldata to make sure it is going to list the right token
            (,, address token, uint256 tokenId, uint256 amount,,) = abi.decode(BytesLib.slice(_calldata, 4, _calldata.length - 4), (
                address, address, address, uint256, uint256, bytes32, bytes32[]));

            require(_as.vaults[vaultId].collection == token && _as.vaults[vaultId].tokenId == tokenId && amount == 1, "CE");
        }

        vault.marketplaceAndRoyaltiesFees = uints[0] + uints[1] + uints[2] + uints[3];
    }

    /*
        @dev
        Withdraw the vault's NFT to the address that holding 100% of the shares
        Only applicable for vaults where one address holding 100% of the shares
    */
    function withdrawNFTToOwner(uint256 vaultId) external nonReentrant {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.vaults[vaultId].votingFor == LibDiamond.VoteFor.Selling || _as.vaults[vaultId].votingFor == LibDiamond.VoteFor.CancellingSellOrder, "E1");
        address[] memory participants = _as.vaultParticipantsAddresses[vaultId];
        for (uint256 i; i < participants.length; i++) {
            if (_as.vaultParticipants[vaultId][i].ownership > 0) {
                require(_as.vaultParticipants[vaultId][i].participant == msg.sender, "E2");
                if (_as.vaultParticipants[vaultId][i].partialNFTVaultTokenId != 0) {
                    require(ownerOf(_as.vaultParticipants[vaultId][i].partialNFTVaultTokenId) == msg.sender, "E3");
                    _burn(_as.vaultParticipants[vaultId][i].partialNFTVaultTokenId);
                    // Removing partial NFT from storage
                    delete _as.vaultTokens[_as.vaultParticipants[vaultId][i].partialNFTVaultTokenId];
                }
            }
            if (_as.vaultParticipants[vaultId][i].collectorOwner != address(0)) {
                // In case the partial NFT was sold to someone else, the original collector owner still
                // going to get their token back
                IAssetsHolderImpl(
                    _as.assetsHolders[vaultId]).transferToken(false, _as.vaultParticipants[vaultId][i].collectorOwner,
                    address(LibDiamond.THE_COLLECTORS), _as.vaultParticipants[vaultId][i].stakedCollectorTokenId
                );
            }
        }
        IAssetsHolderImpl(_as.assetsHolders[vaultId]).transferToken(
            _as.vaultsExtensions[vaultId].isERC1155, msg.sender, _as.vaults[vaultId].collection, _as.vaults[vaultId].tokenId
        );
        emit NFTWithdrawnToOwner(vaultId, _as.vaults[vaultId].collection, _as.vaults[vaultId].tokenId, msg.sender);
    }

    // ==================================================================

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
                    if (_as.vaultParticipants[vaultId][i].collectorOwner == msg.sender) {
                        IAssetsHolderImpl(_as.assetsHolders[vaultId]).transferToken(false, msg.sender, address(LibDiamond.THE_COLLECTORS), _as.vaultParticipants[vaultId][i].stakedCollectorTokenId);
                        emit CollectorUnstaked(vaultId, msg.sender, _as.vaultParticipants[vaultId][i].stakedCollectorTokenId);
                    }
                    _removeParticipant(vaultId, i);
                }
                emit FundsWithdrawn(vaultId, msg.sender, amount);
                break;
            }
        }
    }

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
        require(gracePeriodForSellingOrCancellingSellOrder >= 30 days
            && gracePeriodForSellingOrCancellingSellOrder <= 180 days, "E6");
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
            !privateVault, privateVault ? 0 : minimumFunding, 0, !IERC165(collection).supportsInterface(type(IERC721).interfaceId), false, 0
        );
        Address.functionDelegateCall(
            _as.nftVaultAssetsHolderCreator,
            abi.encodeWithSelector(IAssetsHolderCreator.createNFTVaultAssetsHolder.selector, _as.vaultIdTracker.current())
        );
        _as.vaultParticipantsAddresses[_as.vaultIdTracker.current()] = _participants;
        _as.vaultIdTracker.increment();
    }

    // ==================== Views ====================

    function validateSale(uint256 vaultId) public view {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(block.number - _as.vaultsExtensions[vaultId].listingBlockNumber > 3);
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

}

/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <goncalo.sa@consensys.net>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
library BytesLib {

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
    internal
    pure
    returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
                tempBytes := mload(0x40)

            // The first word of the slice result is potentially a partial
            // word read from the original array. To read it, we calculate
            // the length of that partial word and start copying that many
            // bytes into the array. The first word we copy will start with
            // data we don't care about, but the last `lengthmod` bytes will
            // land at the beginning of the contents of the new array. When
            // we're done copying, we overwrite the full first word with
            // the actual length of the slice.
                let lengthmod := and(_length, 31)

            // The multiplication in the next line is necessary
            // because when slicing multiples of 32 bytes (lengthmod == 0)
            // the following copy loop was copying the origin's length
            // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                // The multiplication in the next line has the same exact purpose
                // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

            //update free-memory pointer
            //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
            //zero out the 32 bytes slice we are about to return
            //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

}
