/* Copyright (C) 2021 NexusMutual.io
  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.7.5;
import "./IERC721.sol";
import "./Ownable.sol";
interface IDistributor is IERC721{
  enum ClaimStatus { IN_PROGRESS, ACCEPTED, REJECTED }

  event ClaimPayoutRedeemed (
    uint indexed coverId,
    uint indexed claimId,
    address indexed receiver,
    uint amountPaid,
    address coverAsset
  );

  event ClaimSubmitted (
    uint indexed coverId,
    uint indexed claimId,
    address indexed submitter
  );

  event CoverBought (
    uint indexed coverId,
    address indexed buyer,
    address indexed contractAddress,
    uint feePercentage,
    uint coverPrice
  );


  function buyCover (
    address contractAddress,
    address coverAsset,
    uint sumAssured,
    uint16 coverPeriod,
    uint8 coverType,
    uint maxPriceWithFee,
    bytes calldata data
  )
    external
    payable
    returns (uint);


  function submitClaim(
    uint tokenId,
    bytes calldata data
  )
    external
    
    returns (uint);
  
  function redeemClaim(
    uint256 tokenId,
    uint claimId
  )
    external;

 
  function executeCoverAction(uint tokenId, uint assetAmount, address asset, uint8 action, bytes calldata data)
    external
    payable
  returns (bytes memory response, uint withheldAmount);

  function getCover(uint tokenId)
  external
  view
  returns (
    uint8 status,
    uint sumAssured,
    uint16 coverPeriod,
    uint validUntil,
    address contractAddress,
    address coverAsset,
    uint premiumInNXM,
    address memberAddress
  );

  function getPayoutOutcome(uint claimId)
  external
  view
  returns (ClaimStatus status, uint amountPaid, address coverAsset);
  
  function approveNXM(address spender, uint256 amount) external; 

  function withdrawNXM(address recipient, uint256 amount) external; 
 
  function switchMembership(address newAddress) external ;

  function sellNXM(uint nxmIn, uint minEthOut) external;
 
  function setBuysAllowed(bool _buysAllowed) external;
  
  function setTreasury(address payable _treasury) external;

  function setFeePercentage(uint _feePercentage) external;

  // function ownerOf(uint256 tokenId) external override view returns (address);
  // function isApprovedForAll(address owner, address operator) external override view returns (bool);
  function owner() external view returns (address);
  function transferOwnership(address newOwner) external;

}