// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/***
 *    ╔╦╗╦ ╦╔═╗
 *     ║ ╠═╣║╣
 *     ╩ ╩ ╩╚═╝
 *    ╔═╗╔═╗╦  ╦  ╔═╗╔═╗╔╦╗╔═╗╦═╗╔═╗
 *    ║  ║ ║║  ║  ║╣ ║   ║ ║ ║╠╦╝╚═╗
 *    ╚═╝╚═╝╩═╝╩═╝╚═╝╚═╝ ╩ ╚═╝╩╚═╚═╝
 *    ╔╗╔╔═╗╔╦╗
 *    ║║║╠╣  ║
 *    ╝╚╝╚   ╩
 *    ╦  ╦╔═╗╦ ╦╦ ╔╦╗
 *    ╚╗╔╝╠═╣║ ║║  ║
 *     ╚╝ ╩ ╩╚═╝╩═╝╩
 *    ╔═╗╔═╗╔═╗╔╗╔╔═╗╔═╗╔═╗
 *    ║ ║╠═╝║╣ ║║║╚═╗║╣ ╠═╣
 *    ╚═╝╩  ╚═╝╝╚╝╚═╝╚═╝╩ ╩
 *    ╔═╗╔═╗╔═╗╔═╗╔╦╗
 *    ╠═╣╚═╗╚═╗║╣  ║
 *    ╩ ╩╚═╝╚═╝╚═╝ ╩
 *    ╦╔╦╗╔═╗╦
 *    ║║║║╠═╝║
 *    ╩╩ ╩╩  ╩═╝
 */

import "./Imports.sol";
import "./Interfaces.sol";
import "./LibDiamond.sol";

struct Participant {
    address participant;
    uint256 paid;
    uint256 leftovers;
    bool vote;
    address collectorOwner;
    uint256 stakedCollectorTokenId;
    uint256 partialNFTVaultTokenId;
    bool voted;
    uint256 ownership;
}

interface INFTVault {
    function getVaultParticipants(uint256 vaultId) external view returns (Participant[] memory);
}

/*
    @dev
    The business logic code of the asset holder.
    Working together with @TheCollectorsNFTVaultOpenseaAssetsHolderProxy in a proxy/implementation design pattern.
    The reason why it is separated to proxy and implementation is to save gas when creating vaults (reduced 50% gas)
*/
contract TheCollectorsNFTVaultOpenseaAssetsHolderImpl is ERC721Holder, ERC1155Holder, Ownable {

    // Must be in the same order as @TheCollectorsNFTVaultOpenseaAssetsHolderProxy
    address internal _proxyAddress;

    // For executing transactions
    address public target;
    bytes public data;
    uint256 public value;
    mapping(address => bool) public consensus;

    function init() public onlyOwner {
        // Registering opensea proxy
        _proxyAddress = IProxyRegistry(LibDiamond.OPENSEA_PROXY_REGISTRY).registerProxy();
    }

    /*
        @dev
        Buying the requested NFT on Opensea without doing any verifications
    */
    function buyNFTOnOpensea(
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
    ) public onlyOwner returns (uint256) {
        uint256 balanceBefore = address(this).balance;
        LibDiamond.OPENSEA_EXCHANGE.atomicMatch_{value : uints[4]}(
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
        return balanceBefore - address(this).balance;
    }

    /*
        @dev
        Listing the requested NFT on Opensea without doing any verifications
    */
    function listNFTOnOpensea(
        address collection,
        address[7] memory addrs,
        uint[9] memory uints,
        uint8 feeMethod,
        uint8 side,
        uint8 saleKind,
        uint8 howToCall,
        bytes memory _calldata,
        bytes memory replacementPattern,
        bytes memory staticExtradata
    ) public onlyOwner {
        // Approving opensea proxy to transfer our token
        // This applies to ERC721 and ERC1155
        if (!IApproveableNFT(collection).isApprovedForAll(address(this), address(_proxyAddress))) {
            IApproveableNFT(collection).setApprovalForAll(_proxyAddress, true);
        }
        LibDiamond.OPENSEA_EXCHANGE.approveOrder_(
            addrs,
            uints,
            feeMethod,
            side,
            saleKind,
            howToCall,
            _calldata,
            replacementPattern,
            staticExtradata,
            true
        );
    }

    /*
        @dev
        Cancelling sell order of the requested NFT on Opensea without doing any verifications
    */
    function cancelListingOnOpensea(
        address[7] memory addrs,
        uint[9] memory uints,
        uint8 feeMethod,
        uint8 side,
        uint8 saleKind,
        uint8 howToCall,
        bytes memory _calldata,
        bytes memory replacementPattern,
        bytes memory staticExtradata
    ) public onlyOwner {
        LibDiamond.OPENSEA_EXCHANGE.cancelOrder_(
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
        );
    }

    /*
        @dev
        Transferring the assets to someone else, can only be called by the owner, the asset holder
    */
    function transferToken(bool isERC1155, address recipient, address collection, uint256 tokenId) public onlyOwner {
        if (isERC1155) {
            IERC1155(collection).safeTransferFrom(address(this), recipient, tokenId, 1, "");
        } else {
            IERC721(collection).safeTransferFrom(address(this), recipient, tokenId);
        }
    }

    /*
        @dev
        Transferring ETH to someone else, can only be called by the owner
    */
    function sendValue(address payable to, uint256 amount) public onlyOwner {
        Address.sendValue(to, amount);
    }

    /*
        @dev
        Confirming or executing a transaction just like a multisig contract
        Initially the contract did not contain this functionality, however, after reconsidering claiming and airdrop
        scenarios it was decided to add it.
        Please notice that there will need to be a 100% consensus to run a transaction without any grace period.
    */
    function executeTransaction(uint256 vaultId, address _target, bytes memory _data, uint256 _value) public {
        Participant[] memory participants = INFTVault(owner()).getVaultParticipants(vaultId);
        // Only a participant with ownership can confirm or execute transactions
        // Only after the nft vault has purchased the NFT the participants getting the ownership property filled
        require(_isParticipantExistsWithOwnership(participants, msg.sender), "E1");

        if (target == _target && keccak256(_data) == keccak256(data) && _value == value) {
            // Approving current transaction
            consensus[msg.sender] = true;
        } else {
            // New transaction and overriding previous transaction
            target = _target;
            data = _data;
            value = _value;
            for (uint256 i; i < participants.length; i++) {
                // Resetting all votes expect the sender
                consensus[participants[i].participant] = participants[i].participant == msg.sender;
            }
        }

        bool passedConsensus = true;
        for (uint256 i; i < participants.length; i++) {
            // We need to check ownership > 0 because some participants can be in the vault but did not contribute
            // any funds (i.e were added by the vault creator)
            if (participants[i].ownership > 0 && !consensus[participants[i].participant]) {
                passedConsensus = false;
                break;
            }
        }

        if (passedConsensus) {

            if (Address.isContract(target)) {
                Address.functionCallWithValue(target, data, value);
            } else {
                Address.sendValue(payable(target), value);
            }

            // Resetting votes and transaction
            for (uint256 i; i < participants.length; i++) {
                consensus[participants[i].participant] = false;
            }
            target = address(0);
            data = "";
            value = 0;
        }
    }

    // ==================== Internals ====================

    /*
        @dev
        A helper function to find out if a participant is part of a vault with ownership
    */
    function _isParticipantExistsWithOwnership(Participant[] memory participants, address participant) internal pure returns (bool) {
        for (uint256 i; i < participants.length; i++) {
            if (participants[i].ownership > 0 && participants[i].participant == participant) {
                return true;
            }
        }
        return false;
    }

}

