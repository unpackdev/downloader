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

import "./MintData.sol";

/**
 * @title IGenesisBase
 *
 * @notice Interface for the GenesisBase contract used for minting and
 * setting a metadata CID on top of ERC721Psi, EIP712, Ownable, AccessControl
 */
interface IGenesisBase {
    /**
     * @notice can only be called once if baseURI isn't set
     * @notice can only be called by the contract owner
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     * @param _uri Content Identifier of the IPFS folder containing metadata files
     */
    function setBaseURI(string calldata _uri) external;

    /**
     * @notice update the default royalty informations as per ERC2981
     * @notice can only be called by the contract owner
     * @param receiver address of the new vault receiving royalty fees
     * @param feeNumerator percentage of royalties to apply
     */
    function updateDefaultRoyalty(address receiver, uint96 feeNumerator) external;
}
