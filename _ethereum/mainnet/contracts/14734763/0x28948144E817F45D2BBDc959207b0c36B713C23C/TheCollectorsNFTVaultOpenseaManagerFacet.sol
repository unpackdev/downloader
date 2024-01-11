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

 ██████╗ ██████╗ ███████╗███╗   ██╗███████╗███████╗ █████╗
██╔═══██╗██╔══██╗██╔════╝████╗  ██║██╔════╝██╔════╝██╔══██╗
██║   ██║██████╔╝█████╗  ██╔██╗ ██║███████╗█████╗  ███████║
██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║╚════██║██╔══╝  ██╔══██║
╚██████╔╝██║     ███████╗██║ ╚████║███████║███████╗██║  ██║
 ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝╚══════╝╚══════╝╚═╝  ╚═╝

███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗     ███████╗ █████╗  ██████╗███████╗████████╗
████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗    ██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝
██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝    █████╗  ███████║██║     █████╗     ██║
██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗    ██╔══╝  ██╔══██║██║     ██╔══╝     ██║
██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║    ██║     ██║  ██║╚██████╗███████╗   ██║
╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝   ╚═╝

*/

import "./TheCollectorsNFTVaultBaseFacet.sol";
import "./TheCollectorsNFTVaultOpenseaAssetsHolderProxy.sol";

/*
    @dev
    The facet that handling all opensea logic and can be called only by @TheCollectorsNFTVaultDiamond
    This contract is part of a diamond / facets implementation as described
    in EIP 2535 (https://eips.ethereum.org/EIPS/eip-2535)
*/
contract TheCollectorsNFTVaultOpenseaManagerFacet is TheCollectorsNFTVaultBaseFacet {
    using Counters for Counters.Counter;
    using Strings for uint256;

    constructor() ERC721("", "") {}

    // ==================== Opensea ====================

    /*
        @dev
        Creating a new class to hold and operate one asset on opensea
    */
    function createNFTVaultAssetsHolder(uint256 vaultId) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.assetsHolders[vaultId] == address(0), "E1");
        _as.assetsHolders[vaultId] = payable(new TheCollectorsNFTVaultOpenseaAssetsHolderProxy(_as.nftVaultAssetHolderImpl));
    }

    /*
        @dev
        Buying the agreed upon token from Opensea.
        Not checking if msg.sender is a participant since a buy consensus must be met
    */
    function buyNFTOnOpensea(
        uint256 vaultId,
        address[14] memory addrs,
        uint[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell,
        uint8[2] memory vs,
        bytes32[5] memory rssMetadata
    ) external nonReentrant {

        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();

        _beforePurchasingNFTOnOpensea(vaultId, uints[4], calldataBuy);

        uint256 purchasePrice = TheCollectorsNFTVaultOpenseaAssetsHolderImpl(_as.assetsHolders[vaultId]).buyNFTOnOpensea(
            addrs,
            uints,
            feeMethodsSidesKindsHowToCalls,
            calldataBuy,
            calldataSell,
            replacementPatternBuy,
            replacementPatternSell,
            staticExtradataBuy,
            staticExtradataSell,
            vs,
            rssMetadata
        );

        _afterPurchaseNFT(vaultId, purchasePrice, true);
    }

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

        _beforeListingNFTOnOpensea(vaultId, uints, _calldata);

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
            ), "E5"
        );

        _resetVotesAndGracePeriod(vaultId);

        LibDiamond.appStorage().vaults[vaultId].votingFor = LibDiamond.VoteFor.CancellingSellOrder;

        emit NFTListedForSale(LibDiamond.appStorage().vaults[vaultId].id, LibDiamond.appStorage().vaults[vaultId].collection, LibDiamond.appStorage().vaults[vaultId].tokenId, LibDiamond.appStorage().vaults[vaultId].listFor);
    }

    /*
        @dev
        Canceling a previous sale order in Opensea exchange.
        This function must be called before re-listing with another price.
        Need to check if msg.sender is a participant since after grace period is over, all undecided votes
        are considered as yes which might make the sell consensus pass
    */
    function cancelListingOnOpensea(
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

        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();

        _beforeCancellingSellOrderOnOpensea(vaultId, _calldata);

        TheCollectorsNFTVaultOpenseaAssetsHolderImpl(_as.assetsHolders[vaultId]).cancelListingOnOpensea(
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
            ) == false, "E4"
        );

        _resetVotesAndGracePeriod(vaultId);

        _as.vaults[vaultId].votingFor = LibDiamond.VoteFor.Selling;

        emit NFTSellOrderCanceled(vaultId, _as.vaults[vaultId].collection, _as.vaults[vaultId].tokenId);
    }

    // ==================== Internals ====================

    /*
        @dev
        A helper function to validate whatever the vault is ready to purchase the token
    */
    function _beforePurchasingNFTOnOpensea(uint256 vaultId, uint256 purchasePrice, bytes memory calldataBuy) internal view {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _requireBuyConsensusAndValidatePurchasePrice(vaultId, purchasePrice);

        if (!_as.vaultsExtensions[vaultId].isERC1155) {
            // Decoding opensea calldata to make sure it is going to purchase the right token
            (, address to, address token, uint256 tokenId,,) = abi.decode(BytesLib.slice(calldataBuy, 4, calldataBuy.length - 4), (
                address, address, address, uint256, bytes32, bytes32[]));

            require(to == _as.assetsHolders[vaultId] && _as.vaults[vaultId].collection == token && _as.vaults[vaultId].tokenId == tokenId, "CE");
        } else {

            // Decoding opensea calldata to make sure it is going to purchase the right token
            (, address to, address token, uint256 tokenId, uint256 amount,,) = abi.decode(BytesLib.slice(calldataBuy, 4, calldataBuy.length - 4), (
                address, address, address, uint256, uint256, bytes32, bytes32[]));

            require(to == _as.assetsHolders[vaultId] && _as.vaults[vaultId].collection == token && _as.vaults[vaultId].tokenId == tokenId && amount == 1, "CE");
        }
    }

    /*
        @dev
        A helper function to validate whatever the vault is ready to list the token for sale
    */
    function _beforeListingNFTOnOpensea(uint256 vaultId, uint256[9] memory uints, bytes memory _calldata) internal {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        require(vault.votingFor == LibDiamond.VoteFor.Selling, "E1");
        // Making sure that list for was set and the sell price is the agreed upon price
        require(vault.listFor > 0 && vault.listFor == uints[4], "E2");
        require(isVaultPassedSellOrCancelSellOrderConsensus(vaultId), "E3");
        require(_isParticipantExists(vaultId, msg.sender), "E4");

        if (!_as.vaultsExtensions[vaultId].isERC1155) {
            require(IERC721(_as.vaults[vaultId].collection).ownerOf(_as.vaults[vaultId].tokenId) == _as.assetsHolders[vaultId], "E5");

            // Decoding opensea calldata to make sure it is going to list the right token
            (,, address token, uint256 tokenId,,) = abi.decode(BytesLib.slice(_calldata, 4, _calldata.length - 4), (
                address, address, address, uint256, bytes32, bytes32[]));

            require(_as.vaults[vaultId].collection == token && _as.vaults[vaultId].tokenId == tokenId, "CE");

        } else {
            // If it was == 1, then it was open to attacks
            require(IERC1155(_as.vaults[vaultId].collection).balanceOf(_as.assetsHolders[vaultId], _as.vaults[vaultId].tokenId) > 0, "E5");

            // Decoding opensea calldata to make sure it is going to list the right token
            (,, address token, uint256 tokenId, uint256 amount,,) = abi.decode(BytesLib.slice(_calldata, 4, _calldata.length - 4), (
                address, address, address, uint256, uint256, bytes32, bytes32[]));

            require(_as.vaults[vaultId].collection == token && _as.vaults[vaultId].tokenId == tokenId && amount == 1, "CE");
        }

        vault.marketplaceAndRoyaltiesFees = uints[0] + uints[1] + uints[2] + uints[3];
    }

    /*
        @dev
        A helper function to validate whatever the vault has an open sell order and there is a consensus for cancelling
    */
    function _beforeCancellingSellOrderOnOpensea(uint256 vaultId, bytes memory _calldata) internal view {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.vaults[vaultId].votingFor == LibDiamond.VoteFor.CancellingSellOrder, "E1");
        require(_isParticipantExists(vaultId, msg.sender), "E2");
        require(isVaultPassedSellOrCancelSellOrderConsensus(vaultId), "E3");

        if (!_as.vaultsExtensions[vaultId].isERC1155) {
            require(IERC721(_as.vaults[vaultId].collection).ownerOf(_as.vaults[vaultId].tokenId) == _as.assetsHolders[vaultId], "E4");

            // Decoding opensea calldata to make sure it is going to cancel the right token
            (,, address token, uint256 tokenId,,) = abi.decode(BytesLib.slice(_calldata, 4, _calldata.length - 4), (
                address, address, address, uint256, bytes32, bytes32[]));

            require(_as.vaults[vaultId].collection == token && _as.vaults[vaultId].tokenId == tokenId, "CE");

        } else {
            // If it was == 1, then it was open to attacks
            require(IERC1155(_as.vaults[vaultId].collection).balanceOf(_as.assetsHolders[vaultId], _as.vaults[vaultId].tokenId) > 0, "E4");

            // Decoding opensea calldata to make sure it is going to cancel the right token
            (,, address token, uint256 tokenId, uint256 amount,,) = abi.decode(BytesLib.slice(_calldata, 4, _calldata.length - 4), (
                address, address, address, uint256, uint256, bytes32, bytes32[]));

            require(_as.vaults[vaultId].collection == token && _as.vaults[vaultId].tokenId == tokenId && amount == 1, "CE");
        }
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
