// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./IRoyaltyInfo.sol";
import "./IGetRoyalties.sol";
import "./IRoyaltyRegistry.sol";
import "./IGetFees.sol";
import "./ITokenCreator.sol";
import "./IOwnable.sol";
import "./Constants.sol";
import "./ERC165Checks.sol";

/**
 * @dev Contract module which offers robust royalty retrieving capabilities to implementers.
 * @dev Royalty awareness implies knowing how to retrieve royalties for a given NFT.
 *
 * @dev There are multiple methods to retrieve NFT royalties, defined by various marketplaces.
 */
abstract contract RoyaltiesAware {
  using ERC165Checks for address;

  IRoyaltyRegistry private immutable _royaltyRegistry =
    IRoyaltyRegistry(0xaD2184FB5DBcfC05d8f056542fB25b04fa32A95D);

  /**
   * @dev We try different ways of retrieving royalties, in this order:
   * @dev   1. EIP-2981 royalty standard
   * @dev   2. Royalties interface for Manifold
   * todo: WIP
   */
  function _getNFTRoyalties(
    address nftContractAddress,
    uint256 tokenId
  )
    internal
    view
    returns (address payable[] memory creators, uint256[] memory creatorsBps)
  {
    // Priority 1: EIP-2981 royalty standard
    if (
      nftContractAddress.supportsERC165InterfaceUnchecked(
        type(IRoyaltyInfo).interfaceId
      )
    ) {
      // we don't have access to the price here, but we can calculate the desired creator bps by passing the 10_000 constant
      try
        IRoyaltyInfo(nftContractAddress).royaltyInfo{gas: 40_000}(
          tokenId,
          10_000
        )
      returns (address receiver, uint256 royaltyAmount) {
        // Ignore this result when royaltyAmount is 0
        if (royaltyAmount > 0) {
          creators = new address payable[](1);
          creators[0] = payable(receiver);
          creatorsBps = new uint256[](1);
          creatorsBps[0] = royaltyAmount;
          return (creators, creatorsBps);
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }
    }

    // Priority 2: Royalties interface for Manifold (also supported by Exchange contracts)
    if (
      nftContractAddress.supportsERC165InterfaceUnchecked(
        type(IGetRoyalties).interfaceId
      )
    ) {
      try
        IGetRoyalties(nftContractAddress).getRoyalties{gas: 40_000}(tokenId)
      returns (
        address payable[] memory _recipients,
        uint256[] memory recipientsBasisPoints
      ) {
        if (
          _recipients.length != 0 &&
          _recipients.length == recipientsBasisPoints.length
        ) {
          return (_recipients, recipientsBasisPoints);
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }
    }

    // Next in order of priorities, try to use the Royalty Registry (https://royaltyregistry.xyz/lookup)
    try
      _royaltyRegistry.getRoyaltyLookupAddress{gas: 40_000}(nftContractAddress)
    returns (address overrideContract) {
      if (overrideContract != nftContractAddress) {
        nftContractAddress = overrideContract;
        // Priority 3: EIP-2981 royalty standard via Royalty Registry
        if (
          nftContractAddress.supportsERC165InterfaceUnchecked(
            type(IRoyaltyInfo).interfaceId
          )
        ) {
          // we don't have access to the price here, but we can calculate the desired creator bps by passing the 10_000 constant
          try
            IRoyaltyInfo(nftContractAddress).royaltyInfo{gas: 40_000}(
              tokenId,
              10_000
            )
          returns (address receiver, uint256 royaltyAmount) {
            // Ignore this result when royaltyAmount is 0
            if (royaltyAmount > 0) {
              creators = new address payable[](1);
              creators[0] = payable(receiver);
              creatorsBps = new uint256[](1);
              creatorsBps[0] = royaltyAmount;
              return (creators, creatorsBps);
            }
          } catch // solhint-disable-next-line no-empty-blocks
          {
            // Fall through
          }
        }

        // Priority 4: Royalties interface for Manifold via Royalty Registry
        if (
          nftContractAddress.supportsERC165InterfaceUnchecked(
            type(IGetRoyalties).interfaceId
          )
        ) {
          try
            IGetRoyalties(nftContractAddress).getRoyalties{gas: 40_000}(tokenId)
          returns (
            address payable[] memory _recipients,
            uint256[] memory recipientsBasisPoints
          ) {
            if (
              _recipients.length != 0 &&
              _recipients.length == recipientsBasisPoints.length
            ) {
              return (_recipients, recipientsBasisPoints);
            }
          } catch // solhint-disable-next-line no-empty-blocks
          {
            // Fall through
          }
        }
      }
    } catch // solhint-disable-next-line no-empty-blocks
    {
      // Ignore out of gas errors and continue using the nftContract address
    }

    // Priority 5: getFee* from contract or override
    if (
      nftContractAddress.supportsERC165InterfaceUnchecked(
        type(IGetFees).interfaceId
      )
    ) {
      try
        IGetFees(nftContractAddress).getFeeRecipients{gas: 40_000}(tokenId)
      returns (address payable[] memory _recipients) {
        if (_recipients.length != 0) {
          try
            IGetFees(nftContractAddress).getFeeBps{gas: 40_000}(tokenId)
          returns (uint256[] memory recipientBasisPoints) {
            if (_recipients.length == recipientBasisPoints.length) {
              return (_recipients, recipientBasisPoints);
            }
          } catch // solhint-disable-next-line no-empty-blocks
          {
            // Fall through
          }
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }
    }

    // At this point, all efforts failed, so try to get the sole creator of the NFT collection, and pay him a 10% royalty
    // Priority 6: tokenCreator w/ or w/o requiring 165 from contract or override
    try
      ITokenCreator(nftContractAddress).tokenCreator{gas: 40_000}(tokenId)
    returns (address payable _creator) {
      if (_creator != address(0)) {
        // Only pay the tokenCreator if there wasn't another royalty defined
        creators = new address payable[](1);
        creators[0] = _creator;
        creatorsBps = new uint256[](1);
        creatorsBps[0] = 1_000;
        return (creators, creatorsBps);
      }
    } catch // solhint-disable-next-line no-empty-blocks
    {
      // Fall through
    }

    // Priority 7: contractOwner w/ or w/o requiring 165 from contract or override
    try IOwnable(nftContractAddress).owner{gas: 40_000}() returns (
      address owner
    ) {
      if (owner != address(0)) {
        // Only pay the owner if there wasn't another royalty defined
        creators = new address payable[](1);
        creators[0] = payable(owner);
        creatorsBps = new uint256[](1);
        creatorsBps[0] = 1_000;
        return (creators, creatorsBps);
      }
    } catch // solhint-disable-next-line no-empty-blocks
    {
      // Fall through
    }

    // If no valid payment address or creator is found, return 0 recipients
  }
}
