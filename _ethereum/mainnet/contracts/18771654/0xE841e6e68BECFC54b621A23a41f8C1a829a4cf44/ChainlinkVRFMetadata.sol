// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

//  **     **  **       **                    ****   **
// /**    /** /**      //                    /**/   /**
// /**    /** /**       **  ******  ******  ****** ******
// /**    /** /******  /** **////  **////**///**/ ///**/
// /**    /** /**///** /**//***** /**   /**  /**    /**
// /**    /** /**  /** /** /////**/**   /**  /**    /**
// //*******  /******  /** ****** //******   /**    //**
// ///////    /////    // //////   //////    //      //

import "./Errors.sol";
import "./Ownable.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFV2WrapperConsumerBase.sol";

/**
 * @title ChainlinkVRFMetadata
 *
 * @dev Implementation of Chainlink VRFV2WrapperConsumerBase to request random numbers
 */
abstract contract ChainlinkVRFMetadata is VRFV2WrapperConsumerBase, Ownable {
    // =============================================================
    //                   VARIABLES
    // =============================================================

    // RequestID from the chainlink VRF V2 randomness request
    uint256 public chainlinkRequestID;

    // RandomWorlds fetched from the chainlink VRF V2 randomness request
    uint256 public chainlinkSeed;

    // =============================================================
    //                   EXTERNAL
    // =============================================================

    /**
     * @notice must called by the contract owner, contract must be funded with LINK tokens
     * @notice can only be called once if `chainlinkRequestID` isn't set
     * @dev reveal will call `requestRandomness` from VRFV2WrapperConsumerBase with
     * @dev the following parameters:
     * @dev _callbackGasLimit is the gas limit that should be used when calling the consumer's
     *        fulfillRandomWords function.
     * @dev _requestConfirmations is the number of confirmations to wait before fulfilling the
     *        request. A higher number of confirmations increases security by reducing the likelihood
     *        that a chain re-org changes a published randomness outcome.
     * @dev _numWords is the number of random words to request.
     */
    function requestChainlinkVRF(uint32 _callbackGasLimit, uint16 _requestConfirmations) external onlyOwner {
        if (chainlinkRequestID != 0) {
            revert Errors.RequestAlreadyInitialized();
        }
        // 150_000 gas should be more than enough for the callback
        // 6 block confirmations or more
        // 1 random number used a a seed for the tokenIDs
        chainlinkRequestID = requestRandomness(_callbackGasLimit, _requestConfirmations, 1);
    }

    /**
     * @notice withdraw all excess of Link tokens from the contract balance to the specified recipient
     * @param dest recipient of the Link transfer
     */
    function withdrawRemainingLink(address dest) external onlyOwner {
        uint256 balance = LINK.balanceOf(address(this));
        if (balance == 0) revert Errors.EmptyLinkBalance();
        require(LINK.transfer(dest, balance));
    }

    // =============================================================
    //                   INTERNAL
    // =============================================================

    /**
     * @notice fulfillRandomWords handles the VRF V2 wrapper response.
     * @notice Consuming contract must implement it.
     * @dev Instead of reverting, reset chainlinkRequestID if there is an error
     * @dev caused by Chainlink's oracle so we can trigger a new VRF request
     * @param _requestId is the VRF V2 request ID.
     * @param _randomWords is the randomness result.
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        if (_requestId != chainlinkRequestID || _randomWords.length != 1) {
            chainlinkRequestID = 0;
            return;
        }
        // Assign the retrieved random word from Chainlink VRF V2
        // Anyone can re-generate the tokenIds from the seed deterministically
        chainlinkSeed = _randomWords[0];
    }
}
