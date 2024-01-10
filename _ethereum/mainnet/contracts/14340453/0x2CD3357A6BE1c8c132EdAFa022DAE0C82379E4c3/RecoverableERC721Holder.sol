
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)
pragma solidity ^0.8.0;

import "./Interfaces.sol";
import "./Ownable.sol";
import "./IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract RecoverableERC721Holder is Ownable, IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev Allows for the safeTransfer of all ERC721 assets from this contract to a list of recipients
     */
    function emergencyTransferOut(address[] calldata _tokenAddressesToTransfer, address[] calldata _recipients, uint[] calldata _tokenIds) external onlyOwner {
        require((_tokenAddressesToTransfer.length == _tokenIds.length) && (_tokenIds.length == _recipients.length), "ERROR: INVALID INPUT DATA - MISMATCHED LENGTHS");

        for(uint i = 0; i < _recipients.length; i++) {
            IToken(_tokenAddressesToTransfer[i]).safeTransferFrom(address(this), _recipients[i], _tokenIds[i]);
        }
    }
}