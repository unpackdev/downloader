// SPDX-License-Identifier: UNLICENSED
/// @title NftContractMaker
/// @notice Nft Contract Maker
/// @author CyberPnk <cyberpnk@cyberpnk.win>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____ 
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______  
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______   
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____    
//  __________________/\/\/\/\________________________________________________________________________________     
// __________________________________________________________________________________________________________     

pragma solidity ^0.8.13;

import "./NftContract.sol";
import "./Ownable.sol";
import "./FeeWithDiscountsLockable.sol";
import "./DestroyLockable.sol";
// import "./console.sol";

contract NftContractMaker is Ownable, FeeWithDiscountsLockable, DestroyLockable {
    event CreatedNftContract(address indexed creator, string indexed name, string indexed symbol, address nftContract);

    constructor() {
    }

    function createNftContract(string memory name, string memory symbol) external payable {
        NftContract newContract = new NftContract(msg.sender, name, symbol);
        emit CreatedNftContract(msg.sender, name, symbol, address(newContract));
    }

    function withdraw() external {
        payable(feePayee).transfer(address(this).balance);
    }

}
