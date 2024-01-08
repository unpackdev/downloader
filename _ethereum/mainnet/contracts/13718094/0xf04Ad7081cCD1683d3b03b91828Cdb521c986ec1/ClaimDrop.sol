//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import "./IERC721.sol";
import "./IERC721Receiver.sol";

contract ClaimDrop is IERC721Receiver {
    IERC721 public immutable baseAddress;
    uint256 public immutable baseTokenId;

    constructor(address _baseAddress, uint256 _baseTokenId) {
        baseAddress = IERC721(_baseAddress);
        baseTokenId = _baseTokenId;
    }

    /// Claim a token owned by this contract, if and only if the sender owns the `baseTokenId`.
    /// @param nft the contract address of the claimable token
    /// @param tokenId the token ID of the claimable token
    /// @param to the address to send the token to
    function claim(
        IERC721 nft,
        uint256 tokenId,
        address to
    ) external {
        require(
            msg.sender == baseAddress.ownerOf(baseTokenId),
            "Not owner of base token"
        );

        nft.safeTransferFrom(address(this), to, tokenId);
    }

    /// IERC721Receiver implementation; all ERC-721s are accepted.
    /// The tokens inside this contract will need to be enumerated off-chain.
    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256 tokenId,
        bytes calldata /* data */
    ) external view override returns (bytes4) {
        // Do not allow the contract to accept the token that is required to claim.
        // Otherwise, an accident could lock the contents forever!
        if (msg.sender == address(baseAddress) && tokenId == baseTokenId) {
            revert("Token is base");
        }
        return IERC721Receiver.onERC721Received.selector;
    }
}
