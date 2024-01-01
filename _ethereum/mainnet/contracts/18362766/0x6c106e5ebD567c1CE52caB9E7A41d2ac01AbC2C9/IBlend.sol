// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Lien {
    address lender;
    address borrower;
    address collection;
    uint256 tokenId;
    uint256 amount;
    uint256 startTime;
    uint256 rate;
    uint256 auctionStartBlock;
    uint256 auctionDuration;
}

struct LienPointer {
    Lien lien;
    uint256 lienId;
}

interface IBlend {
    /**
     * @notice Starts Dutch Auction on lien ownership
     * @dev Must be called by lien owner
     * @param lienId Lien token id
     */
    function startAuction(Lien calldata lien, uint256 lienId) external;

    /**
     * @notice Seizes collateral from defaulted lien, skipping liens that are not defaulted
     * @param lienPointers List of lien, lienId pairs
     */
    function seize(LienPointer[] calldata lienPointers) external;

    /**
     * @notice Refinance lien in auction at the current debt amount where the interest rate ceiling increases over time
     * @dev Interest rate must be lower than the interest rate ceiling
     * @param lien Lien struct
     * @param lienId Lien token id
     * @param rate Interest rate (in bips)
     * @dev Formula: https://www.desmos.com/calculator/urasr71dhb
     */
    function refinanceAuction(Lien calldata lien, uint256 lienId, uint256 rate) external;
}
