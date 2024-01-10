// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface INFT721Bridge {
    struct NFT721FeeInfo {
        uint256 feeAmount;  // gasPrice * gasLimit
        uint256 volatilityCoefficient;  // uint: 0.01, %
    }
    
    event NFT721TokenAdded(
        address indexed token
    );

    event NFT721FeeUpdated(
        address indexed token,
        uint256 feeAmount, 
        uint256 volatilityCoefficient
    );

    event NFT721TokenRemoved(
        address indexed token
    );

    event NFT721Attached(
        address indexed token,
        address account,
        uint256 tokenId
    );

    event NFT721AttachedBatch(
        address indexed token,
        address account,
        uint256[] tokenId
    );

    event NFT721Detached(
        address indexed token,
        address account,
        uint256 tokenId
    );

    event NFT721DetachedBatch(
        address indexed token,
        address account,
        uint256[] tokenId
    );

    function addNFT721Token(address token, NFT721FeeInfo memory feeInfo) external;

    function updateNFT721TokenFee(address token, NFT721FeeInfo memory feeInfo) external;

    function removeNFT721Token(address token) external;

    function estimateFee(address token) external returns (uint256);

    function estimateFee(address token, uint256 amount) external returns (uint256);

    function attachNFT721(address token, uint256 tokenId) external payable;

    function attachNFT721Batch(address token, uint256[] memory tokenId) external payable;

    function detachNFT721(address token, address to, uint256 tokenId) external;
    
    function detachNFT721Batch(address token, address to, uint256[] memory tokenIds) external;

    function emergencyWithdrawNFT(address token, uint256 tokenId) external;

    function withdrawFee(address settler) external;
}