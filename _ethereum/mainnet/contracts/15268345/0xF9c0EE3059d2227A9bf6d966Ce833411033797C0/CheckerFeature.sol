/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IERC721.sol";
import "./IERC1155.sol";
import "./IConduitController.sol";
import "./ISeaport.sol";
import "./ITransferSelectorNFT.sol";
import "./ILooksRare.sol";
import "./IX2y2.sol";


contract CheckerFeature {

    address public constant SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
    address public immutable LOOKS_RARE;
    address public immutable X2Y2;
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    constructor(address looksRare, address x2y2) {
        LOOKS_RARE = looksRare;
        X2Y2 = x2y2;
    }

    struct SeaportCheckInfo {
        address conduit;
        bool conduitExists;
        address erc721Owner;
        bool isApprovedForAll; // erc721.isApprovedForAll or erc1155.isApprovedForAll
        address erc721ApprovedAccount; // erc721.getApproved(tokenId)
        uint256 erc1155Balance;
        bool isValidated;
        bool isCancelled;
        uint256 totalFilled;
        uint256 totalSize;
    }

    struct LooksRareCheckInfo {
        address transferManager;
        address erc721Owner;
        bool isApprovedForAll; // erc721.isApprovedForAll or erc1155.isApprovedForAll
        address erc721ApprovedAccount; // erc721.getApproved(tokenId)
        uint256 erc1155Balance;
        bool isExecutedOrCancelled;
    }

    struct X2y2CheckInfo {
        address erc721Owner;
        bool isApprovedForAll; // erc721.isApprovedForAll
        address erc721ApprovedAccount; // erc721.getApproved(tokenId)
        IX2y2.InvStatus status;
    }

    function getSeaportCheckInfo(address account, address nft, uint256 tokenId, bytes32 conduitKey, bytes32 orderHash)
        external
        view
        returns (SeaportCheckInfo memory info)
    {
        (info.conduit, info.conduitExists) = getConduit(conduitKey);
        if (supportsERC721(nft)) {
            info.erc721Owner = ownerOf(nft, tokenId);
            info.erc721ApprovedAccount = getApproved(nft, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, info.conduit);
        } else if (supportsERC1155(nft)) {
            info.erc1155Balance = balanceOf(nft, account, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, info.conduit);
        }

        try ISeaport(SEAPORT).getOrderStatus(orderHash) returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        ) {
            info.isValidated = isValidated;
            info.isCancelled = isCancelled;
            info.totalFilled = totalFilled;
            info.totalSize = totalSize;
        } catch {}
        return info;
    }

    function getLooksRareCheckInfo(address account, address nft, uint256 tokenId, uint256 accountNonce)
        external
        view
        returns (LooksRareCheckInfo memory info)
    {
        try ILooksRare(LOOKS_RARE).transferSelectorNFT() returns (ITransferSelectorNFT transferSelector) {
            try transferSelector.checkTransferManagerForToken(nft) returns (address transferManager) {
                info.transferManager = transferManager;
            } catch {}
        } catch {}

        try ILooksRare(LOOKS_RARE).isUserOrderNonceExecutedOrCancelled(account, accountNonce) returns (bool isExecutedOrCancelled) {
            info.isExecutedOrCancelled = isExecutedOrCancelled;
        } catch {}

        if (supportsERC721(nft)) {
            info.erc721Owner = ownerOf(nft, tokenId);
            info.erc721ApprovedAccount = getApproved(nft, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, info.transferManager);
        } else if (supportsERC1155(nft)) {
            info.erc1155Balance = balanceOf(nft, account, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, info.transferManager);
        }
        return info;
    }

    function getX2y2CheckInfo(address account, address nft, uint256 tokenId, bytes32 orderHash, address executionDelegate)
        external
        view
        returns (X2y2CheckInfo memory info)
    {
        if (X2Y2 == address(0)) {
            return info;
        }

        try IX2y2(X2Y2).inventoryStatus(orderHash) returns (IX2y2.InvStatus status) {
            info.status = status;
        } catch {}

        if (supportsERC721(nft)) {
            info.erc721Owner = ownerOf(nft, tokenId);
            info.erc721ApprovedAccount = getApproved(nft, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, executionDelegate);
        }
        return info;
    }

    function getConduit(bytes32 conduitKey) public view returns (address conduit, bool exists) {
        try ISeaport(SEAPORT).information() returns (string memory, bytes32, address conduitController) {
            try IConduitController(conduitController).getConduit(conduitKey) returns (address _conduit, bool _exists) {
                conduit = _conduit;
                exists = _exists;
            } catch {
            }
        } catch {
        }
        return (conduit, exists);
    }

    function supportsERC721(address nft) internal view returns (bool) {
        try IERC165(nft).supportsInterface(INTERFACE_ID_ERC721) returns (bool support) {
            return support;
        } catch {
        }
        return false;
    }

    function supportsERC1155(address nft) internal view returns (bool) {
        try IERC165(nft).supportsInterface(INTERFACE_ID_ERC1155) returns (bool support) {
            return support;
        } catch {
        }
        return false;
    }

    function ownerOf(address nft, uint256 tokenId) internal view returns (address owner) {
        try IERC721(nft).ownerOf(tokenId) returns (address _owner) {
            owner = _owner;
        } catch {
        }
        return owner;
    }

    function getApproved(address nft, uint256 tokenId) internal view returns (address operator) {
        try IERC721(nft).getApproved(tokenId) returns (address approvedAccount) {
            operator = approvedAccount;
        } catch {
        }
        return operator;
    }

    function isApprovedForAll(address nft, address owner, address operator) internal view returns (bool isApproved) {
        if (operator != address(0)) {
            try IERC721(nft).isApprovedForAll(owner, operator) returns (bool _isApprovedForAll) {
                isApproved = _isApprovedForAll;
            } catch {
            }
        }
        return isApproved;
    }

    function balanceOf(address nft, address account, uint256 id) internal view returns (uint256 balance) {
        try IERC1155(nft).balanceOf(account, id) returns (uint256 _balance) {
            balance = _balance;
        } catch {
        }
        return balance;
    }
}
