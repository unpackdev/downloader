// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMNFTRoyaltyManager {
   function updateGlobalRoyalty(uint16 royalty_) external;

   function setUserRoyalty(
      address setter_,
      address tokenAddress_,
      uint16 royalty_
   ) external;

   function getRoyaltyFee(
      address tokenAddress_,
      uint256 amount_
   ) external view returns(address receiver, uint256 globalFee, uint256 userFee);
}