// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IERC1155Transferable.sol";

import "./Ownable.sol";
import "./ERC1155Holder.sol";

/**
 * @title ERC1155TransferableWrapper
 * @author @NiftyMike | @NFTCulture
 * @dev Wrapper class to more easily enable bulk transferring of ERC1155 tokens.
 *
 * Note: Tokens must be transferred into the wrapper to be bulk transferred. Also,
 * so as to prevent spam, only allowing Owner to utilize functionality.
 */
contract ERC1155TransferableWrapper is Ownable, ERC1155Holder {
    IERC1155Transferable public erc1155Transferable;

    constructor(address __erc1155Address) {
        _updateERC1155Contract(__erc1155Address);
    }

    /**
     * @notice Query for my balance on the source ERC1155 Contract.
     *
     * @param tokenId the ID of the fungible token.
     */
    function balanceOf(uint256 tokenId) public view returns (uint256) {
        return erc1155Transferable.balanceOf(address(this), tokenId);
    }

    /**
     * @notice Update the ERC1155 token contract that this contract should manage.
     *
     * @param __erc1155Address the ERC1155 address to change to.
     */
    function updateERC1155Contract(address __erc1155Address) external onlyOwner {
        _updateERC1155Contract(__erc1155Address);
    }

    /**
     * @notice Transfer some quantity of a fungible token from caller to a single friend.
     *
     * @param friend address to send tokens to.
     * @param tokenId the ID of the fungible token.
     * @param count the quantity of the fungible token to transfer to the friend.
     */
    function transferToFriend(address friend, uint256 tokenId, uint256 count) external onlyOwner{
        erc1155Transferable.safeTransferFrom(address(this), friend, tokenId, count, "");
    }

    /**
     * @notice Transfer some quantity of a fungible token from caller to many friends.
     *
     * @param friends an array of addresses to send tokens to.
     * @param tokenId the ID of the fungible token.
     * @param count the quantity of the fungible token to transfer to each friend.
     */
    function transferToFriends(address[] memory friends, uint256 tokenId, uint256 count) external onlyOwner{
        uint256 idx;

        for (idx = 0; idx < friends.length; idx++) {
            erc1155Transferable.safeTransferFrom(address(this), friends[idx], tokenId, count, "");
        }
    }

    /**
     * @notice Return unsent tokens back to owner.
     *
     * @param tokenId the ID of the fungible token.
     * @param count the amount to return to owner.
     */
    function returnToOwner(uint256 tokenId, uint256 count) external onlyOwner {
        erc1155Transferable.safeTransferFrom(address(this), msg.sender, tokenId, count, "");
    }

    function _updateERC1155Contract(address __erc1155Address) internal {
        if (__erc1155Address != address(0)) {
            erc1155Transferable = IERC1155Transferable(__erc1155Address);
        }
    }
}
