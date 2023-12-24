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

/**
 * @title Errors
 * 
 * @notice Library contains all the custom errors used to revert in Genesis contracts
 */
library Errors {
    /**
     * @notice user has already minted
     */
    error AlreadyMinted();

    /**
     * @notice signature is invalid
     */
    error InvalidSignature();

    /**
     * @notice signature is being used too early
     */
    error SignatureValidityStart();

    /**
     * @notice signature isn't valid anymore
     */
    error SignatureValidityEnd();

    /**
     * @notice signature was created for another chain_id
     */
    error WrongChainID();

    /**
     * @notice baseURI was already set once
     */
    error BaseURIAlreadyInitialized();

    /**
     * @notice token does not exist
     */
    error ERC721UriNonExistent();

    /**
     * @notice MintData.mint_amount cannot be 0
     */
    error InvalidMintAmount();

    /**
     * @notice the token maximum supply is reached
     */
    error MaxSupplyReached();

    /**
     * Chainlink VRF request was already called
     */
    error RequestAlreadyInitialized();

    /**
     * GenesisPFP contract does not own any Link tokens
     */
    error EmptyLinkBalance();
}
