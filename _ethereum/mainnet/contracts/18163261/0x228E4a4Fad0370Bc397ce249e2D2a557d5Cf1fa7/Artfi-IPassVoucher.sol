//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ArtfiIPassVoucherV2 {
    struct NftData {
        string uri;
        bool unclaimed;
        address tokenAddress;
    }

    struct NftAttributes {
    bool unclaimed;
    bool airDrop;
    bool ieo;
    string image;
    string certificate;
}

    struct MintData {
        string uri;
        bool unclaimed;
        address tokenAddress;
        address seller;
        address buyer;
    }

    struct BridgeData {
    address buyer;
    address otherTokenAddress;
    string uri;
    bool locked;
}

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function isWhiteListed(address caller_) external view returns (bool);

    function isQuantityAllowed(uint256 quantity) external view returns (bool);

    function isArtfiCollectionContract() external pure returns (bool);

    function getNftInfo(
        uint256 tokenId_
    ) external view returns (NftData memory nfts_);

    function getTokenAttributes(
        uint256 tokenId_
    )
        external
        view
        returns (
            bool _unclaimed,
            bool _airDrop,
            bool _ieo,
            string memory _certificate
        );

    function getUnclaimedTokens(
        uint256 tokenId_
    ) external view returns (bool _unclaimed);

    function getRemaining() external view returns (uint256 remaining_);

    function updateAttributes(
        uint256 tokenId_,
        bool unclaimed_,
        bool airDrop_,
        bool ieo_
    ) external;

    function updateUnclaimedAttributes(
        uint256 tokenId_,
        bool unclaimed_
    ) external;

    function updateTokenURI(
        uint256 tokenId_,
        string memory uri_
    ) external;

    // function bridgeNft(
    //     uint256 tokenId_,
    //     address otherTokenAddress,
    //     address owner
    // ) external;

    // function adminMintBridge(
    //     BridgeData memory bridgeData_
    // ) external returns (uint256 tokenId_);

    function mint(
        MintData memory mintData_
    ) external returns (uint256 tokenId_);

    function transferNft(address from_, address to_, uint256 tokenId_) external;
}
