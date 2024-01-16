/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./IAssetCheckerFeature.sol";


contract AssetCheckerFeature is IAssetCheckerFeature {

    bytes4 public constant INTERFACE_ID_ERC20 = 0x36372b07;
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;
    address internal constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function checkAssetsEx(
        address account,
        address operator,
        uint8[] calldata itemTypes,
        address[] calldata tokens,
        uint256[] calldata tokenIds
    )
        external
        override
        view
        returns (AssetCheckResultInfo[] memory infos)
    {
        require(itemTypes.length == tokens.length, "require(itemTypes.length == tokens.length)");
        require(itemTypes.length == tokenIds.length, "require(itemTypes.length == tokenIds.length)");

        infos = new AssetCheckResultInfo[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 tokenId = tokenIds[i];

            infos[i].itemType = itemTypes[i];
            if (itemTypes[0] == 0) {
                infos[i].allowance = isApprovedForAll(token, account, operator) ? 1 : 0;
                infos[i].erc721Owner = ownerOf(token, tokenId);
                infos[i].erc721ApprovedAccount = getApproved(token, tokenId);
                infos[i].balance = (infos[i].erc721Owner == account) ? 1 : 0;
                continue;
            }

            if (itemTypes[0] == 1) {
                infos[i].allowance = isApprovedForAll(token, account, operator) ? 1 : 0;
                infos[i].balance = balanceOf(token, account, tokenId);
                continue;
            }

            if (itemTypes[0] == 2) {
                if (token == address(0) || token == NATIVE_TOKEN_ADDRESS) {
                    infos[i].balance = account.balance;
                    infos[i].allowance = type(uint256).max;
                } else {
                    infos[i].balance = balanceOf(token, account);
                    infos[i].allowance = allowanceOf(token, account, operator);
                }
            }
        }
        return infos;
    }

    function checkAssets(address account, address operator, address[] calldata tokens, uint256[] calldata tokenIds)
        external
        override
        view
        returns (AssetCheckResultInfo[] memory infos)
    {
        require(tokens.length == tokenIds.length, "require(tokens.length == tokenIds.length)");

        infos = new AssetCheckResultInfo[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 tokenId = tokenIds[i];

            if (supportsInterface(token, INTERFACE_ID_ERC721)) {
                infos[i].itemType = 0;
                infos[i].allowance = isApprovedForAll(token, account, operator) ? 1 : 0;
                infos[i].erc721Owner = ownerOf(token, tokenId);
                infos[i].erc721ApprovedAccount = getApproved(token, tokenId);
                infos[i].balance = (infos[i].erc721Owner == account) ? 1 : 0;
                continue;
            }

            if (supportsInterface(token, INTERFACE_ID_ERC1155)) {
                infos[i].itemType = 1;
                infos[i].allowance = isApprovedForAll(token, account, operator) ? 1 : 0;
                infos[i].balance = balanceOf(token, account, tokenId);
                continue;
            }

            if (supportsInterface(token, INTERFACE_ID_ERC20)) {
                infos[i].itemType = 2;
                if (token == address(0) || token == NATIVE_TOKEN_ADDRESS) {
                    infos[i].balance = account.balance;
                    infos[i].allowance = type(uint256).max;
                } else {
                    infos[i].balance = balanceOf(token, account);
                    infos[i].allowance = allowanceOf(token, account, operator);
                }
            } else {
                infos[i].itemType = 255;
            }
        }
        return infos;
    }

    function supportsInterface(address nft, bytes4 interfaceId) internal view returns (bool) {
        try IERC165(nft).supportsInterface(interfaceId) returns (bool support) {
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

    function balanceOf(address erc20, address account) internal view returns (uint256 balance) {
        try IERC20(erc20).balanceOf(account) returns (uint256 _balance) {
            balance = _balance;
        } catch {
        }
        return balance;
    }

    function allowanceOf(address erc20, address owner, address spender) internal view returns (uint256 allowance) {
        try IERC20(erc20).allowance(owner, spender) returns (uint256 _allowance) {
            allowance = _allowance;
        } catch {
        }
        return allowance;
    }

    function balanceOf(address nft, address account, uint256 id) internal view returns (uint256 balance) {
        try IERC1155(nft).balanceOf(account, id) returns (uint256 _balance) {
            balance = _balance;
        } catch {
        }
        return balance;
    }
}
