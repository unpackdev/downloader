// SPDX-License-Identifier: MIT

/**
*   @title LIT Project One VRF
*   @author Transient Labs, LLC
*   @notice Contract to perform VRF for copyright of Survive All Apocalypses
*   Copyright (C) 2021 Transient Labs
*/

/*
 #######                                                      #                            
    #    #####    ##   #    #  ####  # ###### #    # #####    #         ##   #####   ####  
    #    #    #  #  #  ##   # #      # #      ##   #   #      #        #  #  #    # #      
    #    #    # #    # # #  #  ####  # #####  # #  #   #      #       #    # #####   ####  
    #    #####  ###### #  # #      # # #      #  # #   #      #       ###### #    #      # 
    #    #   #  #    # #   ## #    # # #      #   ##   #      #       #    # #    # #    # 
    #    #    # #    # #    #  ####  # ###### #    #   #      ####### #    # #####   #### 
    
0101010011100101100000110111011100101101000110010011011101110100 01001100110000011000101110011 
*/

pragma solidity ^0.8.0;

import "Ownable.sol";
import "SafeMath.sol";
import "VRFConsumerBase.sol";

contract ProjectOneVRF is VRFConsumerBase, Ownable {

    using SafeMath for uint256;

    bytes32 private randomRequestId;
    bool private randomReceived;
    uint256 private randomResult;
    bool private raffleComplete;
    bool private revealTokenId;
    uint256 private randomTokenId;

    event randomnessReceived();

    /**
    *   @notice constructor for contract
    *   @dev contract deployer becomes the contract owner
    *   @param _vrfCoordinator is the address for vrf coordinator on Ethereum.
    *   @param _link is the address for the LINK ERC20 token on Ethereum
    */
    constructor(address _vrfCoordinator, address _link) VRFConsumerBase(_vrfCoordinator, _link) Ownable() {}
    
    /**
    *   @notice function to request randomness from Chainlink VRF
    *   @dev requires owner to call the function 
    *   @dev a wrapper on the VRF consumer base contract
    *   @dev require enough link for the transaction
    *   @param keyHash is the public key against which randomness is generated
    *   @param fee is the fee in LINK for the request
    */
    function getRandomValue(bytes32 keyHash, uint256 fee) public onlyOwner {
        require(LINK.balanceOf(address(this)) >= fee, "Error: Not enough LINK");
        randomRequestId = requestRandomness(keyHash, fee);
    }

    /**
    *   @notice function to receive random value from chainlink VRF
    *   @dev internal function since VRFCoordinator calls "rawFulfillRandomness" and that has security built in
    *   @dev still need to make sure we store a value with the right request Id and that we haven't already received a fulfilled order
    *   @dev just stores result which can then be used elsewhere. This avoid reverting functions
    *   @dev emits event showing that it was received
    */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        if (requestId == randomRequestId && !randomReceived) {
            randomResult = randomness;
            randomReceived = true;
        }

        emit randomnessReceived();
    }   

    /**
    *   @notice function to determine a randomTokenId based on VRF
    *   @dev can only be called by owner
    *   @dev requires that the random ID hasn't been chosen yet
    *   @dev uses inclusive modulus calculation to convert uint256 to value between 1 and current number of tokens.
    *   This is then used to get the owner of that random token.
    */
    function calcRandomId() public onlyOwner {
        require(randomReceived, "Error: VRF has not been called yet");
        require(!raffleComplete, "Error: raffle is complete");
        randomTokenId = randomResult.mod(892).add(1);
        raffleComplete = true;
    }

    /**
    *   @dev gets the random token id
    *   @dev onlyOwner. Others must wait until tokenID is revealed. This is so that LIT creators or Transient Labs may not receive the copyright. Don't want to dox people :)
    * 
    */
    function ownerGetRandomId() public view onlyOwner returns(uint256) {
        require(raffleComplete, "Error: raffle not complete");
        return(randomTokenId);
    }

    /**
    *   @dev gets the random token id once the winner is revealed
    * 
    */
    function getRandomId() public view returns(uint256) {
        require(raffleComplete, "Error: raffle not complete");
        require(revealTokenId, "Error: token ID not ready to be revealed to the public");
        return(randomTokenId);
    }

    /**
    *   @dev resets randomness bools and value. This shall only be used if the random chosen id belongs to a LIT creator or Transient Labs.
    *   @dev onlyOwner
    */
    function resetRaffle() public onlyOwner {
        raffleComplete = false;
        randomReceived = false;
    }

    /**
    *   @dev function to get raffle status
    */
    function raffleStatus() public view returns(bool) {
        return(raffleComplete);
    }

    /**
    *   @dev reveal raffle
    *   @dev ownly owner
    */
    function revealRaffle() public onlyOwner {
        revealTokenId = true;
    }

    /**
    *   @dev hide raffle
    *   @dev ownly owner
    */
    function hideRaffle() public onlyOwner {
        revealTokenId = false;
    }

    /**
    *   @dev show status of raffle reveal
    */
    function raffleRevealStatus() public view returns(bool) {
        return(revealTokenId);
    }
}  