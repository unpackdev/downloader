// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./PartLib.sol";

library ERC1155LazyMintLib {
    struct ERC1155LazyMintData {
        uint tokenId;
        string tokenURI;
        uint supply;
        PartLib.PartData[] creators;
        PartLib.PartData[] royalties;
        bytes[] signatures;
    }

    bytes32 public constant MINT_AND_TRANSFER_TYPEHASH = keccak256("Mint1155(uint256 tokenId,uint256 supply,string tokenURI,PartData[] creators,PartData[] royalties)PartData(address account,uint96 value)");

    function hash(ERC1155LazyMintData memory data) internal pure returns (bytes32) {
        bytes32[] memory royaltiesBytes = new bytes32[](data.royalties.length);
        for (uint i = 0; i < data.royalties.length; i++) {
            royaltiesBytes[i] = PartLib.hash(data.royalties[i]);
        }
        bytes32[] memory creatorsBytes = new bytes32[](data.creators.length);
        for (uint i = 0; i < data.creators.length; i++) {
            creatorsBytes[i] = PartLib.hash(data.creators[i]);
        }
        return keccak256(
            abi.encode(
                MINT_AND_TRANSFER_TYPEHASH,
                data.tokenId,
                data.supply,
                keccak256(bytes(data.tokenURI)),
                keccak256(abi.encodePacked(creatorsBytes)),
                keccak256(abi.encodePacked(royaltiesBytes))
            )
        );
    }
}