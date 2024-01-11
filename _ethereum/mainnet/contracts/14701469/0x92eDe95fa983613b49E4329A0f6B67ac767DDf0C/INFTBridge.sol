// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface INFTBridge {
    /* ========== STRUCT ========== */

    struct ChainInfo {
        bool isSupported;
        bytes nftBridgeAddress;
    }

    struct BridgeNFTInfo {
        uint256 nativeChainId;
        address tokenAddress; // asset address on the current chain
        bool exist;
    }

    struct NativeNFTInfo {
        uint256 chainId; // native chainId
        bytes tokenAddress; //native token address
        uint256 tokenType;
        string name;
        string symbol;
    }

    /* ========== ERRORS ========== */

    error AdminBadRole();
    error CallProxyBadRole();
    error NativeSenderBadRole(bytes nativeSender, uint256 chainIdFrom);

    error WrongArgument();
    error ZeroAddress();
    error ChainToIsNotSupported();
    error AssetAlreadyExist();

    error DebridgeTokenInfoNotFound();
    error MessageValueDoesNotMatchRequiredFee();
    error TokenMustImplementIERC721Metadata();

    error NotReceivedERC721();

    /* ========== EVENTS ========== */

    event AddedChainSupport(bytes bridgeAddress, uint256 chainId);
    event RemovedChainSupport(uint256 chainId);

    event NFTContractAdded(
        bytes32 debridgeId,
        address tokenAddress,
        bytes nativeAddress,
        uint256 nativeChainId,
        string name,
        string sybmol,
        uint256 tokenType
    );

    event NFTSent(
        address tokenAddress, // token address in the current chain
        uint256 tokenId,
        bytes receiver,
        uint256 chainIdTo,
        uint256 nonce
    );

    event NFTClaimed(
        address tokenAddress, // native token address in the current chain
        uint256 tokenId,
        address receiver
    );

    event NFTMinted(
        address tokenAddress, // token address in the current chain
        uint256 tokenId,
        address receiver,
        string tokenUri
    );
}
