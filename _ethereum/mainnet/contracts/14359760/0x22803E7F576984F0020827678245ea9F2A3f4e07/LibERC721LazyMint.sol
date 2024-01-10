// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./LibPart.sol";

library LibERC721LazyMint {
    bytes4 constant public ERC721_LAZY_ASSET_CLASS = bytes4(keccak256("ERC721_LAZY"));
    bytes4 constant _INTERFACE_ID_MINT_AND_TRANSFER = 0x8486f69f;

    struct Mint721Data {
        string tokenURI;
        LibPart.Part[] royalties;
    }

    bytes32 public constant MINT_AND_TRANSFER_TYPEHASH = keccak256("Mint721(string tokenURI,Part[] royalties)Part(address account,uint96 value)");

    function hash(Mint721Data memory data) internal pure returns (bytes32) {
        bytes32[] memory royaltiesBytes = new bytes32[](data.royalties.length);
        for (uint i = 0; i < data.royalties.length; i++) {
            royaltiesBytes[i] = LibPart.hash(data.royalties[i]);
        }
        return keccak256(abi.encode(
                MINT_AND_TRANSFER_TYPEHASH,
                keccak256(bytes(data.tokenURI)),
                keccak256(abi.encodePacked(royaltiesBytes))
            ));
    }

}