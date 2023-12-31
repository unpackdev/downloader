// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./D4AStructs.sol";

interface ID4AProtocol {
    event NewProject(
        bytes32 daoId, string daoUri, address daoFeePool, address token, address nft, uint256 royaltyFeeRatioInBps
    );

    event NewCanvas(bytes32 daoId, bytes32 canvasId, string canvasUri);

    event D4AMintNFT(bytes32 daoId, bytes32 canvasId, uint256 tokenId, string tokenUri, uint256 price);

    event D4AClaimProjectERC20Reward(bytes32 daoId, address token, uint256 amount);

    event D4AClaimCanvasReward(bytes32 daoId, bytes32 canvasId, address token, uint256 amount);

    event D4AClaimNftMinterReward(bytes32 daoId, address token, uint256 amount);

    event D4AExchangeERC20ToERC20(
        bytes32 daoId, address owner, address to, address grantToken, uint256 tokenAmount, uint256 grantTokenAmount
    );

    event D4AExchangeERC20ToETH(bytes32 daoId, address owner, address to, uint256 tokenAmount, uint256 ethAmount);

    function initialize() external;

    function createProject(
        uint256 startRound,
        uint256 mintableRound,
        uint256 daoFloorPriceRank,
        uint256 maxNftRank,
        uint96 royaltyFeeRatioInBps,
        string memory daoUri
    )
        external
        payable
        returns (bytes32 daoId);

    function createOwnerProject(DaoMetadataParam calldata daoMetadata) external payable returns (bytes32 daoId);

    function createCanvas(
        bytes32 daoId,
        string calldata canvasUri,
        bytes32[] calldata proof,
        uint256 canvasRebateRatioInBps
    )
        external
        payable
        returns (bytes32);

    function mintNFT(
        bytes32 daoId,
        bytes32 canvasId,
        string calldata tokenUri,
        bytes32[] calldata proof,
        uint256 nftFlatPrice,
        bytes calldata signature
    )
        external
        payable
        returns (uint256);

    function batchMint(
        bytes32 daoId,
        bytes32 canvasId,
        bytes32[] calldata proof,
        MintNftInfo[] calldata mintNftInfos,
        bytes[] calldata signatures
    )
        external
        payable
        returns (uint256[] memory);

    function claimProjectERC20Reward(bytes32 daoId) external returns (uint256);

    function claimCanvasReward(bytes32 canvasId) external returns (uint256);

    function claimNftMinterReward(bytes32 daoId, address minter) external returns (uint256);

    function exchangeERC20ToETH(bytes32 daoId, uint256 amount, address to) external returns (uint256);

    function getNFTTokenCanvas(bytes32 daoId, uint256 tokenId) external view returns (bytes32);
}
