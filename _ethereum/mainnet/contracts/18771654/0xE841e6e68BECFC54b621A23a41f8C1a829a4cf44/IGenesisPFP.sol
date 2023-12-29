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

import "./IGenesisBase.sol";
import "./MintData.sol";

/**
 * @title IGenesisPFP
 *
 * @notice Interface for the GenesisPFP contract, implementing minting and signature verification
 */
interface IGenesisPFP {
    /**
     * @notice allows a user to mint a token with a valid signature
     * @dev signarture must be signed by the contract owner
     * @param request MintData object describing the mint request
     * @param signature EIP712-typed signature
     */
    function mintWithSignature(MintData calldata request, bytes memory signature) external;
}
