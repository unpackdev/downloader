// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "./IERC721.sol";

interface IERC721Autentica is IERC721 {
    /**
     * @dev Number of decimals used for fees.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the Royalty fee of the `tokenId` token.
     * @param tokenId NFT ID.
     */
    function getRoyaltyFee(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Returns the Investor fee of the `tokenId` token.
     * @param tokenId NFT ID.
     */
    function getInvestorFee(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Returns the creator of the `tokenId` token.
     * @param tokenId NFT ID.
     *
     * NOTE: The Autentica Marketplace smart contract supports royalties, so in order for the
     * creator to be paid, we need to know who created the token and that information must
     * stay the same even if the person who owns the token changes.
     */
    function getCreator(uint256 tokenId) external view returns (address);

    /**
     * @dev Returns the investor of the `tokenId` token.
     * @param tokenId NFT ID.
     *
     * NOTE: Autentica lets other people to pay for the gas fees of the token minting so
     * in that case the minter is not the creator and owner of the token.
     */
    function getInvestor(uint256 tokenId) external view returns (address);
}
