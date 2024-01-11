// SPDX-License-Identifier: UNLICENSED
/// @title CollectionPfpBgManager
/// @notice Collection Pfp Bg Manager
/// @author CyberPnk <cyberpnk@pfpbg.cyberpnk.win>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____ 
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______  
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______   
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____    
//  __________________/\/\/\/\________________________________________________________________________________     
// __________________________________________________________________________________________________________     

pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./CollectionPfpBg.sol";
// import "./console.sol";

contract CollectionPfpBgManager is Ownable {
    address public stringUtilsContract;
    address public pfpBgContract;
    
    mapping (address => address) public pfpToCollectionPfpBg;

    event CreateCollectionPfpBg(address indexed pfpContract, address indexed pfpAdapterContract);

    constructor(address _stringUtilsContract, address _pfpBgContract) {
        stringUtilsContract = _stringUtilsContract;
        pfpBgContract = _pfpBgContract;
    }

    function createCollectionPfpBgContract(address pfpContract, address pfpAdapterContract) external onlyOwner {
        CollectionPfpBg newContract = new CollectionPfpBg(stringUtilsContract, pfpBgContract, pfpAdapterContract);
        pfpToCollectionPfpBg[pfpContract] = address(newContract);
        emit CreateCollectionPfpBg(pfpContract, address(newContract));
    }

    function removeCollectionPfpBgContract(address pfpContract) external onlyOwner {
        pfpToCollectionPfpBg[pfpContract] = address(0);
        emit CreateCollectionPfpBg(pfpContract, address(0));
    }
}
