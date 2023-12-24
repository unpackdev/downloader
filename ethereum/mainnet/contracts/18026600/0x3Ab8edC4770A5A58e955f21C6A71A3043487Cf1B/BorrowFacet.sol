// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./IERC721.sol";

import "./IBorrowFacet.sol";

import "./BorrowHandlers.sol";
import "./Objects.sol";

/// @notice public facing methods for borrowing
/// @dev contract handles all borrowing logic through inheritance
contract BorrowFacet is IBorrowFacet, BorrowHandlers {
    /// @notice borrow using sent NFT as collateral without needing approval through transfer callback
    /// @param from account that owned the NFT before transfer
    /// @param tokenId token identifier of the NFT sent according to the NFT implementation contract
    /// @param data abi encoded arguments for the loan
    /// @return selector `this.onERC721Received.selector` ERC721-compliant response, signaling compatibility
    /// @dev param data must be of format OfferArg[]
    function onERC721Received(
        address, // operator
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        OfferArg[] memory args = abi.decode(data, (OfferArg[]));

        // `from` will be considered the borrower, and the NFT will be transferred to the Kairos contract
        // the `operator` that called `safeTransferFrom` is ignored
        useCollateral(args, from, NFToken({implem: IERC721(msg.sender), id: tokenId}));

        return this.onERC721Received.selector;
    }

    /// @notice take loans, take ownership of NFTs specified as collateral, sends borrowed money to caller
    /// @param args list of arguments specifying at which terms each collateral should be used
    /// @return loanIds list of loan ids created
    function borrow(BorrowArg[] calldata args) external returns (uint256[] memory loanIds) {
        loanIds = new uint256[](args.length);

        for (uint256 i = 0; i < args.length; i++) {
            args[i].nft.implem.transferFrom(msg.sender, address(this), args[i].nft.id);
            uint256 loan = useCollateral(args[i].args, msg.sender, args[i].nft);
            loanIds[i] = loan;
        }

        return loanIds;
    }
}
