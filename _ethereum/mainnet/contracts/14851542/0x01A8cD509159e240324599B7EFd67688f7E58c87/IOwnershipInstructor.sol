//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * This is an interface of OwnershipInstructor
 * The goal of this contract is to allow people to integrate their contract into OwnershipChecker.sol
 * by generalising the obtention of the owner of NFTs.
 * The reason for this solution was because NFTs nowadays have standards, but not all NFTs support these standards.
 * The interface id for this is 0xb0f6fd7f;
 */
interface IOwnershipInstructor{

/**
 * isValidInterface()
 * This function should be public and should be overriden.
 * It should obtain an address as input and should return a boolean value;
 * A positive result means the given address supports your contract's interface.
 * @dev This should be overriden and replaced with a set of instructions to check the given _impl if your contract's interface.
 * See ERC165 for help on interface support.
 * @param _impl address we want to check.
 * @return bool
 * 
 */
  function isValidInterface (address _impl) external view returns (bool);

    /**
    * This function should be public or External and should be overriden.
    * It should obtain an address as implementation, a uint256 token Id and an optional _potentialOwner;
    * It should return an address (or address zero is no owner);
    * @dev This should be overriden and replaced with a set of instructions obtaining the owner of the given tokenId;
    *
    * @param _tokenId token id we want to grab the owner of.
    * @param _impl Address of the NFT contract
    * @param _potentialOwner (OPTIONAL) A potential owner, set address zero if no potentialOwner; Necessary for ERC1155
    * @return a non zero address if the given tokenId has an owner; else if the token Id does not exist or has no owner, return zero address
    * 
    */
    function ownerOfTokenOnImplementation(address _impl,uint256 _tokenId,address _potentialOwner) external view  returns (address);
}