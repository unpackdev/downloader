// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

interface iIsekaiImoutoNFT {
    
    event AddSaleRound(
        string merkleTreeCid,
        uint256 startAt,
        uint256 endAt
    );

    struct SaleRound {
        uint256 startAt;
        uint256 endAt;
    }

    function getCurrentRoundStartDate() external view returns(uint256);

    function getCurrentRoundEndDate() external view returns(uint256);
    
    function addSaleRound(
        string calldata merkleTreeCid,
        bytes32 merkleRoot,
        uint256 startAt,
        uint256 endAt
    ) external;

    function withdrawETH() external;

    function buy(
        uint256 index,
        address account,
        uint256 tokenId,
        bytes32[] calldata merkleProof
    ) external payable;

    function mint(uint256 tokenId) external;

    function batchMint(uint256[] calldata tokenIdList) external;
}

