// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Structs.sol";

interface IKettleV1 {

    event LoanOfferTaken(
        bytes32 offerHash,
        uint256 lienId,
        address lender,
        address borrower,
        address currency,
        uint8 collateralType,
        address collection,
        uint256 tokenId,
        uint256 amount,
        uint256 borrowAmount,
        uint256 netBorrowAmount,
        uint256 rate,
        uint256 duration,
        uint256 startTime
    );

    function borrow(
        LoanOffer calldata offer,
        OfferAuth calldata auth,
        bytes calldata offerSignature,
        bytes calldata authSignature,
        uint256 loanAmount,
        uint256 collateralTokenId,
        address borrower,
        bytes32[] calldata proof
    ) external;

    function repay(
        Lien calldata lien,
        uint256 lienId
    ) external;

    function getRepaymentAmount(
        uint256 borrowAmount,
        uint256 rate,
        uint256 duration
    ) external pure returns (uint256);

    function liens(uint256) external view returns (bytes32);

    function nonces(address) external view returns (uint256);

    function getLoanOfferHash(LoanOffer calldata loanOffer) external view returns (bytes32);
}
