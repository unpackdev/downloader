// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Structs.sol";

interface IKettleV2 {

    event Loan(
        bytes32 offerHash,
        uint256 lienId,
        address lender,
        address borrower,
        uint8 collateralType,
        address collection,
        uint256 tokenId,
        uint256 size,
        address currency,
        uint256 amount,
        uint256 rate,
        uint256 duration,
        uint256 startTime,
        Fee[] fees
    );

    function borrow(
        LoanOffer calldata offer,
        OfferAuth calldata auth,
        bytes calldata offerSignature,
        bytes calldata authSignature,
        uint256 amount,
        uint256 tokenId,
        address borrower,
        bytes32[] calldata proof
    ) external;

    function repay(
        Lien calldata lien,
        uint256 lienId
    ) external;

  function nonces(address) external view returns (uint256);

  function getLoanOfferHash(LoanOffer calldata loanOffer) external view returns (bytes32);
}
