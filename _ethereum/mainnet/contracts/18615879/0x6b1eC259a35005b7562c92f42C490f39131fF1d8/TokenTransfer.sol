// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./ILenderCommitmentForwarder.sol";

abstract contract TokenTransfer {
    function _transferCollateral(
        ILenderCommitmentForwarder.CommitmentCollateralType tokenType,
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 tokenId
    ) internal {
        if (
            tokenType ==
            ILenderCommitmentForwarder.CommitmentCollateralType.ERC20
        ) {
            IERC20(token).transferFrom(from, to, amount);
        } else if (
            tokenType ==
            ILenderCommitmentForwarder.CommitmentCollateralType.ERC721 ||
            tokenType ==
            ILenderCommitmentForwarder.CommitmentCollateralType.ERC721_ANY_ID ||
            tokenType ==
            ILenderCommitmentForwarder
                .CommitmentCollateralType
                .ERC721_MERKLE_PROOF
        ) {
            IERC721(token).safeTransferFrom(from, to, tokenId);
        } else if (
            tokenType ==
            ILenderCommitmentForwarder.CommitmentCollateralType.ERC1155 ||
            tokenType ==
            ILenderCommitmentForwarder
                .CommitmentCollateralType
                .ERC1155_ANY_ID ||
            tokenType ==
            ILenderCommitmentForwarder
                .CommitmentCollateralType
                .ERC1155_MERKLE_PROOF
        ) {
            IERC1155(token).safeTransferFrom(from, to, tokenId, amount, "");
        } else {
            revert("Unsupported token type");
        }
    }

    function _approveCollateral(
        ILenderCommitmentForwarder.CommitmentCollateralType tokenType,
        address token,
        address spender,
        uint256 amount,
        uint256 tokenId
    ) internal {
        if (
            tokenType ==
            ILenderCommitmentForwarder.CommitmentCollateralType.ERC20
        ) {
            IERC20(token).approve(spender, amount);
        } else if (
            tokenType ==
            ILenderCommitmentForwarder.CommitmentCollateralType.ERC721 ||
            tokenType ==
            ILenderCommitmentForwarder.CommitmentCollateralType.ERC721_ANY_ID ||
            tokenType ==
            ILenderCommitmentForwarder
                .CommitmentCollateralType
                .ERC721_MERKLE_PROOF
        ) {
            IERC721(token).approve(spender, tokenId);
        } else if (
            tokenType ==
            ILenderCommitmentForwarder.CommitmentCollateralType.ERC1155 ||
            tokenType ==
            ILenderCommitmentForwarder
                .CommitmentCollateralType
                .ERC1155_ANY_ID ||
            tokenType ==
            ILenderCommitmentForwarder
                .CommitmentCollateralType
                .ERC1155_MERKLE_PROOF
        ) {
            IERC1155(token).setApprovalForAll(spender, true);
        } else {
            revert("Unsupported token type");
        }
    }

    function _balanceOfCollateral(
        ILenderCommitmentForwarder.CommitmentCollateralType tokenType,
        address token,
        address account,
        uint256 tokenId
    ) internal view returns (uint256) {
        if (
            tokenType ==
            ILenderCommitmentForwarder.CommitmentCollateralType.ERC20
        ) {
            return IERC20(token).balanceOf(account);
        } else if (
            tokenType ==
            ILenderCommitmentForwarder.CommitmentCollateralType.ERC721 ||
            tokenType ==
            ILenderCommitmentForwarder.CommitmentCollateralType.ERC721_ANY_ID ||
            tokenType ==
            ILenderCommitmentForwarder
                .CommitmentCollateralType
                .ERC721_MERKLE_PROOF
        ) {
            return IERC721(token).ownerOf(tokenId) == account ? 1 : 0;
        } else if (
            tokenType ==
            ILenderCommitmentForwarder.CommitmentCollateralType.ERC1155 ||
            tokenType ==
            ILenderCommitmentForwarder
                .CommitmentCollateralType
                .ERC1155_ANY_ID ||
            tokenType ==
            ILenderCommitmentForwarder
                .CommitmentCollateralType
                .ERC1155_MERKLE_PROOF
        ) {
            return IERC1155(token).balanceOf(account, tokenId);
        } else {
            revert("Unsupported token type");
        }
    }

    // TODO: 721 & 1155 receive support
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function onERC1155Received(
        address,
        address,
        uint256 id,
        uint256 value,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }
}
