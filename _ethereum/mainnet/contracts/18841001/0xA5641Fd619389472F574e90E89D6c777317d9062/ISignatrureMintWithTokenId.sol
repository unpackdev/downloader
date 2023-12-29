// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

struct MintRequest {
    address userAddress;
    uint256 tokenId;
    uint256 nftPrice;
    address paymentToken;
    uint128 validityStartTimestamp;
    uint128 validityEndTimestamp;
    uint256 totalSupply;
}

struct MintOperation {
    MintRequest requst;
    bytes sig;
}




interface ISignatrureMintWithTokenId {
    
    event TokensMintedWithSignature(
        address indexed signer,
        address indexed mintedTo,
        uint256 indexed tokenIdMinted,
        MintRequest mintRequest
    );

    function verify(
        MintRequest calldata req,
        bytes calldata signature
    ) external view returns (bool success, address signer);

    function mint(
        MintRequest calldata req,
        bytes calldata signature
    ) external payable returns (address signer);
}
