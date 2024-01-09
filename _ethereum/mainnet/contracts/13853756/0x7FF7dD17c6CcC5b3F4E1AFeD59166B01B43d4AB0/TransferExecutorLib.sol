// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./PartLib.sol";
import "./ERC1155LazyMintLib.sol";

library TransferExecutorLib {
    struct TransferExecutorData {
        ERC1155LazyMintLib.ERC1155LazyMintData data;
        address token;
        address from;
        address to;
        uint256 value;
        uint256 salt;
        bytes signature;
    }

    bytes32 public constant TRANSFER_EXECUTOR_TYPEHASH = keccak256("TransferExecutor(Mint1155 data,address token,address from,address to,uint256 value,uint256 salt)Mint1155(uint256 tokenId,uint256 supply,string tokenURI,PartData[] creators,PartData[] royalties)PartData(address account,uint96 value)");

    function hash(TransferExecutorData memory transfer) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                TRANSFER_EXECUTOR_TYPEHASH,
                ERC1155LazyMintLib.hash(transfer.data),
                transfer.token,
                transfer.from,
                transfer.to,
                transfer.value,
                transfer.salt
            )
        );
    }
}