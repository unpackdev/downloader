// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @creator: Pak
/// @author: manifold.xyz

/////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                 //
//                                                                                                 //
//      .g8"""bgd `7MM"""Mq.  `7MM"""YMM        db   MMP""MM""YMM `7MMF' .g8""8q. `7MN.   `7MF'    //
//    .dP'     `M   MM   `MM.   MM    `7       ;MM:  P'   MM   `7   MM .dP'    `YM. MMN.    M      //
//    dM'       `   MM   ,M9    MM   d        ,V^MM.      MM        MM dM'      `MM M YMb   M      //
//    MM            MMmmdM9     MMmmMM       ,M  `MM      MM        MM MM        MM M  `MN. M      //
//    MM.           MM  YM.     MM   Y  ,    AbmmmqMA     MM        MM MM.      ,MP M   `MM.M      //
//    `Mb.     ,'   MM   `Mb.   MM     ,M   A'     VML    MM        MM `Mb.    ,dP' M     YMM      //
//      `"bmmmd'  .JMML. .JMM..JMMmmmmMMM .AMA.   .AMMA..JMML.    .JMML. `"bmmd"' .JML.    YM      //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//      .g8""8q. `7MM"""Yp, `7MM"""YMM `YMM'   `MM'.M"""bgd                                        //
//    .dP'    `YM. MM    Yb   MM    `7   VMA   ,V ,MI    "Y                                        //
//    dM'      `MM MM    dP   MM   d      VMA ,V  `MMb.                                            //
//    MM        MM MM"""bg.   MMmmMM       VMMP     `YMMNq.                                        //
//    MM.      ,MP MM    `Y   MM   Y  ,     MM    .     `MM                                        //
//    `Mb.    ,dP' MM    ,9   MM     ,M     MM    Mb     dM                                        //
//      `"bmmd"' .JMMmmmd9  .JMMmmmmMMM   .JMML.  P"Ybmmd"                                         //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//    `7MMF'MMP""MM""YMM  .M"""bgd                                                                 //
//      MM  P'   MM   `7 ,MI    "Y                                                                 //
//      MM       MM      `MMb.                                                                     //
//      MM       MM        `YMMNq.                                                                 //
//      MM       MM      .     `MM                                                                 //
//      MM       MM      Mb     dM                                                                 //
//    .JMML.   .JMML.    P"Ybmmd"                                                                  //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//      .g8"""bgd `7MM"""Mq.  `7MM"""YMM        db   MMP""MM""YMM   .g8""8q. `7MM"""Mq.            //
//    .dP'     `M   MM   `MM.   MM    `7       ;MM:  P'   MM   `7 .dP'    `YM. MM   `MM.           //
//    dM'       `   MM   ,M9    MM   d        ,V^MM.      MM      dM'      `MM MM   ,M9            //
//    MM            MMmmdM9     MMmmMM       ,M  `MM      MM      MM        MM MMmmdM9             //
//    MM.           MM  YM.     MM   Y  ,    AbmmmqMA     MM      MM.      ,MP MM  YM.             //
//    `Mb.     ,'   MM   `Mb.   MM     ,M   A'     VML    MM      `Mb.    ,dP' MM   `Mb.           //
//      `"bmmmd'  .JMML. .JMM..JMMmmmmMMM .AMA.   .AMMA..JMML.      `"bmmd"' .JMML. .JMM.          //
//                                                                                                 //
//                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * coic Interface
 */
interface icoic {

    /**
     * @dev Mint tokens
     */
    function mint(address[] calldata receivers, string[] calldata uris) external;

    /**
     * @dev Lock transfers for specified tokens
     */
    function setTransferLock(uint256[] calldata tokenIds, bool lock) external;

    /**
     * @dev Burn all tokens
     */
    function burn() external;

    /**
     * @dev Move tokens
     */
    function move(uint256[] calldata tokenIds, address[] calldata recipients) external;

    /**
     * @dev Set the contract information
     */
    function setInfo(string calldata name_, string calldata symbol_) external;

    /**
     * @dev Set the image base uri (prefix)
     */
    function setPrefixURI(string calldata uri) external;

    /**
     * @dev Set the image base uri (common for all tokens)
     */
    function setCommonURI(string calldata uri) external;

    /**
     * @dev Set token uri
     */
    function setTokenURIs(uint256[] calldata tokenIds, string[] calldata uris) external;

    /**
     * @dev Update royalties
     */
    function updateRoyalties(address payable recipient, uint256 bps) external;

    /**
     * ROYALTY FUNCTIONS
     */
    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps);
    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients);
    function getFeeBps(uint256) external view returns (uint[] memory bps);
    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256);
}
