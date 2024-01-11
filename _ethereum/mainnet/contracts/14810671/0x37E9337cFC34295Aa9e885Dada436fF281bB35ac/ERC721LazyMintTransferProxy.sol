/*
                     ..........
                 .(MMMMMMMMMMMMMMa,.
              .(MMMMMMMMMMMMMMMMMMMMN,
            .+MMMMMMMMMMMMMMMMMMMMMMMMN,
           .MMMMMMMMMMMMMMMMMMMMMMMMMMMMb
          .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMh
         .MMMMMMMF TMMMMMMMMMMMMF`   ?MMMMb
         MMMMMMMa, .+MMMMMMMMMM#      ,MMMM,
        .MMMMMMMMMgMMMMMMMMMMMMN,     .MMMM]
        ,MMMMMMMMMMMMMMMMMMMMMB^ .J.JMMMMMMF
       .MMMMMMMMMMMMMMMMMMM#=  .JMMMMMMMMMMF
     .JMMMMMMMMMMMMMMMMMB=   .(MMMMMMMMMMMM>
     MMMMMMMMMMMMMMM#"!    .JMMMMMMMMMMMMMF
    ,MMMMMMMMMMMB"`      .dMMMMMM9`7MMMMM#
     .""""""!         .(MMMMMMMMMMaMMMMM@
                   ..MMMMMMMMMMMMMMMMMM3
                .&MMMMMMMMMMMMMMMMMMM"
                 ?YMMMMMMMMMMMMMM#"`
                     _7"""""""!
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721LazyMint.sol";
import "./MintERC721Lib.sol";
import "./SecurityLib.sol";
import "./OperatorControllerUpgradeable.sol";
import "./ITransferProxy.sol";

/**
 * @title Transfer proxy for NFT on Recomet.
 */
contract ERC721LazyMintTransferProxy is
    OperatorControllerUpgradeable,
    ITransferProxy
{
    function __ERC721LazyMintTransferProxy_init(address account)
        external
        initializer
    {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __OperatorController_init_unchained(account);
    }

    function transfer(
        AssetLib.AssetData memory asset,
        address from,
        address to
    ) external override onlyOperator {
        (bool isValid, string memory errorMessage) = _validate(asset, from, to);
        require(isValid, errorMessage);
        (
            address token,
            MintERC721Lib.MintERC721Data memory mintERC721Data,
            SignatureLib.SignatureData memory signatureData
        ) = _decodeAssetTypeData(asset);
        IERC721LazyMint(token).lazyMint(mintERC721Data, signatureData);
    }

    function _decodeAssetTypeData(AssetLib.AssetData memory asset)
        private
        pure
        returns (
            address,
            MintERC721Lib.MintERC721Data memory,
            SignatureLib.SignatureData memory
        )
    {
        (
            address token,
            MintERC721Lib.MintERC721Data memory mintERC721Data,
            SignatureLib.SignatureData memory signatureData
        ) = abi.decode(
                asset.assetType.data,
                (
                    address,
                    MintERC721Lib.MintERC721Data,
                    SignatureLib.SignatureData
                )
            );
        return (token, mintERC721Data, signatureData);
    }

    function _validate(
        AssetLib.AssetData memory asset,
        address from,
        address to
    ) private pure returns (bool, string memory) {
        (
            ,
            MintERC721Lib.MintERC721Data memory mintERC721Data,

        ) = _decodeAssetTypeData(asset);
        if (from == address(0) || from != mintERC721Data.minter) {
            return (
                false,
                "ERC721LazyMintTransferProxy: from verification failed"
            );
        } else if (to == address(0)) {
            return (
                false,
                "ERC721LazyMintTransferProxy: to verification failed"
            );
        }
        return (true, "");
    }

    uint256[50] private __gap;
}
