// SPDX-License-Identifier: MIT
import "./ERC1155URIStorage.sol";
import "./AllowedAddresses.sol";

pragma solidity ^0.8.7;

error Achievements__TransfersAreNotAllowed();
error Achievements__SenderIsNotOwner();

contract Achievements is ERC1155URIStorage, AllowedAddresses {
    string constant NAME = "Verdomi Achievements";
    string constant SYMBOL = "ACVMT";

    constructor() ERC1155URIStorage() ERC1155("") {}

    function setTokenURI(uint256 tokenId, string memory tokenURI) external onlyOwner {
        _setURI(tokenId, tokenURI);
    }

    function grantAchievement(address to, uint256 tokenId) external onlyAllowedAddresses {
        _mint(to, tokenId, 1, "");
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        if (account != _msgSender()) {
            revert Achievements__SenderIsNotOwner();
        }
        _burn(account, id, value);
    }

    function name() external pure returns (string memory) {
        return NAME;
    }

    function symbol() external pure returns (string memory) {
        return SYMBOL;
    }

    // Overriding transfer functions.
    // You can't transfer your achievement!

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal pure override {
        revert Achievements__TransfersAreNotAllowed();
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal pure override {
        revert Achievements__TransfersAreNotAllowed();
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal pure override {
        revert Achievements__TransfersAreNotAllowed();
    }
}
