// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SafeERC20Upgradeable.sol";
import "./ERC165CheckerUpgradeable.sol";
import "./IERC721Royalties.sol";
import "./IERC20Permit.sol";
import "./IERC721Permit.sol";
import "./IERC1155Permit.sol";

library LibAsset {
    using SafeERC20Upgradeable for IERC20Permit;
    using ERC165CheckerUpgradeable for address;

    uint256 public constant MAX_ROYALTY_VALUE = 2000;

    /// @notice Order hash for EIP712
    bytes32 private constant ASSET_TYPEHASH =
        keccak256("Asset(uint8 assetType,address token,uint256 id,uint256 amount)");

    enum AssetType {
        ERC20,
        ERC721,
        ERC1155,
        ETH
    }

    struct Asset {
        AssetType assetType;
        address token;
        uint256 id;
        uint256 amount;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct SignatureERC20 {
        uint256 amount;
        uint256 deadline;
        Signature sig;
    }

    struct SignatureERC721 {
        bool forAll;
        uint256 tokenId;
        uint256 deadline;
        Signature sig;
    }

    struct SignatureERC1155 {
        uint256 deadline;
        Signature sig;
    }

    function hashAsset(Asset memory asset) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(ASSET_TYPEHASH, asset.assetType, asset.token, asset.id, asset.amount)
            );
    }

    function isCommodity(Asset memory asset) internal pure returns (bool) {
        return asset.assetType == AssetType.ERC721 || asset.assetType == AssetType.ERC1155;
    }

    function isPayment(Asset memory asset, bool buyOrder) internal pure returns (bool) {
        if (buyOrder) {
            return asset.assetType == AssetType.ERC20;
        } else {
            return asset.assetType == AssetType.ERC20 || asset.assetType == AssetType.ETH;
        }
    }

    function withAmount(Asset memory asset, uint256 amount) internal pure returns (Asset memory) {
        return
            Asset({assetType: asset.assetType, token: asset.token, amount: amount, id: asset.id});
    }

    function getRoyalty(Asset memory asset)
        internal
        view
        returns (address receiver, uint256 value)
    {
        if (
            asset.assetType == AssetType.ERC721 &&
            asset.token.supportsInterface(type(IERC721Royalties).interfaceId)
        ) {
            (receiver, value) = IERC721Royalties(asset.token).getRoyalty(asset.id);
            require(value <= MAX_ROYALTY_VALUE, "LibAsset: invalid royalty value");
        }
    }

    function getCurrency(Asset memory asset) internal pure returns (address) {
        return (asset.assetType == AssetType.ETH) ? address(0) : asset.token;
    }

    function permit(
        Asset memory asset,
        bytes memory permitSig,
        address from
    ) internal {
        if (asset.assetType == AssetType.ERC20) {
            SignatureERC20 memory signature = abi.decode(permitSig, (SignatureERC20));
            IERC20Permit(asset.token).permit(
                from,
                address(this),
                signature.amount,
                signature.deadline,
                signature.sig.v,
                signature.sig.r,
                signature.sig.s
            );
        } else if (asset.assetType == AssetType.ERC721) {
            SignatureERC721 memory signature = abi.decode(permitSig, (SignatureERC721));
            if (signature.forAll) {
                IERC721Permit(asset.token).permitAll(
                    from,
                    address(this),
                    signature.deadline,
                    signature.sig.v,
                    signature.sig.r,
                    signature.sig.s
                );
            } else {
                IERC721Permit(asset.token).permit(
                    from,
                    address(this),
                    signature.tokenId,
                    signature.deadline,
                    signature.sig.v,
                    signature.sig.r,
                    signature.sig.s
                );
            }
        } else {
            SignatureERC1155 memory signature = abi.decode(permitSig, (SignatureERC1155));
            IERC1155Permit(asset.token).permit(
                from,
                address(this),
                signature.deadline,
                signature.sig.v,
                signature.sig.r,
                signature.sig.s
            );
        }
    }

    function transfer(
        Asset memory asset,
        address from,
        address to
    ) internal {
        if (asset.assetType == AssetType.ERC20) {
            IERC20Permit(asset.token).safeTransferFrom(from, to, asset.amount);
        } else if (asset.assetType == AssetType.ERC721) {
            IERC721Permit(asset.token).safeTransferFrom(from, to, asset.id);
        } else if (asset.assetType == AssetType.ERC1155) {
            IERC1155Permit(asset.token).safeTransferFrom(from, to, asset.id, asset.amount, "");
        } else {
            payable(to).send(asset.amount);
        }
    }

    function permitTransfer(
        Asset memory asset,
        bytes memory permitSig,
        address from,
        address to
    ) internal {
        if (permitSig.length != 0) {
            permit(asset, permitSig, from);
        }
        transfer(asset, from, to);
    }
}
