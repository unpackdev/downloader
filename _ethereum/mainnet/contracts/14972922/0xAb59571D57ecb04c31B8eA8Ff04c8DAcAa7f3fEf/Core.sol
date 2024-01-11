// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IERC721Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./ERC165CheckerUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";

error Not_Valid_Contract();

error Core_Amount_Is_Not_Valid_For_ERC721();

abstract contract Core {
    using ERC165CheckerUpgradeable for address;

    mapping(address => bool) internal _saleContractAllowlist;

    function _trasferNFT(
        address from,
        address to,
        address nftAddress,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (_isERC721(nftAddress)) {
            if (amount > 1) {
                revert Core_Amount_Is_Not_Valid_For_ERC721();
            }
            _transferERC721(from, to, nftAddress, tokenId);
        } else {
            _transferERC1155(from, to, nftAddress, tokenId, amount);
        }
    }

    function _addContractAllowlist(address contractAddress) internal {
        _saleContractAllowlist[contractAddress] = true;
    }

    function _transferERC1155(
        address from,
        address to,
        address nftAddress,
        uint256 tokenId,
        uint256 amount
    ) private {
        IERC1155Upgradeable(nftAddress).safeTransferFrom(
            from,
            to,
            tokenId,
            amount,
            ""
        );
    }

    function _transferERC721(
        address from,
        address to,
        address nftAddress,
        uint256 tokenId
    ) private {
        IERC721Upgradeable(nftAddress).safeTransferFrom(from, to, tokenId);
    }

    function _isERC721(address nftAddress) private view returns (bool) {
        return
            nftAddress.supportsInterface(type(IERC721Upgradeable).interfaceId);
    }

    function onERC721Received(
        address _operator,
        address,
        uint256,
        bytes calldata
    ) external view returns (bytes4) {
        if (_operator == address(this)) {
            return this.onERC721Received.selector;
        }
        return 0x0;
    }

    function onERC1155Received(
        address _operator,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external view returns (bytes4) {
        if (_operator == address(this)) {
            return this.onERC1155Received.selector;
        }
        return 0x0;
    }

    function onERC1155BatchReceived(
        address _operator,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external view returns (bytes4) {
        if (_operator == address(this)) {
            return this.onERC1155BatchReceived.selector;
        }

        return 0x0;
    }
}
