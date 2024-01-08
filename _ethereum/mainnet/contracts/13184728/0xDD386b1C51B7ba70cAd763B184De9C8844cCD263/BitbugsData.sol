// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./Counters.sol";

/**
 *  @title BitbugsData
 *  @author Ladera Software Studio
 *  @notice This contract implements some Bitbugs NFT data
 *  @dev All function calls are currently implemented without side effects
 */
contract BitbugsData is Ownable {

    using Counters for Counters.Counter;

    /**
     *  @dev Counter to track number of (minted) bitbugs.
     *  Note: Initial value is 0, so range is [0,TOKEN_LIMIT).
     */
    Counters.Counter internal bitbugIdTracker;

    /**
     *  @dev Counter to track number of (minted) bitbugs by owner.
     */
    Counters.Counter internal devMintTracker;

    /**
     *  @dev Dynamic array to keep track of minted BitbugIds. 
     *  Note: Maximum Range [0,TOKEN_LIMIT) & TOKEN_LIMIT positions.
     */
    uint[] internal mintedBitbugs;


    /**
     * @dev Function to query minted bitbugs' tokenIds.
     * Required to mint bitbugs.
     * Note that ERC721Enumerable module does not return _allTokens array, only its length.
     */
    function getMintedBitbugs() public view returns(uint[] memory)
    {
	return mintedBitbugs;
    }

    
    /**
     * @dev Function to query number of (minted) bitbugs.
     */
    function getTokenIdTracker() public view onlyOwner returns (uint) {
	return bitbugIdTracker.current();
    }

    
    /**
     * @dev Function to query number of (minted) bitbugs of the owner.
     */
    function getdevIdTracker() public view onlyOwner returns (uint) {
	return devMintTracker.current();
    }

}
