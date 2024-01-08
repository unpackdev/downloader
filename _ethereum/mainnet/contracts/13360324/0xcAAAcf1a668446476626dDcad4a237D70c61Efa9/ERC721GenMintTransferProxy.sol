// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;
pragma abicoder v2;

import "./ITransferProxy.sol";
import "./IERC721GenMint.sol";
import "./OperatorRole.sol";

//transfer proxy that is going to mint tokens (operator proxy)
contract ERC721GenMintTransferProxy is ITransferProxy, OperatorRole {
    function transfer(LibAsset.Asset memory asset, address from, address to) external override {
        address token = abi.decode(asset.assetType.data, (address));
        IERC721GenMint(token).mint(from, to, asset.value);
    }
}
