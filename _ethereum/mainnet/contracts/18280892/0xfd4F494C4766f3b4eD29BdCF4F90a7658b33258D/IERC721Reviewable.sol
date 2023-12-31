// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title ERC721Reviewable - Interface
 * @author YUMEMI inc. - akibe & iizumi
 */

interface IERC721Reviewable is IERC721 {
    /**
     * @dev Emitted when post review from `reviewer`
     */
    event ReviewContract(address indexed reviewer, uint256 indexed reviewId);
    event ReviewToken(
        address indexed reviewer,
        uint256 indexed reviewId,
        uint256 indexed tokenId
    );

    /**
     * @dev Returns the total amount of reviews for token.
     */
    function totalReviewsOfToken(
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * @dev Returns the total amount of reviews for contract.
     */
    function totalReviewsOfContract() external view returns (uint256);

    /**
     * @dev post review for token
     */
    function postReviewOfToken(
        uint256 tokenId,
        string memory reviewURI
    ) external returns (uint256);

    /**
     * @dev get review id by index of token reviews
     */
    function reviewOfTokenByIndex(
        uint256 tokenId,
        uint256 index
    ) external view returns (uint256);

    /**
     * @dev post review for contract
     */
    function postReviewOfContract(
        string memory reviewURI
    ) external returns (uint256);

    /**
     * @dev get review id by index of contract reviews
     */
    function reviewOfContractByIndex(
        uint256 index
    ) external view returns (uint256);

    /**
     * @dev Get reviewURI from reviewId
     */
    function reviewURI(uint256 reviewId) external view returns (string memory);
}
